'use strict';
// Network updates run in the native Updater, outside the offline WebView.
// The WebView intentionally blocks external requests to protect documents.
const FolhaUpdates=(()=>{
  function show(){PdfLibrary.switchView('update');}
  function check(){
    const status=$('#updateStatus');
    try{
      if(typeof Android==='undefined'||typeof Android.openUpdates!=='function')throw Error('Atualizador Android indisponível. Abra esta tela pelo aplicativo instalado.');
      Android.openUpdates();
      status.textContent='No menu do Android, toque em “Verificar atualizações agora”. A verificação automática também pode ser ativada nesse menu.';
      status.className='';
    }catch(error){status.textContent=error.message;status.className='error';}
  }
  $('#updates').onclick=show;
  $('#checkUpdates').onclick=check;
  return {show,check};
})();
