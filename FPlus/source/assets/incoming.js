'use strict';
// Android ACTION_VIEW / ACTION_SEND intake. The native bridge accepts only PDF bytes.
(() => {
  if (typeof Android === 'undefined' || typeof Android.takeIncomingBase64 !== 'function') return;
  try {
    const encoded = Android.takeIncomingBase64();
    if (!encoded) return;
    let name = String(Android.getIncomingName() || 'documento-recebido.pdf').split(/[\\/]/).pop();
    name = name.replace(/[<>:"|?*\x00-\x1f]/g, '-').slice(0, 100);
    if (!/\.pdf$/i.test(name)) name = 'documento-recebido.pdf';
    const binary = atob(encoded);
    if (!binary.startsWith('%PDF-')) throw Error('O arquivo recebido não é um PDF válido.');
    const bytes = new Uint8Array(binary.length);
    for (let position = 0; position < binary.length; position += 32768) {
      const end = Math.min(binary.length, position + 32768);
      for (let index = position; index < end; index++) bytes[index] = binary.charCodeAt(index);
    }
    const file = new File([bytes], name, {type:'application/pdf',lastModified:Date.now()});
    files = [file];render();resetResults();
    FolhaWorkspace.hub();
    status('PDF recebido do Android: ' + name + '. Escolha uma ferramenta para continuar.');
    PdfLibrary.put(file,name).catch(error => status('Documento recebido; a cópia na biblioteca falhou: ' + error.message,true));
  } catch (error) {
    status('Não foi possível abrir o PDF recebido do Android: ' + error.message,true);
    PdfLibrary.switchView('tools');
  }
})();
