'use strict';
const OcrStudio = (() => {
  const state = {worker:null, cancelled:false, active:false, session:null};
  const yieldFrame = () => new Promise(resolve => setTimeout(resolve, 0));
  function check() { if (state.cancelled) throw Error('OCR_CANCELLED'); }
  function canvas(width, height) {
    const element = document.createElement('canvas');
    element.width = width; element.height = height;
    return element;
  }
  function threshold(histogram, count) {
    let total = 0;
    for (let n=0;n<256;n++) total += n*histogram[n];
    let weight = 0, sum = 0, best = -1, cut = 128;
    for (let n=0;n<255;n++) {
      weight += histogram[n]; sum += n*histogram[n];
      if (!weight || weight === count) continue;
      const difference = sum/weight-(total-sum)/(count-weight);
      const variance = weight*(count-weight)*difference*difference;
      if (variance > best) { best=variance; cut=n; }
    }
    return Math.max(30, Math.min(225, cut));
  }
  function enhance(source, mode) {
    const result = canvas(source.width, source.height);
    const context = result.getContext('2d', {willReadFrequently:true});
    context.fillStyle = '#fff'; context.fillRect(0,0,result.width,result.height);
    context.drawImage(source,0,0);
    if (mode === 'none') return result;
    const pixels = context.getImageData(0,0,result.width,result.height), values = pixels.data;
    const histogram = new Uint32Array(256), count = values.length/4;
    for (let p=0;p<values.length;p+=4) {
      const gray = (77*values[p]+150*values[p+1]+29*values[p+2]) >> 8;
      values[p]=values[p+1]=values[p+2]=gray; histogram[gray]++;
    }
    let low=0, high=255, sum=0;
    for (let n=0;n<256;n++) { sum+=histogram[n]; if(sum>=count*.005){low=n;break;} }
    sum=0;
    for (let n=255;n>=0;n--) { sum+=histogram[n]; if(sum>=count*.005){high=n;break;} }
    const cutoff = threshold(histogram,count);
    for (let p=0;p<values.length;p+=4) {
      const value = mode === 'binary' ? (values[p] <= cutoff ? 0 : 255) : high-low>16 ? Math.max(0,Math.min(255,Math.round((values[p]-low)*255/(high-low)))) : values[p];
      values[p]=values[p+1]=values[p+2]=value; values[p+3]=255;
    }
    context.putImageData(pixels,0,0);
    return result;
  }
  function estimateSkew(source) {
    const scale=Math.min(1,800/source.width,1000/source.height);
    const sample=canvas(Math.max(1,Math.round(source.width*scale)),Math.max(1,Math.round(source.height*scale)));
    try {
      const context=sample.getContext('2d',{willReadFrequently:true});
      context.drawImage(source,0,0,sample.width,sample.height);
      const pixels=context.getImageData(0,0,sample.width,sample.height).data;
      const points=[];
      // Ignore scanner borders and sample every other pixel to bound CPU use.
      for(let y=12;y<sample.height-12;y++) for(let x=12;x<sample.width-12;x+=2) {
        const p=(y*sample.width+x)*4;
        if ((pixels[p]+pixels[p+1]+pixels[p+2])/3 < 125) points.push(x-sample.width/2,y-sample.height/2);
      }
      if(points.length<200) return 0;
      function score(degrees) {
        const angle=degrees*Math.PI/180, s=Math.sin(angle), c=Math.cos(angle);
        const bins=new Uint32Array(sample.height+sample.width+8), center=bins.length/2;
        for(let n=0;n<points.length;n+=2) {
          const row=Math.round(points[n]*s+points[n+1]*c+center);
          if(row>=0 && row<bins.length) bins[row]++;
        }
        let value=0;
        for(let n=0;n<bins.length;n++) value+=bins[n]*bins[n];
        return value;
      }
      const baseline=score(0); let best=baseline, angle=0;
      for(let a=-5;a<=5;a+=.5) {const value=score(a);if(value>best){best=value;angle=a;}}
      return best>baseline*1.09 ? angle : 0;
    } finally {sample.width=sample.height=0;}
  }
  function rotate(source, degrees) {
    if(!degrees) return {image:source,angle:0};
    const a=degrees*Math.PI/180,c=Math.cos(a),s=Math.sin(a);
    const result=canvas(Math.ceil(Math.abs(c)*source.width+Math.abs(s)*source.height),Math.ceil(Math.abs(s)*source.width+Math.abs(c)*source.height));
    const ctx=result.getContext('2d');
    ctx.fillStyle='#fff';ctx.fillRect(0,0,result.width,result.height);
    ctx.translate(result.width/2,result.height/2);ctx.rotate(a);ctx.drawImage(source,-source.width/2,-source.height/2);
    return {image:result,angle:degrees};
  }
  function inversePoint(x,y,originalWidth,originalHeight,rotatedWidth,rotatedHeight,angle) {
    const a=angle*Math.PI/180,c=Math.cos(a),s=Math.sin(a);
    const dx=x-rotatedWidth/2,dy=y-rotatedHeight/2;
    return {x:c*dx+s*dy+originalWidth/2,y:-s*dx+c*dy+originalHeight/2};
  }
  function wordsFrom(data) {
    if(data.words && data.words.length) return data.words;
    const result=[];
    for(const block of data.blocks||[]) for(const paragraph of block.paragraphs||[]) for(const line of paragraph.lines||[]) result.push(...line.words||[]);
    return result;
  }
  function report(rows) {
    const element=$('#ocrReport'); element.replaceChildren(); element.hidden=false;
    const title=document.createElement('h3');title.textContent='Reconhecimento concluído';element.append(title);
    const processed=rows.filter(row=>!row.kept), words=processed.reduce((sum,row)=>sum+row.words,0);
    const low=processed.reduce((sum,row)=>sum+row.low,0);
    const stats=document.createElement('div');stats.className='report-stats';
    for(const [value,label] of [[rows.length,'páginas'],[words,'palavras reconhecidas'],[low,'palavras para revisar']]) {
      const cell=document.createElement('div'),strong=document.createElement('strong'),small=document.createElement('small');
      strong.textContent=value;small.textContent=label;cell.append(strong,small);stats.append(cell);
    }
    element.append(stats);
    const details=document.createElement('details'),summary=document.createElement('summary');summary.textContent='Ver resultado por página';details.append(summary);
    const table=document.createElement('table'),head=document.createElement('tr');
    for(const value of ['Página','Resultado','Confiança']){const th=document.createElement('th');th.textContent=value;head.append(th);}table.append(head);
    rows.forEach(row=>{
      const tr=document.createElement('tr');
      const label=row.kept?'Preservada':row.words?row.words+' palavras':'Sem texto reconhecido';
      for(const value of [String(row.number),label,row.kept?'—':row.confidence===null?'—':Math.round(row.confidence)+'%']) {
        const td=document.createElement('td');td.textContent=value;if(!row.kept&&(row.confidence===null||row.confidence<65))td.className='low';tr.append(td);
      }
      table.append(tr);
    });
    details.append(table);element.append(details);
    const note=document.createElement('p');note.className='hint';
    note.textContent='Confiança é uma estimativa do mecanismo, não garantia de exatidão. Revise nomes, datas e números. Páginas sem texto reconhecido continuam como imagem.';
    if(rows.some(row=>row.omitted))note.textContent+=' Alguns símbolos não puderam ser inseridos na camada de pesquisa; consulte também o TXT.';
    element.append(note);
  }

  const priorRun=$('#run').onclick;
  $('#cancelOcr').onclick=async()=>{
    if(!state.active||state.cancelled)return;
    state.cancelled=true;$('#cancelOcr').disabled=true;
    if(state.session){state.session.cancelled=true;state.session.abort();}
    status('Cancelando OCR…');
    if(state.worker){const worker=state.worker;state.worker=null;try{await worker.terminate();}catch(_){}}
  };
  $('#run').onclick=async()=>{
    if(tool!=='ocr') {
      $('#processTitle').textContent='Processando documento';$('#processSpinner').hidden=false;$('#taskProgress').removeAttribute('value');
      try{return await priorRun();}finally{$('#processPanel').hidden=true;}
    }
    if(busy||!files.length)return;
    const options={language:$('#language').value,quality:$('#ocrQuality').value,layout:$('#ocrLayout').value,
      enhancement:$('#ocrEnhance').value,deskew:$('#ocrDeskew').checked,force:$('#ocrForce').checked,
      exportText:$('#ocrExportText').checked,pages:$('#pages').value};
    const inputs=files.slice(),rows=[],texts=[];
    let rejectAbort;
    const abortPromise=new Promise((_,reject)=>{rejectAbort=reject;});
    abortPromise.catch(()=>{});
    const session={cancelled:false,abort:()=>rejectAbort(Error('OCR_CANCELLED'))};
    state.session=session;
    const wait=promise=>Promise.race([promise,abortPromise]);
    state.active=true;state.cancelled=false;busy=true;render();resetResults();
    $('#ocrReport').hidden=true;$('#processPanel').hidden=false;$('#processSpinner').hidden=false;$('#cancelOcr').hidden=false;$('#cancelOcr').disabled=false;
    $('#processTitle').textContent='Reconhecendo seus documentos';$('#taskProgress').value=0;
    let currentPage=0,currentFraction=0,wakeLock=null,finished=false;
    const start=Date.now();
    const progress=fraction=>{$('#taskProgress').value=Math.max(0,Math.min(100,fraction*100));};
    let pageProgress=()=>{};
    async function getWorker() {
      check();
      if(!state.worker) {
        status('Preparando o reconhecimento offline…');
        const loading=Tesseract.createWorker(options.language,1,{
          workerPath:'https://appassets.androidplatform.net/vendor/worker.min.js',
          corePath:'https://appassets.androidplatform.net/vendor',
          langPath:'https://appassets.androidplatform.net/vendor/lang',
          logger:message=>{
            if(session.cancelled)return;
            if(message.status==='recognizing text'){
              const fraction=Number(message.progress)||0;
              status('Página '+currentPage+' · reconhecendo texto '+Math.round(fraction*100)+'%');pageProgress(fraction);
            }
          }
        }).then(async worker=>{
          if(session.cancelled){await worker.terminate();throw Error('OCR_CANCELLED');}
          state.worker=worker;
          return worker;
        });
        await wait(loading);
        check();
      }
      return state.worker;
    }
    try {
      if(!window.Tesseract||!window.PDFLib||!window.pdfjsLib)throw Error('Não foi possível carregar o OCR. Feche e abra o aplicativo.');
      if(navigator.wakeLock)try{wakeLock=await navigator.wakeLock.request('screen');}catch(_){}
      pdfjsLib.GlobalWorkerOptions.workerSrc='https://appassets.androidplatform.net/vendor/pdf.worker.js';
      const output=await PDFLib.PDFDocument.create(),font=await output.embedFont(PDFLib.StandardFonts.Helvetica);
      const dpi=options.quality==='precise'?300:200,maxSide=options.quality==='precise'?3600:2600;
      async function recognize(original,width,height,actualDpi) {
        check();status('Página '+currentPage+' · preparando imagem…');await yieldFrame();
        let enhanced=null,rotated=null;
        try {
          enhanced=enhance(original,options.enhancement);
          const angle=options.deskew?estimateSkew(enhanced):0;
          rotated=rotate(enhanced,angle);check();await yieldFrame();
          const worker=await getWorker();
          await wait(worker.setParameters({tessedit_pageseg_mode:options.layout,user_defined_dpi:String(Math.max(70,Math.round(actualDpi))),preserve_interword_spaces:'1'}));
          check();
          const {data}=await wait(worker.recognize(rotated.image,{}, {text:true,blocks:true,hocr:false,tsv:false}));
          check();
          const image=await output.embedJpg(original.toDataURL('image/jpeg',options.quality==='precise'?.96:.92));
          const page=output.addPage([width,height]);page.drawImage(image,{x:0,y:0,width,height});
          const words=wordsFrom(data);let omitted=0,accepted=0,low=0,confidenceSum=0,confidenceCount=0;
          for(const word of words) {
            const box=word.bbox;
            if(!box||![box.x0,box.y0,box.x1,box.y1].every(Number.isFinite)||box.x1<=box.x0||box.y1<=box.y0)continue;
            const label=Array.from(word.text||'').filter(character=>{try{font.encodeText(character);return true;}catch(_){omitted++;return false;}}).join('');
            if(!label.trim())continue;
            const point=inversePoint(box.x0,box.y1,original.width,original.height,rotated.image.width,rotated.image.height,angle);
            const natural=font.widthOfTextAtSize(label,1);
            const size=Math.max(.5,Math.min((box.y1-box.y0)*height/original.height*.94,(box.x1-box.x0)*width/original.width/Math.max(.01,natural)));
            page.drawText(label,{x:point.x*width/original.width,y:height-point.y*height/original.height,
              size,font,opacity:0,rotate:PDFLib.degrees(angle)});
            accepted++;
            if(Number.isFinite(word.confidence)){confidenceSum+=word.confidence;confidenceCount++;if(word.confidence<60)low++;}
          }
          const confidence=confidenceCount?confidenceSum/confidenceCount:Number.isFinite(data.confidence)?data.confidence:null;
          rows.push({number:currentPage,words:accepted,low,confidence,angle,omitted,kept:false});
          texts.push('--- Página '+currentPage+' ---\n'+(data.text||words.map(w=>w.text||'').join(' ')));
        } finally {
          if(rotated&&rotated.image!==enhanced)rotated.image.width=rotated.image.height=0;
          if(enhanced)enhanced.width=enhanced.height=0;
        }
      }
      for(let index=0;index<inputs.length;index++) {
        check();const file=inputs[index];
        if(/\.pdf$/i.test(file.name)) {
          const raw=await file.arrayBuffer(),source=await PDFLib.PDFDocument.load(raw);
          const pdf=await pdfjsLib.getDocument({data:new Uint8Array(raw.slice(0)),isEvalSupported:false}).promise;
          try {
            const selected=new Set(options.pages.trim()?pageNumbers(options.pages,pdf.numPages):source.getPageIndices());
            for(let n=1;n<=pdf.numPages;n++) {
              check();currentPage++;
              const page=await pdf.getPage(n),content=await page.getTextContent();
              const existing=content.items.map(item=>(item.str||'')+(item.hasEOL?'\n':' ')).join('');
              currentFraction=(index+(n-1)/pdf.numPages)/inputs.length;
              pageProgress=fraction=>progress(currentFraction+(fraction*.85+.1)/pdf.numPages/inputs.length);
              if(!selected.has(n-1)||(!options.force&&existing.trim())) {
                for(const preserved of await output.copyPages(source,[n-1]))output.addPage(preserved);
                rows.push({number:currentPage,kept:true,words:0,low:0,confidence:null});
                texts.push('--- Página '+currentPage+' ---\n'+existing);
                status('Página '+currentPage+' · preservada sem reconstrução');
              } else {
                const base=page.getViewport({scale:1});
                const scale=Math.min(dpi/72,maxSide/Math.max(base.width,base.height),Math.sqrt(10000000/(base.width*base.height)));
                const viewport=page.getViewport({scale}),image=canvas(Math.ceil(viewport.width),Math.ceil(viewport.height));
                try {
                  status('Página '+currentPage+' · renderizando a '+Math.round(scale*72)+' DPI');
                  await page.render({canvasContext:image.getContext('2d'),viewport,background:'rgb(255,255,255)'}).promise;
                  await recognize(image,base.width,base.height,scale*72);
                } finally {image.width=image.height=0;}
              }
              page.cleanup();progress((index+n/pdf.numPages)/inputs.length);await yieldFrame();
            }
          } finally {await pdf.destroy();}
        } else {
          if(options.pages.trim())throw Error('A seleção de páginas vale apenas para PDFs. Apague o campo para reconhecer imagens.');
          currentPage++;pageProgress=fraction=>progress((index+fraction*.9)/inputs.length);
          const bitmap=await createImageBitmap(file),scale=Math.min(1,maxSide/Math.max(bitmap.width,bitmap.height));
          const image=canvas(Math.max(1,Math.round(bitmap.width*scale)),Math.max(1,Math.round(bitmap.height*scale)));
          try {
            const context=image.getContext('2d');context.fillStyle='#fff';context.fillRect(0,0,image.width,image.height);context.drawImage(bitmap,0,0,image.width,image.height);
            await recognize(image,595,595*image.height/image.width,dpi);
          } finally {bitmap.close();image.width=image.height=0;}
          progress((index+1)/inputs.length);
        }
      }
      check();status('Preparando os arquivos de saída…');await yieldFrame();
      const bytes=await output.save();check();
      download(bytes,'documento-pesquisavel.pdf');
      if(options.exportText)download(texts.join('\n\n'),'texto-reconhecido.txt','text/plain;charset=utf-8');
      report(rows);progress(1);finished=true;
      const empty=rows.filter(row=>!row.kept&&!row.words).length;
      status('Concluído em '+Math.max(1,Math.round((Date.now()-start)/1000))+' s. '+(empty?empty+' página(s) sem texto reconhecido; confira o relatório.':'Salve o PDF pesquisável e confira o relatório.'));
    } catch(error) {
      if(state.cancelled||error.message==='OCR_CANCELLED')status('OCR cancelado. Nenhum original foi alterado.');
      else status(/encrypt|password/i.test(error.message)?'Este PDF está protegido por senha. Remova a proteção antes do OCR.':'Não foi possível concluir o OCR: '+error.message,true);
    } finally {
      const worker=state.worker;state.worker=null;
      if(worker)try{await worker.terminate();}catch(_){}
      if(wakeLock)try{await wakeLock.release();}catch(_){}
      state.active=false;busy=false;render();$('#cancelOcr').hidden=true;
      $('#processPanel').hidden=!finished;
      $('#processSpinner').hidden=finished;
      $('#processTitle').textContent=finished?'Arquivos prontos para salvar':'Processando documento';
    }
  };
  return {threshold,enhance,estimateSkew,rotate,inversePoint,wordsFrom};
})();
