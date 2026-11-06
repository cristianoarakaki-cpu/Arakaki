'use strict';
// Compatibility for maintained Android WebViews lacking this standard API.
if(!Promise.withResolvers)Promise.withResolvers=function(){let resolve,reject;const promise=new Promise((a,b)=>{resolve=a;reject=b});return{promise,resolve,reject}};
try{
 window.pdfjsLib=await import('./vendor/pdf.mjs');
 for(const module of ['./speech-core.js','./ocr-core.js','./ocr-engine.js','./speech.js','./app.js'])await import(module);
}catch(error){const notice=document.getElementById('notice');if(notice)notice.textContent='Não foi possível iniciar o leitor. Atualize o Android System WebView e reabra o app.';console.error('Falha ao iniciar leitor local:',error)}
