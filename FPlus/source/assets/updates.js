'use strict';
// Extra tools use the original local PDF libraries and Android save/share bridge.
const extraTools = {
  remove: ['Excluir páginas', 'Guarde só o que <i>precisa.</i>', 'Remova páginas de um PDF.<br>O original permanece no seu aparelho.', 'Excluir páginas', 'Documento PDF', 'As páginas restantes, na ordem original.'],
  split: ['Dividir PDF', 'Um documento, <i>vários arquivos.</i>', 'Separe páginas em PDFs individuais.<br>Salve todas juntas em um arquivo ZIP.', 'Dividir em PDFs', 'ZIP com PDFs', 'Uma página por PDF. Até 80 páginas por operação.'],
  png: ['PDF para PNG', 'Páginas em <i>alta nitidez.</i>', 'Converta páginas para imagens PNG.<br>Salve todas juntas em um arquivo ZIP.', 'Gerar imagens PNG', 'ZIP com PNGs', 'Até 80 páginas. Resolução limitada a 2400 pixels no maior lado.'],
  stamp: ['Numerar / rodapé', 'Cada página, <i>identificada.</i>', 'Adicione um rodapé personalizado ao documento.<br>Use {pagina} e {total} para numerar.', 'Adicionar rodapé', 'Documento PDF', 'Texto adicionado ao rodapé das páginas selecionadas.'],
  optimize: ['Otimizar PDF', 'Uma estrutura <i>mais enxuta.</i>', 'Regrave a estrutura interna do PDF.<br>As imagens mantêm sua resolução.', 'Otimizar estrutura', 'Documento PDF', 'Pode reduzir o tamanho; a redução não é garantida.'],
  docx: ['PDF para Word (texto)', 'Seu texto, <i>editável.</i>', 'Extraia o texto para um documento Word.<br>Imagens e diagramação não são preservadas.', 'Exportar texto para Word', 'Documento Word', 'Arquivo DOCX com o texto. Execute OCR antes em digitalizações.']
};
Object.assign(cfg, extraTools);
const extraKeys = Object.keys(extraTools);
for (const key of extraKeys) {
  const button = document.createElement('button');
  button.dataset.tool = key;
  const label = document.createElement('span');
  label.textContent = extraTools[key][0];
  button.append('▤ ', label);
  button.onclick = () => selectTool(key);
  $('nav').append(button);
}
const originalSelect = selectTool;
selectTool = function(key) {
  if (busy) return;
  originalSelect(key);
  const paged = ['extract', 'remove', 'split', 'png', 'stamp', 'docx'].includes(key);
  $('#pageSettings').hidden = !paged;
  document.querySelector('label[for="pages"]').textContent = key === 'remove' ? 'Páginas para excluir (obrigatório)' : key === 'extract' ? 'Páginas para extrair (obrigatório)' : 'Páginas (vazio = todas)';
  $('#pageSettings .hint').textContent = 'Ex.: 1-3, 5, 8. Intervalos invertidos como 3-1 são aceitos.';
  $('#stampSettings').hidden = key !== 'stamp';
  $('#pages').value = '';
  $('#acceptHint').textContent = extraKeys.includes(key) ? 'Selecione um PDF por operação' : $('#acceptHint').textContent;
};
const stampSettings = document.createElement('div');
stampSettings.id = 'stampSettings';
stampSettings.hidden = true;
stampSettings.innerHTML = '<label for="stampText">Texto do rodapé</label><input id="stampText" value="Página {pagina} de {total}" maxlength="160"><p class="hint">Em páginas rotacionadas, o rodapé segue a orientação original.</p>';
document.querySelector('label[for="outputName"]').before(stampSettings);
$('#updates').onclick = () => {
  alert('Folha PDF+ 1.2.0\n\nEdição independente: mantém o Folha PDF original instalado.\n\nNovidades: excluir páginas, dividir em ZIP, exportar PNG em ZIP, numeração/rodapé, otimização estrutural e PDF para Word (somente texto). O OCR preserva páginas que já contêm texto.\n\nSem envio de documentos. OCR em português, inglês e espanhol incluído.\n\nLimites: Word não preserva layout ou imagens. Excel, PowerPoint, proteção por senha, edição de texto existente e assinatura digital não estão incluídos. Alterações invalidam assinaturas digitais anteriores. OCR pode errar; revise o resultado.\n\nEsta edição não usa o atualizador da versão original.');
};

pageNumbers = function(value, total) {
  if (!value.trim()) throw Error('Informe as páginas desejadas.');
  const out = [];
  for (const part of value.split(',')) {
    const match = part.trim().match(/^(\d+)(?:\s*-\s*(\d+))?$/);
    if (!match) throw Error('Use páginas como 1-3, 5, 8.');
    const a = Number(match[1]), b = Number(match[2] || match[1]);
    if (a < 1 || b < 1 || a > total || b > total) throw Error('O documento tem ' + total + ' páginas.');
    const step = a <= b ? 1 : -1;
    for (let n = a; step > 0 ? n <= b : n >= b; n += step) out.push(n - 1);
    if (out.length > 2000) throw Error('Limite de 2000 páginas selecionadas por operação.');
  }
  return out;
};

// ZIP STORE: avoids external libraries and produces ordinary, interoperable archives.
function zipFiles(entries) {
  const encoder = new TextEncoder();
  const local = [], central = [];
  let offset = 0, centralSize = 0;
  const table = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    table[n] = c >>> 0;
  }
  for (const entry of entries) {
    const name = encoder.encode(entry.name);
    const data = typeof entry.data === 'string' ? encoder.encode(entry.data) : new Uint8Array(entry.data);
    let crc = 0xffffffff;
    for (const byte of data) crc = table[(crc ^ byte) & 255] ^ (crc >>> 8);
    crc = (crc ^ 0xffffffff) >>> 0;
    const header = new Uint8Array(30 + name.length), h = new DataView(header.buffer);
    h.setUint32(0, 0x04034b50, true); h.setUint16(4, 20, true); h.setUint16(6, 0x800, true);
    h.setUint16(12, 0x21, true); h.setUint32(14, crc, true);
    h.setUint32(18, data.length, true); h.setUint32(22, data.length, true); h.setUint16(26, name.length, true);
    header.set(name, 30); local.push(header, data);
    const directory = new Uint8Array(46 + name.length), d = new DataView(directory.buffer);
    d.setUint32(0, 0x02014b50, true); d.setUint16(4, 20, true); d.setUint16(6, 20, true);
    d.setUint16(8, 0x800, true); d.setUint16(14, 0x21, true); d.setUint32(16, crc, true);
    d.setUint32(20, data.length, true); d.setUint32(24, data.length, true); d.setUint16(28, name.length, true);
    d.setUint32(42, offset, true); directory.set(name, 46);
    central.push(directory); centralSize += directory.length; offset += header.length + data.length;
  }
  const end = new Uint8Array(22), e = new DataView(end.buffer);
  e.setUint32(0, 0x06054b50, true); e.setUint16(8, entries.length, true); e.setUint16(10, entries.length, true);
  e.setUint32(12, centralSize, true); e.setUint32(16, offset, true);
  const result = new Uint8Array(offset + centralSize + 22);
  let pos = 0;
  for (const chunk of [...local, ...central, end]) { result.set(chunk, pos); pos += chunk.length; }
  return result;
}
const xml = value => value.replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f]/g, '').replace(/[<>&"']/g, c => ({'<':'&lt;','>':'&gt;','&':'&amp;','"':'&quot;',"'":'&apos;'}[c]));
function wordDocument(pageTexts) {
  const paragraphs = pageTexts.map((text, index) => (index ? '<w:p><w:r><w:br w:type="page"/></w:r></w:p>' : '') + text.split('\n').map(line => '<w:p><w:r><w:t xml:space="preserve">' + xml(line) + '</w:t></w:r></w:p>').join('')).join('');
  return zipFiles([
    {name:'[Content_Types].xml', data:'<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>'},
    {name:'_rels/.rels', data:'<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>'},
    {name:'word/document.xml', data:'<?xml version="1.0" encoding="UTF-8"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>'+paragraphs+'<w:sectPr><w:pgSz w:w="11906" w:h="16838"/></w:sectPr></w:body></w:document>'}
  ]);
}

// Keep the original bridge, extending its safe output filename handling.
download = function(bytes, filename, type = 'application/pdf') {
  let custom = $('#outputName').value.trim().replace(/[<>:"/\\|?*\x00-\x1f]/g, '-').replace(/\.(pdf|txt|jpe?g|png|zip|docx)$/i, '');
  if (custom) {
    const extension = filename.slice(filename.lastIndexOf('.'));
    const number = type === 'image/jpeg' ? '-' + (filename.match(/(\d+)\.jpg$/) || ['', '1'])[1] : '';
    filename = custom + number + extension;
  }
  const blob = new Blob([bytes], {type});
  const row = document.createElement('div');
  for (const [caption, method] of [['↓ Salvar ', 'saveFile'], ['Compartilhar ', 'shareFile']]) {
    const button = document.createElement('button');
    button.className = method === 'saveFile' ? 'primary' : 'secondary';
    button.textContent = caption + (method === 'saveFile' ? filename : '');
    button.onclick = () => {
      button.disabled = true;
      const reader = new FileReader();
      reader.onload = () => {
        try { Android[method](filename, reader.result.split(',')[1], type.split(';')[0]); }
        catch (error) { status('Falha ao preparar o salvamento: ' + error.message, true); }
        finally { button.disabled = false; }
      };
      reader.onerror = () => { status('Não foi possível preparar o arquivo.', true); button.disabled = false; };
      reader.readAsDataURL(blob);
    };
    row.append(button);
  }
  $('#results').append(row);
};

const originalRun = $('#run').onclick;
$('#run').onclick = async function() {
  if (!extraKeys.includes(tool)) return originalRun();
  if (busy || !files.length) return;
  if (files.length !== 1) return status('Esta ferramenta aceita um PDF por vez. Remova os arquivos extras.', true);
  const selectedTool = tool, selection = $('#pages').value, footer = $('#stampText').value;
  busy = true; render(); resetResults(); status('Preparando documento…');
  try {
    const raw = await files[0].arrayBuffer();
    const source = await PDFLib.PDFDocument.load(raw);
    const total = source.getPageCount();
    let selected = selection.trim() ? pageNumbers(selection, total) : source.getPageIndices();
    if (['remove', 'extract'].includes(selectedTool) && !selection.trim()) throw Error('Informe as páginas.');
    if (selectedTool === 'remove') {
      const removed = new Set(selected);
      selected = source.getPageIndices().filter(n => !removed.has(n));
      if (!selected.length) throw Error('Mantenha pelo menos uma página no PDF.');
      const result = await PDFLib.PDFDocument.create();
      for (const page of await result.copyPages(source, selected)) result.addPage(page);
      download(await result.save(), 'paginas-restantes.pdf');
    } else if (selectedTool === 'split') {
      if (selected.length > 80) throw Error('Selecione até 80 páginas por operação.');
      const entries = [];
      for (const [index, page] of selected.entries()) {
        status('Separando página ' + (index+1) + ' de ' + selected.length);
        const result = await PDFLib.PDFDocument.create();
        result.addPage((await result.copyPages(source, [page]))[0]);
        entries.push({name:'pagina-'+String(index+1).padStart(3,'0')+'.pdf', data:await result.save()});
      }
      download(zipFiles(entries), 'paginas-pdf.zip', 'application/zip');
    } else if (selectedTool === 'optimize') {
      const result = await source.save({useObjectStreams:true, addDefaultPage:false});
      download(result, 'documento-otimizado.pdf');
      status('Concluído: ' + (raw.byteLength/1048576).toFixed(2) + ' MB → ' + (result.length/1048576).toFixed(2) + ' MB. A redução depende do PDF.');
      return;
    } else if (selectedTool === 'stamp') {
      const font = await source.embedFont(PDFLib.StandardFonts.Helvetica);
      if (!footer.trim()) throw Error('Informe o texto do rodapé.');
      for (const index of new Set(selected)) {
        const page = source.getPage(index), box = page.getCropBox();
        const label = footer.replace(/\{pagina\}/g, String(index+1)).replace(/\{total\}/g, String(total));
        try { font.encodeText(label); } catch (_) { throw Error('O rodapé aceita letras latinas; remova emojis ou símbolos incompatíveis.'); }
        const size = Math.min(11, (box.width-32)/Math.max(1, font.widthOfTextAtSize(label, 1)));
        if (size < 4) throw Error('Rodapé muito longo para a largura da página.');
        page.drawText(label, {x:box.x+16, y:box.y+16, size, font, color:PDFLib.rgb(.25,.3,.25)});
      }
      download(await source.save(), 'documento-numerado.pdf');
    } else {
      pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://appassets.androidplatform.net/vendor/pdf.worker.js';
      const pdf = await pdfjsLib.getDocument({data:new Uint8Array(raw.slice(0)),isEvalSupported:false}).promise;
      try {
        if (selectedTool === 'png') {
          if (selected.length > 80) throw Error('Selecione até 80 páginas por operação.');
          const entries = [];
          let byteCount = 0;
          for (const [n, index] of selected.entries()) {
            status('Convertendo página ' + (n+1) + ' de ' + selected.length);
            const page = await pdf.getPage(index+1), base = page.getViewport({scale:1});
            const viewport = page.getViewport({scale:Math.min(2.5,2400/Math.max(base.width,base.height))});
            const canvas = document.createElement('canvas');
            canvas.width = Math.ceil(viewport.width); canvas.height = Math.ceil(viewport.height);
            try {
              await page.render({canvasContext:canvas.getContext('2d'),viewport,background:'rgb(255,255,255)'}).promise;
              const blob = await new Promise(resolve => canvas.toBlob(resolve, 'image/png'));
              if (!blob) throw Error('Não foi possível gerar a imagem.');
              byteCount += blob.size;
              if (byteCount > 70*1048576) throw Error('O resultado excede 70 MB. Selecione menos páginas.');
              entries.push({name:'pagina-'+String(n+1).padStart(3,'0')+'.png',data:await blob.arrayBuffer()});
            } finally { canvas.width = canvas.height = 0; page.cleanup(); }
          }
          download(zipFiles(entries), 'paginas-png.zip', 'application/zip');
        } else if (selectedTool === 'docx') {
          const texts = [];
          for (const index of selected) {
            status('Extraindo texto da página ' + (index+1));
            const page = await pdf.getPage(index+1), content = await page.getTextContent();
            texts.push(content.items.map(item => (item.str || '') + (item.hasEOL ? '\n' : ' ')).join(''));
          }
          if (!texts.some(text => text.trim())) throw Error('Nenhum texto encontrado. Execute o OCR antes.');
          download(wordDocument(texts), 'texto-editavel.docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
        }
      } finally { await pdf.destroy(); }
    }
    status('Pronto! Use Salvar ou Compartilhar abaixo.');
  } catch (error) {
    status(/encrypt|password/i.test(error.message) ? 'PDF protegido. Esta edição não abre PDFs com senha.' : 'Não foi possível concluir: ' + error.message, true);
  } finally { busy = false; render(); }
};
