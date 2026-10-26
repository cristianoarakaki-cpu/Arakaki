'use strict';
const FolhaWorkspace=(()=>{
  cfg.boleto=['Ler boleto','Seu boleto, <i>pronto para copiar.</i>',
    'Reconheça a linha digitável de um boleto em PDF ou imagem.<br>Confira os números antes de pagar.',
    'Reconhecer boleto','Código para copiar','Copie os números reconhecidos.'];
  cfg.redact=['Ocultar dados pessoais','Proteja informações <i>pessoais.</i>',
    'Encontre CPFs, documentos, registros e possíveis nomes.<br>Revise cada sugestão antes de ocultar.',
    'Analisar dados pessoais','PDF com tarjas','Nova cópia rasterizada, sem camada de texto original.'];
  const additions={
    compare:['Comparar PDFs','O que mudou <i>entre as versões?</i>','Compare duas versões pela aparência das páginas.<br>Uma análise visual, sem interpretar o significado do texto.','Comparar versões','Relatório visual em PDF','Páginas das duas versões e diferenças destacadas. Até 30 pares.'],
    audit:['Revisar digitalização','Encontre páginas <i>que merecem revisão.</i>','Identifique páginas possivelmente em branco ou visualmente repetidas.<br>Confira as prévias antes de remover qualquer página.','Analisar documento','Revisão assistida','Nenhuma página é removida sem sua seleção. Até 80 páginas analisadas.'],
    nup:['Várias páginas por folha','Mais conteúdo. <i>Menos folhas.</i>','Monte 2, 4 ou 9 páginas em cada folha A4.<br>O conteúdo vetorial e o texto são incorporados ao novo PDF.','Montar folhas','PDF para impressão','Links, anotações e campos interativos não são copiados.']
  };
  Object.assign(cfg,additions);
  const descriptions={
    redact:['Ocultar dados pessoais','Detecte identificadores e aplique tarjas permanentes após conferir as páginas.','smart','▩'],
    boleto:['Ler código de boleto','Localize a linha digitável e copie os números para pagamento.','smart','▥'],
    ocr:['Texto pesquisável','Reconheça digitalizações, copie texto e confira a confiança do OCR.','smart','⌕'],
    compare:['Compare versões','Veja diferenças visuais entre dois PDFs, página por página.','smart','⇄'],
    audit:['Revise digitalizações','Encontre possíveis páginas em branco e repetições antes de limpar.','smart','◎'],
    images:['Imagens para PDF','Escolha papel, margens e encaixe. Uma imagem em cada página.','convert','▧'],
    docx:['PDF para Word','Exporte o texto para DOCX editável, sem conservar o layout.','convert','W'],
    text:['PDF para texto','Extraia o texto selecionável em TXT, sem diagramação.','convert','≡'],
    jpg:['PDF para JPG','Uma imagem JPEG por página, pronta para salvar.','convert','▧'],
    png:['PDF para PNG','Exporte páginas em imagens PNG, reunidas em ZIP.','convert','▧'],
    merge:['Junte documentos','Combine PDFs na ordem que você escolher.','organize','⊞'],
    extract:['Extraia e reordene','Selecione páginas, repita ou altere sua sequência.','organize','▤'],
    split:['Separe em arquivos','Um PDF por página, reunidos em um ZIP.','organize','⑂'],
    remove:['Remova páginas','Escolha o que excluir e salve uma nova cópia.','organize','−'],
    rotate:['Acerte a orientação','Gire as páginas sem reconstruir o conteúdo.','organize','↻'],
    stamp:['Numere e identifique','Insira paginação ou um rodapé personalizado.','organize','#'],
    optimize:['Otimize a estrutura','Regrave a estrutura interna; a redução de tamanho varia.','organize','↙'],
    nup:['Várias por folha','Monte 2, 4 ou 9 páginas por folha A4 para imprimir.','organize','⊟']
  };
  for(const key of Object.keys(additions)){
    const button=document.createElement('button');button.dataset.tool=key;
    button.innerHTML='<span class="nav-icon">'+descriptions[key][3]+'</span><span>'+cfg[key][0]+'</span><em>NOVO</em>';
    button.onclick=()=>selectTool(key);$('nav').append(button);
  }
  const panel=document.createElement('div');panel.id='workspaceSettings';panel.hidden=true;
  panel.innerHTML='<div id="compareControls" hidden><div class="feature-info">O primeiro PDF da lista é a versão A. O segundo é a versão B.</div><label for="compareTolerance">Sensibilidade visual</label><select id="compareTolerance"><option value="24">Equilibrada</option><option value="12">Mais sensível</option><option value="45">Ignorar pequenas variações</option></select><p class="hint">Compara páginas pela mesma posição. Não alinha páginas movidas. Fontes e digitalizações podem criar diferenças sem mudança no texto.</p></div><div id="auditControls" hidden><p class="feature-info">A análise é uma sugestão. Texto claro, assinaturas e marcas pequenas podem parecer uma página vazia: revise a prévia.</p></div><div id="nupControls" hidden><label for="nupCount">Páginas por folha</label><select id="nupCount"><option value="2">2 páginas · A4 paisagem</option><option value="4">4 páginas · A4 retrato</option><option value="9">9 páginas · A4 retrato</option></select></div><div id="imageControls" hidden><label for="imagePaper">Formato do papel</label><select id="imagePaper"><option value="a4">A4 retrato</option><option value="a4land">A4 paisagem</option><option value="letter">Carta</option><option value="original">Proporção da imagem</option></select><label for="imageMargin">Margens</label><select id="imageMargin"><option value="18">6 mm</option><option value="36">13 mm</option><option value="0">Sem margens</option></select><p class="hint">A imagem inteira é encaixada, sem corte, sobre fundo branco.</p></div>';
  document.querySelector('label[for="outputName"]').before(panel);
  const result=document.createElement('section');result.id='workspaceResults';result.className='report';result.hidden=true;$('#results').after(result);
  let category='all',candidates=[],auditBytes=null,auditPages=0,cancelled=false;
  function checkCancelled(){if(cancelled)throw Error('Operação cancelada. Seus arquivos originais foram preservados.');}
  const cancelButton=document.createElement('button');cancelButton.id='cancelWorkspace';cancelButton.className='text-button';cancelButton.textContent='Cancelar';cancelButton.hidden=true;
  cancelButton.onclick=()=>{cancelled=true;cancelButton.disabled=true;status('Cancelando após a página atual…');};$('.process-heading').append(cancelButton);
  const normalize=text=>text.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase();
  function cards(){
    const term=normalize($('#hubSearch').value.trim()),grid=$('#toolCards');grid.replaceChildren();let count=0;
    for(const [key,[title,description,group,icon]]of Object.entries(descriptions)){
      if(category!=='all'&&category!==group)continue;
      if(term&&!normalize(title+' '+description+' '+cfg[key][0]).includes(term))continue;
      const button=document.createElement('button');button.className='tool-card category-'+group;
      button.innerHTML='<div class="tool-card-top"><span class="tool-card-icon">'+icon+'</span>'+(key in additions?'<em>NOVO</em>':'')+'</div><h2></h2><p></p><span class="tool-card-arrow">↗</span>';
      button.querySelector('h2').textContent=title;button.querySelector('p').textContent=description;button.onclick=()=>selectTool(key);grid.append(button);count++;
    }
    if(!count){const empty=document.createElement('p');empty.className='hint';empty.textContent='Nenhuma ferramenta encontrada. Tente “texto”, “imagens” ou “páginas”.';grid.append(empty);}
  }
  function hub(){if(PdfLibrary.switchView('hub'))cards();}
  $('#tabTools').onclick=$('#libraryWorkspace').onclick=hub;
  $('#hubSearch').oninput=cards;
  document.querySelectorAll('#hubFilters button').forEach(button=>button.onclick=()=>{
    category=button.dataset.category;document.querySelectorAll('#hubFilters button').forEach(b=>b.classList.toggle('active',b===button));cards();
  });
  async function overview(){try{const records=await PdfLibrary.list();$('#overviewCount').textContent=records.length;$('#overviewSize').textContent=(records.reduce((n,r)=>n+r.size,0)/1048576).toFixed(1)+' MB';}catch(_){}}
  const priorShow=PdfLibrary.show;PdfLibrary.show=async()=>{await priorShow();await overview();};
  $('#tabLibrary').onclick=$('#sidebarLibrary').onclick=$('#viewerBack').onclick=PdfLibrary.show;
  const priorPut=PdfLibrary.put;PdfLibrary.put=async(...args)=>{const id=await priorPut(...args);overview();return id;};
  // Internal library imports call their original closure; refresh the overview
  // after the importer finishes rather than relying only on the public method.
  const priorImport=$('#libraryFiles').onchange;$('#libraryFiles').onchange=async event=>{await priorImport(event);await overview();};
  const oldSelect=selectTool;selectTool=function(key){
    if(busy)return oldSelect(key);oldSelect(key);result.hidden=true;candidates=[];auditBytes=null;
    panel.hidden=!(key in additions||key==='images');
    for(const [id,active]of [['compareControls','compare'],['auditControls','audit'],['nupControls','nup'],['imageControls','images']])$('#'+id).hidden=key!==active;
    if(key in additions){$('#pageSettings').hidden=false;document.querySelector('label[for="pages"]').textContent='Páginas (vazio = todas)';$('#pageSettings .hint').textContent=key==='compare'?'A seleção vale para as duas versões. Para documentos de tamanhos diferentes, deixe vazio.':'Ex.: 1-3, 5, 8. A análise usa páginas únicas.';}
  };
  async function renderPage(doc,index,maxSide=700){
    const page=await doc.getPage(index+1),base=page.getViewport({scale:1});
    const viewport=page.getViewport({scale:Math.min(1.5,maxSide/Math.max(base.width,base.height))});
    const image=document.createElement('canvas');image.width=Math.max(1,Math.round(viewport.width));image.height=Math.max(1,Math.round(viewport.height));
    await page.render({canvasContext:image.getContext('2d'),viewport,background:'rgb(255,255,255)'}).promise;image.pdfWidth=base.width;image.pdfHeight=base.height;page.cleanup();return image;
  }
  function statistics(pixels){
    let dark=0;const count=pixels.length/4;
    for(let n=0;n<pixels.length;n+=4)if((pixels[n]*.299+pixels[n+1]*.587+pixels[n+2]*.114)<225)dark++;
    return {darkFraction:count?dark/count:0};
  }
  function diffPixels(a,b,tolerance){
    if(a.length!==b.length)throw Error('As imagens precisam ter o mesmo tamanho.');
    const output=new Uint8ClampedArray(a.length);let changed=0;
    for(let n=0;n<a.length;n+=4){
      const difference=Math.max(Math.abs(a[n]-b[n]),Math.abs(a[n+1]-b[n+1]),Math.abs(a[n+2]-b[n+2]));
      if(difference>tolerance){output[n]=236;output[n+1]=65;output[n+2]=112;changed++;}
      else{const gray=Math.round((a[n]+a[n+1]+a[n+2])/3);output[n]=output[n+1]=output[n+2]=Math.round(gray*.25+191);}
      output[n+3]=255;
    }
    return {pixels:output,fraction:changed/(a.length/4)};
  }
  function normalizeCanvas(source,width,height){
    const out=document.createElement('canvas');out.width=width;out.height=height;const ctx=out.getContext('2d');ctx.fillStyle='#fff';ctx.fillRect(0,0,width,height);
    const scale=Math.min(width/source.width,height/source.height);ctx.drawImage(source,0,0,source.width,source.height,(width-source.width*scale)/2,(height-source.height*scale)/2,source.width*scale,source.height*scale);return out;
  }
  async function compare(inputs,selection,tolerance){
    const docs=[];let report;
    try{
      for(const file of inputs)docs.push(await pdfjsLib.getDocument({data:new Uint8Array(await file.arrayBuffer()),isEvalSupported:false}).promise);
      const total=Math.max(docs[0].numPages,docs[1].numPages);
      const indices=selection.trim()?pageNumbers(selection,Math.min(docs[0].numPages,docs[1].numPages)):Array.from({length:total},(_,n)=>n);
      if(indices.length>30)throw Error('Compare até 30 pares por vez. Use o campo de páginas.');
      report=await PDFLib.PDFDocument.create();const font=await report.embedFont(PDFLib.StandardFonts.Helvetica);const rows=[];
      for(const index of indices){
        checkCancelled();
        const images=[];try{
          status('Comparando página '+(index+1)+' de '+total+'…');
          for(const doc of docs)images.push(index<doc.numPages?await renderPage(doc,index,800):null);
          let fraction=1,diff=null,dimensionsChanged=false;
          if(images[0]&&images[1]){
            dimensionsChanged=Math.abs(images[0].pdfWidth-images[1].pdfWidth)>.5||Math.abs(images[0].pdfHeight-images[1].pdfHeight)>.5;
            const a=normalizeCanvas(images[0],550,720),b=normalizeCanvas(images[1],550,720);
            images.push(a,b);const ctx=a.getContext('2d'),pixels=ctx.getImageData(0,0,550,720);
            const compared=diffPixels(pixels.data,b.getContext('2d').getImageData(0,0,550,720).data,tolerance);fraction=compared.fraction;
            pixels.data.set(compared.pixels);ctx.putImageData(pixels,0,0);diff=a;
          }
          const page=report.addPage([842,595]);page.drawText('Comparacao visual - pagina '+(index+1),{x:25,y:565,size:15,font});
          page.drawText(images[0]&&images[1]?'Pixels diferentes: '+(fraction*100).toFixed(2)+'%  |  Rosa: diferencas visuais'+(dimensionsChanged?'  |  Tamanho da pagina alterado':''):'Pagina ausente em uma das versoes.',{x:25,y:544,size:9,font});
          for(let column=0;column<3;column++){
            page.drawText(['Versao A','Versao B','Diferencas'][column],{x:25+column*270,y:515,size:11,font});
            const image=column<2?images[column]:diff;
            if(image){const embedded=await report.embedPng(image.toDataURL('image/png')),scale=Math.min(252/image.width,465/image.height);page.drawImage(embedded,{x:25+column*270+(252-image.width*scale)/2,y:30,width:image.width*scale,height:image.height*scale});}
          }
          rows.push({page:index+1,fraction,dimensionsChanged,missing:!images[0]||!images[1]});
        }finally{for(const image of new Set(images.filter(Boolean)))image.width=image.height=0;}
        await new Promise(r=>setTimeout(r,0));
      }
      const bytes=await report.save();checkCancelled();download(bytes,'comparacao-visual.pdf');
      result.replaceChildren();const title=document.createElement('h3');title.textContent='Comparação visual concluída';result.append(title);
      const summary=document.createElement('p');summary.textContent=rows.filter(r=>r.fraction>.0001||r.dimensionsChanged).length+' de '+rows.length+' pares com diferença visual ou de tamanho. O relatório mostra A, B e a diferença. Não é uma validação jurídica nem uma comparação semântica.';result.append(summary);result.hidden=false;
    }finally{for(const doc of docs)await doc.destroy();}
  }
  async function audit(file,selection){
    auditBytes=await file.arrayBuffer();const doc=await pdfjsLib.getDocument({data:new Uint8Array(auditBytes.slice(0)),isEvalSupported:false}).promise;
    try{
      auditPages=doc.numPages;const chosen=[...new Set(selection.trim()?pageNumbers(selection,doc.numPages):Array.from({length:doc.numPages},(_,n)=>n))];
      if(chosen.length>80)throw Error('Analise até 80 páginas por operação.');
      const known=new Map();candidates=[];result.replaceChildren();const heading=document.createElement('h3');heading.textContent='Revise antes de remover';result.append(heading);
      const note=document.createElement('p');note.textContent='Marque somente as páginas que deseja remover. Nenhuma opção começa marcada. A detecção é visual e pode confundir conteúdo muito claro com página em branco.';result.append(note);
      const grid=document.createElement('div');grid.className='audit-grid';result.append(grid);result.hidden=false;
      for(const index of chosen){
        checkCancelled();
        status('Analisando página '+(index+1)+' de '+doc.numPages+'…');const image=await renderPage(doc,index,480);
        try{
          const pixels=image.getContext('2d').getImageData(0,0,image.width,image.height).data;
          const textContent=await(await doc.getPage(index+1)).getTextContent();
          const hasText=textContent.items.some(item=>(item.str||'').trim());
          const blank=!hasText&&statistics(pixels).darkFraction<.0008;
          const digest=await crypto.subtle.digest('SHA-256',pixels);
          const hash=image.width+'x'+image.height+':'+Array.from(new Uint8Array(digest),b=>b.toString(16).padStart(2,'0')).join('');
          const duplicate=known.has(hash)?known.get(hash):null;if(!known.has(hash))known.set(hash,index);
          if(blank||duplicate!==null){
            const label=document.createElement('label');label.className='audit-candidate';
            const checkbox=document.createElement('input');checkbox.type='checkbox';checkbox.checked=false;checkbox.dataset.page=String(index);
            const preview=document.createElement('img');preview.src=image.toDataURL('image/png');preview.alt='Prévia da página '+(index+1);
            const text=document.createElement('span');text.textContent='Página '+(index+1)+(blank?' · possivelmente em branco':' · igual à página '+(duplicate+1)+' nesta renderização');
            label.append(preview,checkbox,text);grid.append(label);candidates.push({index,checkbox});
          }
        }finally{image.width=image.height=0;}
        await new Promise(r=>setTimeout(r,0));
      }
      if(!candidates.length){const text=document.createElement('p');text.textContent='Não foram encontradas candidatas a páginas vazias ou repetições idênticas nesta seleção.';result.append(text);return;}
      const apply=document.createElement('button');apply.className='primary';apply.textContent='Salvar cópia sem as páginas marcadas';
      apply.onclick=async()=>{
        if(busy)return;
        const removed=new Set(candidates.filter(c=>c.checkbox.checked).map(c=>c.index));
        if(!removed.size){status('Marque as páginas que deseja remover.',true);return;}
        if(removed.size>=auditPages){status('Mantenha pelo menos uma página.',true);return;}
        busy=true;render();apply.disabled=true;
        try{const input=await PDFLib.PDFDocument.load(auditBytes),output=await PDFLib.PDFDocument.create();const indices=input.getPageIndices().filter(n=>!removed.has(n));for(const page of await output.copyPages(input,indices))output.addPage(page);download(await output.save(),'documento-revisado.pdf');status('Cópia criada com '+indices.length+' páginas. Original preservado.');}
        catch(e){status(e.message,true);}finally{busy=false;render();apply.disabled=false;$('#processPanel').hidden=true;}
      };
      result.append(apply);
    }finally{await doc.destroy();}
  }
  async function nup(file,selection,count){
    if(![2,4,9].includes(count))throw Error('Escolha 2, 4 ou 9 páginas por folha.');
    const source=await PDFLib.PDFDocument.load(await file.arrayBuffer()),output=await PDFLib.PDFDocument.create();
    const indices=selection.trim()?pageNumbers(selection,source.getPageCount()):source.getPageIndices();
    const columns=count===2?2:count===4?2:3,rows=count===2?1:columns;
    const width=count===2?842:595,height=count===2?595:842,margin=18,gap=10;
    const cellW=(width-margin*2-gap*(columns-1))/columns,cellH=(height-margin*2-gap*(rows-1))/rows;
    let sheet;
    for(let n=0;n<indices.length;n++){
      checkCancelled();
      if(n%count===0)sheet=output.addPage([width,height]);
      const original=source.getPage(indices[n]),crop=original.getCropBox(),rotation=((original.getRotation().angle%360)+360)%360;
      // A truly empty page has no content stream. Keep its reserved cell empty.
      if(!original.node.Contents())continue;
      const embedded=await output.embedPage(original,{left:crop.x,bottom:crop.y,right:crop.x+crop.width,top:crop.y+crop.height});
      const swapped=rotation===90||rotation===270,visualW=swapped?embedded.height:embedded.width,visualH=swapped?embedded.width:embedded.height;
      const scale=Math.min(cellW/visualW,cellH/visualH),column=n%count%columns,row=Math.floor(n%count/columns),w=visualW*scale,h=visualH*scale;
      let x=margin+column*(cellW+gap)+(cellW-w)/2,y=height-margin-row*(cellH+gap)-cellH+(cellH-h)/2;
      if(rotation===90)y+=embedded.width*scale;
      else if(rotation===180){x+=embedded.width*scale;y+=embedded.height*scale;}
      else if(rotation===270)x+=embedded.height*scale;
      sheet.drawPage(embedded,{x,y,width:embedded.width*scale,height:embedded.height*scale,rotate:PDFLib.degrees(-rotation)});
    }
    return output.save();
  }
  async function imagesToPdf(inputs,paper,margin){
    const output=await PDFLib.PDFDocument.create();
    for(const file of inputs){
      checkCancelled();
      const image=await imageCanvas(file);try{
        const embedded=await output.embedJpg(image.toDataURL('image/jpeg',.95));
        const [width,height]=paper==='a4land'?[842,595]:paper==='letter'?[612,792]:paper==='original'?[595,595*image.height/image.width]:[595,842];
        const allowed=Math.min(margin,Math.max(0,(Math.min(width,height)-10)/2));
        const scale=Math.min((width-2*allowed)/embedded.width,(height-2*allowed)/embedded.height);
        const page=output.addPage([width,height]);page.drawRectangle({x:0,y:0,width,height,color:PDFLib.rgb(1,1,1)});
        page.drawImage(embedded,{x:(width-embedded.width*scale)/2,y:(height-embedded.height*scale)/2,width:embedded.width*scale,height:embedded.height*scale});
      }finally{image.width=image.height=0;}
    }
    return output.save();
  }
  const priorRun=$('#run').onclick;$('#run').onclick=async()=>{
    if(!(tool in additions||tool==='images'))return priorRun();
    if(busy||!files.length)return;
    const operation=tool,inputs=files.slice(),selection=$('#pages').value;
    if(operation==='compare'&&inputs.length!==2){status('Adicione exatamente dois PDFs: versão A e versão B.',true);return;}
    if(['audit','nup'].includes(operation)&&inputs.length!==1){status('Esta ferramenta aceita um PDF por vez.',true);return;}
    cancelled=false;cancelButton.hidden=false;cancelButton.disabled=false;busy=true;render();resetResults();result.hidden=true;$('#processSpinner').hidden=false;$('#processTitle').textContent='Preparando o resultado';
    try{
      if(operation==='compare')await compare(inputs,selection,Number($('#compareTolerance').value)||24);
      else if(operation==='audit')await audit(inputs[0],selection);
      else if(operation==='nup'){const bytes=await nup(inputs[0],selection,Number($('#nupCount').value)||2);checkCancelled();download(bytes,'varias-paginas-por-folha.pdf');}
      else{const bytes=await imagesToPdf(inputs,$('#imagePaper').value||'a4',Number($('#imageMargin').value)||0);checkCancelled();download(bytes,'imagens-formatadas.pdf');}
      status(operation==='audit'?'Análise concluída. Confira as prévias e marque apenas o que deseja remover.':'Pronto. Salve o resultado ou encontre o novo PDF na biblioteca.');
    }catch(error){if(cancelled){result.hidden=true;auditBytes=null;}status(/password|encrypt/i.test(error.message)?'Este PDF está protegido por senha.':error.message,true);}
    finally{busy=false;render();$('#processPanel').hidden=true;cancelButton.hidden=true;}
  };
  cards();overview();
  return {statistics,diffPixels,nup,imagesToPdf,hub,overview};
})();

// Load final document-intake safeguards after all tool wrappers are initialized.
const folhaIntakeGuard = document.createElement('script');
folhaIntakeGuard.src = 'hardening.js';
folhaIntakeGuard.onload = () => {
  const boletoScript = document.createElement('script');
  boletoScript.src = 'boleto.js';
  boletoScript.onload = () => {
    const activeScript = document.createElement('script');
    activeScript.src = 'active-document.js';
    activeScript.onload = () => {
      const redactScript = document.createElement('script');
      redactScript.src = 'redaction.js';
      redactScript.onload = () => {
        const incomingScript = document.createElement('script');
        incomingScript.src = 'incoming.js';
        document.body.append(incomingScript);
      };
      document.body.append(redactScript);
    };
    document.body.append(activeScript);
  };
  document.body.append(boletoScript);
};
document.body.append(folhaIntakeGuard);
const folhaUi16 = document.createElement('link');
folhaUi16.rel = 'stylesheet';
folhaUi16.href = 'ui16.css';
document.head.append(folhaUi16);
