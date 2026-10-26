'use strict';
// Folha PDF+ 1.6: protect document intake from mislabeled / duplicated files.
(() => {
  const footerVersion = document.querySelector('aside footer span');
  if (footerVersion) footerVersion.textContent = '1.9.3';
  const updateEyebrow = document.querySelector('#updateView .eyebrow');
  if (updateEyebrow) updateEyebrow.textContent = 'FOLHA PDF+ 1.9.3';
  const originalAdd = add;
  let intake = Promise.resolve();
  const signatures = {
    pdf: bytes => bytes.length >= 5 && String.fromCharCode(...bytes).includes('%PDF-'),
    jpg: bytes => bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff,
    png: bytes => bytes.length >= 8 && [137, 80, 78, 71, 13, 10, 26, 10].every((v, i) => bytes[i] === v)
  };
  add = function (items) {
    const batch = Array.from(items || []);
    if (busy || !batch.length) return;
    const selectedTool = tool;
    intake = intake.then(async () => {
      const approved = [], errors = [];
      for (const file of batch) {
        if (tool !== selectedTool || busy) return;
        if (!file.size || file.size > 50 * 1048576) {
          errors.push(file.name + ': arquivo vazio ou maior que 50 MB.');
          continue;
        }
        const kind = /\.pdf$/i.test(file.name) ? 'pdf' : /\.jpe?g$/i.test(file.name) ? 'jpg' : /\.png$/i.test(file.name) ? 'png' : null;
        if (!kind || (selectedTool === 'images' && kind === 'pdf') || (selectedTool !== 'images' && selectedTool !== 'ocr' && kind !== 'pdf')) {
          errors.push(file.name + ': formato não aceito.');
          continue;
        }
        try {
          const bytes = new Uint8Array(await file.slice(0, 1024).arrayBuffer());
          if (!signatures[kind](bytes)) {
            errors.push(file.name + ': conteúdo não corresponde à extensão.');
            continue;
          }
        } catch (_) {
          errors.push(file.name + ': não foi possível ler o arquivo.');
          continue;
        }
        if (files.some(old => old.name === file.name && old.size === file.size && old.lastModified === file.lastModified) ||
            approved.some(old => old.name === file.name && old.size === file.size && old.lastModified === file.lastModified)) {
          errors.push(file.name + ': já está na lista.');
          continue;
        }
        if (files.length + approved.length >= 30) {
          errors.push('Limite de 30 arquivos por operação para reduzir travamentos.');
          break;
        }
        approved.push(file);
      }
      if (tool !== selectedTool || busy) return;
      if (approved.length) originalAdd(approved);
      if (errors.length) status(errors.join(' '), true);
    }).catch(error => status('Falha ao adicionar arquivos: ' + error.message, true));
  };
})();
