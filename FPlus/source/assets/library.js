'use strict';
const PdfLibrary=(()=>{
  let dbPromise,entries=[],pageIndex=0,drawToken=0,current=null,pdf=null,pageNumber=1,zoom=1,renderTask=null,viewerToken=0,openToken=0;
  const perPage=12;
  function database(){
    if(!dbPromise)dbPromise=new Promise((resolve,reject)=>{
      const request=indexedDB.open('folha-pdf-library',1);
      request.onupgradeneeded=()=>request.result.createObjectStore('pdfs',{keyPath:'id'});
      request.onsuccess=()=>resolve(request.result);
      request.onerror=()=>{dbPromise=null;reject(Error('Não foi possível abrir a biblioteca local.'));};
    });
    return dbPromise;
  }
  async function transaction(mode,action){
    const db=await database();
    return new Promise((resolve,reject)=>{
      const tx=db.transaction('pdfs',mode),request=action(tx.objectStore('pdfs'));
      tx.oncomplete=()=>resolve(request.result);
      tx.onerror=tx.onabort=()=>reject(Error('Falha ao acessar a biblioteca. Verifique o espaço livre do aparelho.'));
    });
  }
  async function list(){
    const records=await transaction('readonly',store=>store.getAll());
    return records.map(({blob,...meta})=>meta);
  }
  async function put(blob,name){
    if(blob.size>50*1048576)throw Error('A biblioteca aceita PDFs de até 50 MB. Salve este resultado fora do app.');
    const bytes=await blob.arrayBuffer();
    if(!new TextDecoder().decode(bytes.slice(0,1024)).includes('%PDF-'))throw Error('Este arquivo não parece ser um PDF válido.');
    const hash=await crypto.subtle.digest('SHA-256',bytes);
    const id=Array.from(new Uint8Array(hash),v=>v.toString(16).padStart(2,'0')).join('');
    const existing=await transaction('readonly',store=>store.get(id));
    const entry={id,name:name||'documento.pdf',size:blob.size,date:Date.now(),blob};
    if(existing){entry.name=existing.name;entry.date=existing.date;}
    await transaction('readwrite',store=>store.put(entry));
    if(!$('#libraryView').hidden)await refresh();
    return id;
  }
  function notice(message,error=false){$('#libraryNotice').textContent=message;$('#libraryNotice').className=error?'error':'';}
  function switchView(view){
    if(busy&&view!=='tools'){status('Conclua ou cancele o processamento antes de sair.');return false;}
    for(const name of ['tools','library','viewer','update','hub'])$('#'+name+'View').hidden=name!==view;
    $('#crumb').textContent=view==='hub'?'Ferramentas':view==='tools'?cfg[tool][0]:view==='library'?'Meus PDFs':view==='viewer'?'Leitor de PDF':'Atualizações';
    $('#tabLibrary').classList.toggle('active',view==='library'||view==='viewer');
    $('#tabTools').classList.toggle('active',view==='tools'||view==='hub');
    document.body.classList.remove('tools-open');$('#navBackdrop').hidden=true;
    document.documentElement.scrollTop=0;
    return true;
  }
  async function show(){
    if(!switchView('library'))return;
    openToken++;
    viewerToken++;
    if(renderTask)try{renderTask.cancel();await renderTask.promise;}catch(_){}
    if(pdf){const previous=pdf;pdf=null;await previous.destroy();}
    current=null;await refresh();
  }
  async function thumbnail(entry,card,token){
    let doc;
    try{
      const record=await transaction('readonly',store=>store.get(entry.id));
      if(!record||token!==drawToken)return;
      doc=await pdfjsLib.getDocument({data:new Uint8Array(await record.blob.arrayBuffer()),isEvalSupported:false}).promise;
      if(token!==drawToken)return;
      const page=await doc.getPage(1),base=page.getViewport({scale:1}),viewport=page.getViewport({scale:Math.min(1,240/base.width,270/base.height)});
      const canvas=document.createElement('canvas');canvas.width=Math.ceil(viewport.width);canvas.height=Math.ceil(viewport.height);
      await page.render({canvasContext:canvas.getContext('2d'),viewport,background:'rgb(255,255,255)'}).promise;
      if(token===drawToken){card.querySelector('.pdf-preview').replaceChildren(canvas);card.querySelector('.pdf-pages').textContent=doc.numPages+' pág.';}
    }catch(_){if(token===drawToken)card.querySelector('.pdf-pages').textContent='Prévia indisponível';}
    finally{if(doc)await doc.destroy();}
  }
  async function refresh(){
    const token=++drawToken;
    try{
      entries=await list();if(token!==drawToken)return;if(typeof FolhaWorkspace!=='undefined')FolhaWorkspace.overview();
      const term=$('#librarySearch').value.trim().toLocaleLowerCase('pt-BR');
      const filtered=entries.filter(entry=>entry.name.toLocaleLowerCase('pt-BR').includes(term));
      filtered.sort($('#librarySort').value==='name'?(a,b)=>a.name.localeCompare(b.name,'pt-BR'):(a,b)=>b.date-a.date);
      const count=Math.max(1,Math.ceil(filtered.length/perPage));pageIndex=Math.min(pageIndex,count-1);
      const grid=$('#libraryGrid');grid.replaceChildren();
      if(!filtered.length){const empty=document.createElement('div');empty.className='library-empty';empty.innerHTML='<span>▤</span><h2>'+ (term?'Nenhum PDF encontrado':'Seu espaço para documentos')+'</h2><p>'+(term?'Tente outro nome na busca.':'Importe PDFs do aparelho ou crie um documento nas ferramentas. Eles aparecerão aqui.')+'</p>';grid.append(empty);}
      const cards=[];
      for(const entry of filtered.slice(pageIndex*perPage,(pageIndex+1)*perPage)){
        const card=document.createElement('article');card.className='pdf-card';
        card.innerHTML='<button class="pdf-preview" aria-label="Abrir PDF"><span>PDF</span></button><div class="pdf-card-body"><h3></h3><p><span class="pdf-pages">PDF</span><span class="pdf-size"></span></p><div class="pdf-actions"><button class="text-button pdf-open">Abrir</button><button class="text-button pdf-export">Exportar</button><button class="text-button pdf-remove" aria-label="Remover cópia da biblioteca">×</button></div></div>';
        card.querySelector('h3').textContent=entry.name;card.querySelector('h3').title=entry.name;
        card.querySelector('.pdf-size').textContent=(entry.size/1048576).toFixed(1)+' MB';
        card.querySelector('.pdf-preview').onclick=card.querySelector('.pdf-open').onclick=()=>open(entry.id);
        card.querySelector('.pdf-export').onclick=async()=>{try{const record=await transaction('readonly',s=>s.get(entry.id));await exportRecord(record);}catch(e){notice(e.message,true);}};
        card.querySelector('.pdf-remove').onclick=async()=>{
          if(!confirm('Remover a cópia de “'+entry.name+'” da biblioteca? Arquivos exportados e originais permanecem no aparelho.'))return;
          try{await transaction('readwrite',s=>s.delete(entry.id));await refresh();}catch(e){notice(e.message,true);}
        };
        grid.append(card);cards.push([entry,card]);
      }
      $('#libraryPage').textContent=filtered.length+' PDF(s) · '+(pageIndex+1)+' / '+count;
      $('#libraryPrev').disabled=pageIndex===0;$('#libraryNext').disabled=pageIndex>=count-1;
      for(const [entry,card]of cards){if(token!==drawToken)break;await thumbnail(entry,card,token);}
    }catch(e){notice(e.message,true);}
  }
  async function exportRecord(record){
    if(!record)throw Error('Este PDF não está mais na biblioteca.');
    const data=await new Promise((resolve,reject)=>{const reader=new FileReader();reader.onload=()=>resolve(reader.result.split(',')[1]);reader.onerror=()=>reject(Error('Falha ao preparar o PDF.'));reader.readAsDataURL(record.blob);});
    Android.saveFile(record.name,data,'application/pdf');
  }
  async function drawPage(){
    if(!pdf)return;
    const doc=pdf,token=++viewerToken;
    if(renderTask)try{renderTask.cancel();await renderTask.promise;}catch(_){}
    $('#viewerPrev').disabled=pageNumber===1;$('#viewerNext').disabled=pageNumber===doc.numPages;
    $('#viewerPage').textContent=pageNumber+' / '+doc.numPages+' · '+Math.round(zoom*100)+'%';
    const page=await doc.getPage(pageNumber);if(token!==viewerToken)return;
    const base=page.getViewport({scale:1}),available=Math.max(220,$('.viewer-canvas-wrap').clientWidth-24);
    const cssScale=Math.min(available/base.width,1.6)*zoom;
    const scale=Math.min(cssScale*Math.min(devicePixelRatio||1,2),3200/Math.max(base.width,base.height));
    const viewport=page.getViewport({scale}),canvas=$('#viewerCanvas');canvas.width=Math.ceil(viewport.width);canvas.height=Math.ceil(viewport.height);
    canvas.style.width=Math.ceil(base.width*cssScale)+'px';canvas.style.height=Math.ceil(base.height*cssScale)+'px';
    renderTask=page.render({canvasContext:canvas.getContext('2d'),viewport,background:'rgb(255,255,255)'});
    try{await renderTask.promise;}catch(e){if(e.name!=='RenderingCancelledException')throw e;}
  }
  async function open(id){
    if(busy)return;
    const requestToken=++openToken;
    try{
      const record=await transaction('readonly',s=>s.get(id));if(!record)throw Error('PDF não encontrado.');
      if(requestToken!==openToken)return;
      if(pdf){await pdf.destroy();pdf=null;}
      switchView('viewer');current=record;pageNumber=1;zoom=1;
      $('#viewerName').textContent=record.name;$('#viewerStatus').textContent='Abrindo PDF…';$('#viewerQuery').value='';
      const loaded=await pdfjsLib.getDocument({data:new Uint8Array(await record.blob.arrayBuffer()),isEvalSupported:false}).promise;
      if(requestToken!==openToken){await loaded.destroy();return;}
      pdf=loaded;
      await drawPage();$('#viewerStatus').textContent='';
    }catch(e){$('#viewerStatus').textContent=/password/i.test(e.message)?'Este leitor ainda não abre PDFs protegidos por senha.':e.message;}
  }
  $('#tabLibrary').onclick=$('#sidebarLibrary').onclick=$('#viewerBack').onclick=show;
  $('#tabTools').onclick=()=>switchView('tools');
  $('#importPdfs').onclick=()=>$('#libraryFiles').click();
  $('#libraryFiles').onchange=async event=>{
    const incoming=Array.from(event.target.files);event.target.value='';$('#importPdfs').disabled=true;let count=0,failures=[];
    for(const file of incoming)try{notice('Importando '+file.name+'…');await put(file,file.name);count++;}catch(e){failures.push(file.name+': '+e.message);}
    $('#importPdfs').disabled=false;notice(count+' PDF(s) importado(s). '+failures.join(' '),!!failures.length);await refresh();
  };
  $('#librarySearch').oninput=()=>{pageIndex=0;refresh();};$('#librarySort').onchange=()=>{pageIndex=0;refresh();};
  $('#libraryPrev').onclick=()=>{pageIndex=Math.max(0,pageIndex-1);refresh();};$('#libraryNext').onclick=()=>{pageIndex++;refresh();};
  for(const [id,fn]of [['viewerPrev',()=>{pageNumber--;}],['viewerNext',()=>{pageNumber++;}],['viewerZoomOut',()=>{zoom=Math.max(.5,zoom-.25);}],['viewerZoomIn',()=>{zoom=Math.min(3,zoom+.25);}]]){
    $('#'+id).onclick=async()=>{if(!pdf)return;fn();pageNumber=Math.max(1,Math.min(pdf.numPages,pageNumber));try{await drawPage();}catch(e){$('#viewerStatus').textContent=e.message;}};
  }
  $('#viewerSave').onclick=async()=>{try{await exportRecord(current);}catch(e){$('#viewerStatus').textContent=e.message;}};
  $('#viewerUse').onclick=()=>{
    if(!current||busy)return;
    const record=current;selectTool('ocr');files=[new File([record.blob],record.name,{type:'application/pdf'})];render();
    status('PDF da biblioteca pronto para processar. Escolha os ajustes antes de iniciar.');
  };
  $('#viewerFind').onclick=async()=>{
    if(!pdf)return;const term=$('#viewerQuery').value.trim().toLocaleLowerCase('pt-BR');if(!term)return;
    const doc=pdf,start=pageNumber,query=term;$('#viewerFind').disabled=true;
    try{
      for(let step=1;step<=doc.numPages;step++){
        if(doc!==pdf||$('#viewerView').hidden)return;
        const number=(start-1+step)%doc.numPages+1,page=await doc.getPage(number),content=await page.getTextContent();
        const text=content.items.map(i=>i.str||'').join(' ').toLocaleLowerCase('pt-BR');
        if(text.includes(query)){pageNumber=number;await drawPage();$('#viewerStatus').textContent='Texto encontrado na página '+number+'.';return;}
      }
      $('#viewerStatus').textContent='Texto não encontrado. Se o PDF for uma digitalização, execute OCR nas ferramentas.';
    }catch(e){$('#viewerStatus').textContent=e.message;}finally{$('#viewerFind').disabled=false;}
  };
  const oldSelect=selectTool;selectTool=function(key){if(busy)return oldSelect(key);oldSelect(key);switchView('tools');};
  const oldDownload=download;download=function(bytes,name,type='application/pdf'){
    oldDownload(bytes,name,type);
    if(type==='application/pdf'){
      const custom=$('#outputName').value.trim().replace(/[<>:"/\\|?*\x00-\x1f]/g,'-').replace(/\.(pdf|txt|jpe?g|png|zip|docx)$/i,'');
      put(new Blob([bytes],{type}),custom?custom+'.pdf':name).catch(e=>status('Arquivo pronto para salvar. A cópia na biblioteca falhou: '+e.message,true));
    }
  };
  const oldAdd=add;add=function(items){const before=new Set(files);oldAdd(items);for(const file of files)if(!before.has(file)&&/\.pdf$/i.test(file.name))put(file,file.name).catch(e=>status('Arquivo selecionado. A cópia na biblioteca falhou: '+e.message,true));};
  pdfjsLib.GlobalWorkerOptions.workerSrc='https://appassets.androidplatform.net/vendor/pdf.worker.js';
  show();
  return {put,list,show,switchView,refresh,open};
})();
