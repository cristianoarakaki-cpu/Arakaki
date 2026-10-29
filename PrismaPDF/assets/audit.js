'use strict';
const PrismaAudit=(()=>{
 async function check(bytes,config){const audit={sha256:[...new Uint8Array(await crypto.subtle.digest('SHA-256',bytes))].map(x=>x.toString(16).padStart(2,'0')).join(''),createdAt:new Date().toISOString(),totalPages:config.totalPages,completedPages:0,pages:[],structuralIssue:false,error:false};let worker,doc;try{
 const inspect=await PDFLib.PDFDocument.load(bytes,{updateMetadata:false});if(inspect.getPageCount()!==config.totalPages||['Names','AcroForm','Metadata'].some(key=>inspect.catalog.has(PDFLib.PDFName.of(key)))||inspect.getPages().some(p=>{const a=p.node.lookup(PDFLib.PDFName.of('Annots'));return a!==undefined&&(!(a instanceof PDFLib.PDFArray)||a.size()>0)}))audit.structuralIssue=true;
 doc=await pdfjsLib.getDocument({data:new Uint8Array(bytes),isEvalSupported:false}).promise;if(doc.numPages!==config.totalPages||doc.numPages>12)throw Error('Invalid page count');
 worker=await Tesseract.createWorker(config.language,1,{workerPath:location.origin+'/vendor/worker.min.js',corePath:location.origin+'/vendor',langPath:location.origin+'/vendor/lang'});
 for(let n=1;n<=doc.numPages;n++){config.progress('Conferindo a cópia final — OCR na página '+n+'/'+doc.numPages+'…');const p=await doc.getPage(n),content=await p.getTextContent();if(content.items.some(i=>i.str?.trim()))audit.structuralIssue=true;const base=p.getViewport({scale:1}),view=p.getViewport({scale:Math.min(2.5,2200/Math.max(base.width,base.height))}),c=document.createElement('canvas');c.width=Math.ceil(view.width);c.height=Math.ceil(view.height);try{await p.render({canvasContext:c.getContext('2d'),viewport:view,background:'rgb(255,255,255)'}).promise;const {data}=await worker.recognize(c,{}, {text:true});audit.pages.push({page:n,...PrismaAuditCore.page(data.text||'',config.options,config.terms)});audit.completedPages++;}finally{c.width=c.height=0}}
 }catch{audit.error=true;}finally{if(worker)try{await worker.terminate()}catch{}if(doc)try{await doc.destroy()}catch{}}
 audit.status=PrismaAuditCore.status(audit);return audit;}
 return{check};
})();
