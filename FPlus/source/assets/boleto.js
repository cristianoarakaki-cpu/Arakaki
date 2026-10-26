'use strict';
// Folha PDF+ boleto reader: local-first OCR and optional native browser barcode detection.
(() => {
  cfg.boleto = ['Ler boleto', 'Seu boleto, <i>pronto para copiar.</i>',
    'Reconheça a linha digitável de um boleto em PDF ou imagem.<br>Confira os números antes de pagar.',
    'Reconhecer boleto', 'Código para copiar', 'Copie a linha digitável ou o código de barras reconhecido.'];

  const nav = document.createElement('button');
  nav.dataset.tool = 'boleto';
  nav.innerHTML = '<span class="nav-icon">▥</span><span>Ler boleto</span><em>NOVO</em>';
  nav.onclick = () => selectTool('boleto');
  document.querySelector('nav').append(nav);
  const total = document.querySelector('#toolTotal');
  if (total) total.textContent = String(document.querySelectorAll('nav button[data-tool]').length);

  const info = document.createElement('div');
  info.id = 'boletoOptions';
  info.hidden = true;
  info.innerHTML = '<div class="feature-info"><strong>Leitura local do boleto</strong><p>PDF, JPG ou PNG. O texto pode ser reconhecido mesmo em um documento digitalizado.</p><p>Confira beneficiário, valor, vencimento e os números no documento original antes de efetuar um pagamento.</p></div>';
  document.querySelector('#ocrSettings').before(info);

  const previousSelect = selectTool;
  selectTool = function (key) {
    previousSelect(key);
    if (busy) return;
    info.hidden = key !== 'boleto';
    if (key === 'boleto') {
      $('#files').accept = 'application/pdf,image/jpeg,image/png';
      $('#acceptHint').textContent = 'Escolha um boleto em PDF, JPG ou PNG';
      $('#pageSettings').hidden = true;
      $('#ocrSettings').hidden = true;
      $('#rotateSettings').hidden = true;
    }
  };

  // This tool takes just one PDF or image. Standard file checks remain in the guard.
  const previousAdd = add;
  add = async function (items) {
    if (tool !== 'boleto') return previousAdd(items);
    if (busy) return;
    const incoming = Array.from(items || []);
    if (!incoming.length) return;
    const f = incoming[0];
    if (!/\.(pdf|jpe?g|png)$/i.test(f.name) || !f.size || f.size > 50 * 1048576) {
      status('Escolha um PDF, JPG ou PNG de até 50 MB.', true);return;
    }
    try {
      const header = new Uint8Array(await f.slice(0, 1024).arrayBuffer());
      const pdf = /\.pdf$/i.test(f.name), jpg = /\.jpe?g$/i.test(f.name), png = /\.png$/i.test(f.name);
      const signatureOk = pdf ? String.fromCharCode(...header).includes('%PDF-') : jpg ?
        header[0] === 255 && header[1] === 216 && header[2] === 255 :
        png && [137, 80, 78, 71, 13, 10, 26, 10].every((v,i) => header[i] === v);
      if (!signatureOk) throw Error('O conteúdo não corresponde à extensão do arquivo.');
      if (tool !== 'boleto' || busy) return;
      files = [f];render();resetResults();
      status(incoming.length > 1 ? 'Será analisado somente o primeiro arquivo.' : 'Pronto para reconhecer.');
    } catch (error) { status('Não foi possível selecionar o boleto: ' + error.message, true); }
  };

  // Modulo-10 for the three banking-boleto free fields and the four collection blocks.
  function mod10(digits) {
    let sum = 0, weight = 2;
    for (let i = digits.length - 1; i >= 0; i--) {
      let value = Number(digits[i]) * weight;
      sum += Math.floor(value / 10) + value % 10;
      weight = weight === 2 ? 1 : 2;
    }
    return (10 - sum % 10) % 10;
  }
  function mod11(digits, collection = false) {
    let sum = 0, weight = 2;
    for (let i = digits.length - 1; i >= 0; i--) {
      sum += Number(digits[i]) * weight;
      weight = weight === 9 ? 2 : weight + 1;
    }
    const remainder = sum % 11;
    if (collection) return remainder === 0 || remainder === 1 ? 0 : 11 - remainder;
    return remainder === 0 || remainder === 1 || remainder === 10 ? 1 : 11 - remainder;
  }
  function valid47(s) {
    return /^\d{47}$/.test(s) &&
      mod10(s.slice(0, 9)) === +s[9] &&
      mod10(s.slice(10, 20)) === +s[20] &&
      mod10(s.slice(21, 31)) === +s[31];
  }
  function valid48(s) {
    if (!/^8\d{47}$/.test(s)) return false;
    const method = s[2] === '6' || s[2] === '7' ? 10 : s[2] === '8' || s[2] === '9' ? 11 : 0;
    if (!method) return false;
    for (let i = 0; i < 48; i += 12) {
      const fragment = s.slice(i, i + 11);
      if ((method === 10 ? mod10(fragment) : mod11(fragment, true)) !== +s[i + 11]) return false;
    }
    return true;
  }
  function bankBarcode(line) {
    return line.slice(0, 4) + line[32] + line.slice(33) + line.slice(4, 9) + line.slice(10, 20) + line.slice(21, 31);
  }
  function candidates(raw) {
    const normalized = String(raw || '').replace(/[Oo]/g, '0').replace(/[Il|]/g, '1');
    const fragments = normalized.split(/\n|\r|\t|[A-Za-z]{3,}/).map(part => part.replace(/\D/g, ''));
    const spans = (normalized.match(/(?:[0-9][ \t.\-]*){44,48}/g) || []).map(part => part.replace(/\D/g, ''));
    const output = [];
    // A continuous line may carry dots, spaces, hyphens or OCR line breaks.
    for (const chunk of [...spans, ...fragments, normalized.replace(/\D/g, '')]) {
      for (const size of [47, 48, 44]) {
        if (chunk.length < size || chunk.length > size + 20) continue;
        for (let i = 0; i <= chunk.length - size; i++) {
          const value = chunk.slice(i, i + size);
          if (!output.some(item => item.value === value)) output.push({value, length: size});
          if (output.length >= 60) return output;
        }
      }
    }
    return output;
  }
  function rank(candidate) {
    const s = candidate.value;
    if (candidate.length === 47) return valid47(s) ? 3 : 0;
    if (candidate.length === 48) return valid48(s) ? 3 : 0;
    if (candidate.length === 44) return /^\d{44}$/.test(s) ? 1 : 0;
    return 0;
  }
  async function copy(value, button) {
    try {
      if (navigator.clipboard && navigator.clipboard.writeText) await navigator.clipboard.writeText(value);
      else {
        const element = document.createElement('textarea');
        element.value = value;element.setAttribute('readonly', '');
        element.style.position = 'fixed';element.style.opacity = '0';
        document.body.append(element);element.select();
        const ok = document.execCommand('copy');element.remove();
        if (!ok) throw Error('A cópia não foi autorizada.');
      }
      button.textContent = '✓ Copiado';status('Código copiado. Confira com o boleto original antes de pagar.');
    } catch (error) { status('Não foi possível copiar automaticamente: ' + error.message, true); }
  }
  function show(results) {
    const root = document.createElement('section');
    root.className = 'report boleto-report';
    const title = document.createElement('h3');title.textContent = 'Resultado da leitura';root.append(title);
    if (!results.length) {
      const p = document.createElement('p');
      p.textContent = 'Não identifiquei uma linha digitável confiável. Tente uma foto mais nítida, bem iluminada e sem cortes.';
      root.append(p);
    }
    for (const item of results.slice(0, 3)) {
      const box = document.createElement('div');box.className = 'boleto-code';
      const type = document.createElement('strong');
      type.textContent = item.value.length === 44 ? 'Código de barras (44 números)' :
        item.value.length === 47 ? 'Linha digitável bancária (47 números)' : 'Linha digitável de arrecadação (48 números)';
      const value = document.createElement('code');value.textContent = item.value;
      const note = document.createElement('p');
      note.textContent = item.score >= 3 ? 'Dígitos verificadores dos campos conferidos. Isso não confirma beneficiário nem autenticidade.' :
        'Leitura não validada: confira todos os números antes de usar.';
      const btn = document.createElement('button');btn.className = 'primary';btn.textContent = 'Copiar números';
      btn.onclick = () => copy(item.value, btn);
      box.append(type, value, note, btn);root.append(box);
    }
    $('#results').append(root);
  }
  async function textFromPdf(file) {
    const pdf = await readPdf(file);
    let data = '';
    try {
      for (let n = 1; n <= Math.min(4, pdf.numPages); n++) {
        const p = await pdf.getPage(n), content = await p.getTextContent();
        data += '\n' + content.items.map(i => i.str || '').join(' ');
      }
    } finally { await pdf.destroy(); }
    return data;
  }
  async function canvasFromFile(file) {
    if (/\.pdf$/i.test(file.name)) {
      const pdf = await readPdf(file);
      try {
        const p = await pdf.getPage(1), base = p.getViewport({scale:1});
        const viewport = p.getViewport({scale:Math.min(3, 2800 / Math.max(base.width, base.height))});
        const c = document.createElement('canvas');
        c.width = Math.ceil(viewport.width);c.height = Math.ceil(viewport.height);
        await p.render({canvasContext:c.getContext('2d'),viewport}).promise;
        return c;
      } finally { await pdf.destroy(); }
    }
    return imageCanvas(file);
  }
  async function barcodeFromCanvas(canvas) {
    if (!('BarcodeDetector' in window)) return [];
    try {
      const supported = await BarcodeDetector.getSupportedFormats();
      if (!supported.includes('itf')) return [];
      const detector = new BarcodeDetector({formats:['itf']});
      return (await detector.detect(canvas)).map(v => ({value:String(v.rawValue).replace(/\D/g, ''), length:44})).filter(x => x.value.length === 44);
    } catch (_) { return []; }
  }
  const previousRun = $('#run').onclick;
  $('#run').onclick = async () => {
    if (tool !== 'boleto') return previousRun();
    if (busy || files.length !== 1) return;
    busy = true;render();resetResults();
    let worker, canvas;
    try {
      const f = files[0];status('Procurando a linha digitável…');
      let raw = /\.pdf$/i.test(f.name) ? await textFromPdf(f) : '';
      let found = candidates(raw).map(item => ({...item, score:rank(item)})).filter(item => item.score >= 3);
      if (!found.length) {
        status('Analisando imagem do boleto no aparelho…');
        canvas = await canvasFromFile(f);
        const direct = await barcodeFromCanvas(canvas);
        if (direct.length) found.push(...direct.map(item => ({...item, score:1})));
        worker = await Tesseract.createWorker('por', 1, {
          workerPath:'https://appassets.androidplatform.net/vendor/worker.min.js',
          corePath:'https://appassets.androidplatform.net/vendor',
          langPath:'https://appassets.androidplatform.net/vendor/lang'
        });
        await worker.setParameters({tessedit_pageseg_mode:'11'});
        raw = (await worker.recognize(canvas)).data.text || '';
        found.push(...candidates(raw).map(item => ({...item, score:rank(item)})).filter(item => item.score > 0));
      }
      found.sort((a,b) => b.score - a.score);
      show(found.filter((item, index) => found.findIndex(other => other.value === item.value) === index));
      status(found.length ? 'Leitura concluída. Confira o código e os dados do boleto.' : 'Não foi possível identificar o código deste boleto.', !found.length);
    } catch (error) {
      status('Erro na leitura: ' + (error && error.message || String(error)), true);
    } finally {
      if (worker) try { await worker.terminate(); } catch (_) {}
      if (canvas) canvas.width = canvas.height = 0;
      busy = false;render();
    }
  };
})();
