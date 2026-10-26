'use strict';
// Privacy redaction: OCR proposals + explicit human review + rasterized final PDF.
// This removes original PDF text and objects from the output, not just drawing an overlay.
(() => {
  const config = ['Ocultar dados pessoais', 'Proteja informações <i>pessoais.</i>',
    'Encontre CPFs, documentos, registros e possíveis nomes.<br>Revise cada sugestão antes de ocultar.',
    'Analisar dados pessoais', 'PDF com tarjas', 'Uma cópia rasterizada, sem camada de texto original.'];
  cfg.redact = config;
  const button = document.createElement('button');
  button.dataset.tool = 'redact';
  button.innerHTML = '<span class="nav-icon">▩</span><span>Ocultar dados pessoais</span><em>LGPD</em>';
  button.onclick = () => selectTool('redact');
  document.querySelector('nav').append(button);
  const toolTotal = $('#toolTotal');
  if (toolTotal) toolTotal.textContent = String(document.querySelectorAll('nav button[data-tool]').length);

  const panel = document.createElement('section');
  panel.id = 'redactSettings';
  panel.hidden = true;
  panel.innerHTML = '<div class="feature-info"><strong>Tarja definitiva após sua confirmação</strong><p>Detecção automática é uma ajuda, não uma garantia. Confira todas as páginas e marque os trechos desejados.</p><p>O PDF resultante é uma imagem de cada página, sem os objetos e textos originais, e perde links, campos, assinaturas digitais e pesquisa textual.</p></div><label class="check-row"><input type="checkbox" id="redactCpf" checked><span>CPF</span></label><label class="check-row"><input type="checkbox" id="redactRg" checked><span>RG e identidade</span></label><label class="check-row"><input type="checkbox" id="redactRegistration" checked><span>Matrículas e números de registro</span></label><label class="check-row"><input type="checkbox" id="redactName" checked><span>Possíveis nomes próximos de campos identificados</span></label><p class="hint">Por segurança, analise até 8 páginas por operação. Se necessário, divida documentos maiores antes.</p>';
  const additional = document.createElement('div');
  additional.innerHTML = '<label class="check-row"><input type="checkbox" id="redactCnpj" checked><span>CNPJ</span></label><label class="check-row"><input type="checkbox" id="redactOtherIds" checked><span>CNH, CNS, PIS/PASEP, COREN, CRM e outros registros identificados</span></label><label class="check-row"><input type="checkbox" id="redactContact" checked><span>E-mail e telefone</span></label><label class="check-row"><input type="checkbox" id="redactBirth" checked><span>Data de nascimento quando identificada</span></label><label class="check-row"><input type="checkbox" id="redactLoose"><span>Números longos sem identificação (sugestões extras para revisão)</span></label>';
  panel.append(additional);
  const performance=document.createElement('div');
  performance.innerHTML='<label for="redactQuality">Velocidade e qualidade</label><select id="redactQuality"><option value="1800">Equilibrado · mais rápido</option><option value="2400">Detalhado · letras pequenas</option></select><label class="check-row"><input type="checkbox" id="redactForceOcr"><span>Aplicar OCR também nas páginas com texto selecionável<small>Mais lento; útil quando há digitalizações misturadas com texto.</small></span></label>';
  panel.append(performance);
  const custom=document.createElement('div');
  custom.className='redact-custom';
  custom.innerHTML='<h3>Minhas regras de ocultação</h3><label for="redactTerms">Palavras, nomes ou frases para procurar</label><textarea id="redactTerms" rows="3" placeholder="Um por linha. Ex.: Nome da pessoa, número específico ou termo sigiloso"></textarea><p class="hint">Oculta a expressão encontrada. Use uma linha por termo. Não há envio desses dados para a internet.</p><label for="redactLabels">Novos tipos de documentos ou identificadores</label><textarea id="redactLabels" rows="3" placeholder="Um rótulo por linha. Ex.: Prontuário, Registro hospitalar, Cartão do paciente"></textarea><p class="hint">Procura o número ou código que vem após esse rótulo (ex.: Prontuário: 123456). Revise os resultados antes de gerar o PDF.</p>';
  panel.append(custom);
  $('#ocrSettings').before(panel);

  const result = document.createElement('section');
  result.id = 'redactReview';result.className = 'report';result.hidden = true;
  $('#results').after(result);
  const ready = document.createElement('section');
  ready.id = 'redactReady'; ready.className = 'report'; ready.hidden = true;
  $('#results').before(ready);
  let pages = [], suggestions = [], analyzedFile = null;
  function showStage(title, message, target, action) {
    ready.replaceChildren(); ready.hidden = false;
    const heading = document.createElement('h3'); heading.textContent = title;
    const detail = document.createElement('p'); detail.textContent = message;
    const button = document.createElement('button'); button.className = 'primary';
    button.textContent = action; button.onclick = () => target.scrollIntoView({behavior:'smooth',block:'start'});
    ready.append(heading,detail,button);
  }

  const priorSelect = selectTool;
  selectTool = function (key) {
    priorSelect(key);
    if (busy) return;
    panel.hidden = key !== 'redact';result.hidden = true;ready.hidden=true;clearState();
    if (key === 'redact') {
      $('#files').accept = 'application/pdf';
      $('#acceptHint').textContent = 'Escolha um PDF para localizar dados pessoais';
      $('#pageSettings').hidden = true;
      $('#ocrSettings').hidden = true;
      $('#rotateSettings').hidden = true;
      $('#run').textContent = 'Analisar dados pessoais';
    }
  };
  function clearState() { pages = [];suggestions = [];analyzedFile = null;result.replaceChildren();ready.hidden=true; }
  function validCpf(value) {
    const s = value.replace(/\D/g, '');
    if (s.length !== 11 || /^(\d)\1{10}$/.test(s)) return false;
    for (let len = 9; len <= 10; len++) {
      let sum = 0;
      for (let i = 0; i < len; i++) sum += Number(s[i]) * (len + 1 - i);
      let check = (sum * 10) % 11;
      if (check === 10) check = 0;
      if (check !== +s[len]) return false;
    }
    return true;
  }
  function validCnpj(value) {
    const s = value.replace(/\D/g, '');
    if (s.length !== 14 || /^(\d)\1{13}$/.test(s)) return false;
    for (let len = 12; len <= 13; len++) {
      const weights = len === 12 ? [5,4,3,2,9,8,7,6,5,4,3,2] : [6,5,4,3,2,9,8,7,6,5,4,3,2];
      const sum = weights.reduce((total,w,i) => total + Number(s[i])*w, 0);
      const check = sum % 11 < 2 ? 0 : 11 - sum % 11;
      if (check !== +s[len]) return false;
    }
    return true;
  }
  function groupLines(words) {
    const lines = [];
    for (const w of words) {
      if (!w.bbox || !w.text || !w.text.trim()) continue;
      const cy = (w.bbox.y0 + w.bbox.y1) / 2;
      const height = Math.max(6, w.bbox.y1 - w.bbox.y0);
      let line = lines.find(l => Math.abs(l.cy - cy) < Math.min(l.height, height) * .62);
      if (!line) { line = {cy,height,words:[]};lines.push(line); }
      line.words.push(w);
      line.cy = (line.cy * (line.words.length - 1) + cy) / line.words.length;
    }
    return lines.map(line => {
      line.words.sort((a,b) => a.bbox.x0 - b.bbox.x0);
      let text = '';
      const mapped = [];
      for (const w of line.words) {
        if (text) text += ' ';
        const start = text.length;text += w.text;
        mapped.push({...w,start,end:text.length});
      }
      return {text, mapped};
    });
  }
  function detect(lines, pageIndex) {
    const rules = [];
    const escapeRx=value=>value.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
    const customTerms=($('#redactTerms').value||'').split(/\r?\n/).map(s=>s.trim()).filter(s=>s.length>=2).slice(0,80);
    const customLabels=($('#redactLabels').value||'').split(/\r?\n/).map(s=>s.trim()).filter(s=>s.length>=2).slice(0,50);
    for(const term of customTerms)rules.push({type:'Expressão personalizada',rx:new RegExp(escapeRx(term).replace(/\s+/g,'\\s+'),'gi')});
    for(const label of customLabels)rules.push({type:'Identificador personalizado · '+label,rx:new RegExp('(?:^|\\b)'+escapeRx(label).replace(/\s+/g,'\\s+')+'\\s*[:#=\\-]?\\s*([A-Z0-9][A-Z0-9.\\-/]{2,30})','gi')});
    if ($('#redactCpf').checked) rules.push({type:'CPF', rx:/\b\d{3}[.\s]?\d{3}[.\s]?\d{3}[-\s]?\d{2}\b/g, valid:validCpf});
    if ($('#redactCnpj').checked) rules.push({type:'CNPJ', rx:/\b\d{2}[.\s]?\d{3}[.\s]?\d{3}[\/\s]?\d{4}[-\s]?\d{2}\b/g, valid:validCnpj});
    if ($('#redactRg').checked) rules.push({type:'RG / identidade', rx:/\b(?:RG|IDENTIDADE|REGISTRO\s+GERAL)\s*[:Nº°.#-]*\s*([\d][\d.\-\s]{5,16}[\dXx])\b/gi});
    if ($('#redactRegistration').checked) rules.push({type:'Matrícula / registro', rx:/\b(?:MATR[IÍ]CULA|REGISTRO\s+(?:N[º°.]|N[ÚU]MERO)?|COREN|CRM|CNS|PIS|PASEP)\s*[:Nº°.#-]*\s*([\d][\d.\-\/]{3,18}\d)\b/gi});
    if ($('#redactOtherIds').checked) rules.push({type:'Documento / registro', rx:/\b(?:CNH|CARTEIRA\s+(?:DE\s+)?HABILITA[ÇC][ÃA]O|CART[ÃA]O\s+(?:NACIONAL\s+)?(?:DO\s+)?SUS|CNS|NIS|PIS|PASEP|COREN(?:[-\s][A-Z]{2})?|CRM(?:[-\s][A-Z]{2})?|OAB|RNE|RNM)\s*[:Nº°.#-]*\s*([\d][\d.\-\/]{4,19}\d)\b/gi});
    if ($('#redactContact').checked) {
      rules.push({type:'E-mail', rx:/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/gi});
      rules.push({type:'Telefone', rx:/(?:\(?\d{2}\)?[\s-]?)?9?\d{4}[\s-]?\d{4}\b/g});
    }
    if ($('#redactBirth').checked) rules.push({type:'Nascimento', rx:/\b(?:DATA\s+DE\s+NASCIMENTO|NASCIMENTO|DT\.?\s*NASC\.?)\s*[:\-]?\s*(\d{2}[\/.-]\d{2}[\/.-]\d{4})\b/gi});
    if ($('#redactLoose').checked) rules.push({type:'Número sem identificação · conferir', rx:/\b\d{9,14}\b/g});
    if ($('#redactName').checked) {
      // Balanças, laboratórios e clínicas também usam "ID:NOME SOBRENOME".
      rules.push({type:'Nome junto de identificação', rx:/\b(?:NOME(?:\s+COMPLETO)?|PACIENTE|SERVIDOR[A]?|TITULAR|RESPONS[ÁA]VEL|BENEFICI[ÁA]RIO|REQUERENTE|IDENTIFICA[ÇC][ÃA]O|AVALIAD[OA]|ID)\s*[:=\-]\s*([A-ZÀ-Ú][A-Za-zÀ-ú'-]{1,}(?:\s+(?![A-Za-zÀ-ú]+\s*:)[A-ZÀ-Ú][A-Za-zÀ-ú'-]{1,}){1,5})/gi});
      // Sugestão conservadora para nomes em MAIÚSCULAS sem campo rotulado.
      rules.push({type:'Possível nome sem rótulo · conferir', rx:/\b([A-ZÀ-Ú]{3,}(?:\s+(?:DA|DE|DO|DAS|DOS|E))?\s+[A-ZÀ-Ú]{3,}(?:\s+[A-ZÀ-Ú]{3,}){0,3})\b/g, valid:value=>!/(?:AN[ÁA]LISE|RELAT[ÓO]RIO|COMPOSI[ÇC][ÃA]O|CORPORAL|MUSCULAR|OBESIDADE|GORDURA|PESO|MASSA|TOTAL|AVALIA[ÇC][ÃA]O|SAUD[ÁA]VEL|IMPED[ÂA]NCIA|IDADE|ALTURA|SEXO|RELAXMEDIC)/i.test(value)});
    }
    const list = [];
    for (const line of lines) for (const rule of rules) {
      rule.rx.lastIndex = 0;
      for (const match of line.text.matchAll(rule.rx)) {
        const sensitive = match[1] || match[0];
        if (rule.valid && !rule.valid(sensitive)) continue;
        const start = match.index + (match[1] ? match[0].lastIndexOf(match[1]) : 0);
        const end = start + sensitive.length;
        const covered = line.mapped.filter(word => word.end > start && word.start < end);
        if (!covered.length) continue;
        const minX = Math.min(...covered.map(w => w.bbox.x0));
        const minY = Math.min(...covered.map(w => w.bbox.y0));
        const maxX = Math.max(...covered.map(w => w.bbox.x1));
        const maxY = Math.max(...covered.map(w => w.bbox.y1));
        list.push({pageIndex,type:rule.type,text:sensitive,rect:{x:minX,y:minY,w:maxX-minX,h:maxY-minY},enabled:true});
      }
    }
    return list;
  }
  function putPreview(parent, item) {
    const thumb = document.createElement('div');thumb.className = 'redact-thumbnail';
    const canvas = document.createElement('canvas'), source = pages[item.pageIndex].canvas;
    const scale = Math.min(1, 370/source.width);
    canvas.width = Math.round(source.width*scale);canvas.height = Math.round(source.height*scale);
    const context = canvas.getContext('2d');context.drawImage(source,0,0,canvas.width,canvas.height);
    context.fillStyle = '#111';
    const r=item.rect;
    context.fillRect(Math.max(0,(r.x-5)*scale),Math.max(0,(r.y-4)*scale),Math.min(canvas.width,(r.w+10)*scale),Math.min(canvas.height,(r.h+8)*scale));
    thumb.append(canvas);parent.append(thumb);
  }
  function review() {
    result.replaceChildren();result.hidden=false;
    const heading=document.createElement('h3');heading.textContent='Revisão antes da ocultação';result.append(heading);
    const warning=document.createElement('p');warning.className='hint';
    warning.textContent='Revise TODAS as páginas do original. O OCR pode deixar passar documentos, nomes, carimbos, imagens, QR codes e manuscritos. Nenhuma tarja é aplicada sem sua confirmação.';
    result.append(warning);
    const count=document.createElement('p');count.textContent=suggestions.length+' trecho(s) sugerido(s) em '+pages.length+' página(s).';result.append(count);
    const manualLabel=document.createElement('p');manualLabel.className='hint';
    manualLabel.textContent='Tarja manual: arraste o dedo sobre uma área da prévia para ocultar trechos não encontrados automaticamente.';
    result.append(manualLabel);
    for (const [pageIndex,page] of pages.entries()) {
      const holder=document.createElement('div');holder.className='redact-manual';
      const label=document.createElement('strong');label.textContent='Página '+(pageIndex+1)+' — marcar área manualmente';holder.append(label);
      const preview=document.createElement('canvas');
      const scale=Math.min(1,360/page.canvas.width);
      preview.width=Math.max(1,Math.round(page.canvas.width*scale));
      preview.height=Math.max(1,Math.round(page.canvas.height*scale));
      const context=preview.getContext('2d');
      const draw=rect=>{
        context.drawImage(page.canvas,0,0,preview.width,preview.height);
        if(rect){context.fillStyle='#000b';context.fillRect(rect.x,rect.y,rect.w,rect.h);}
      };
      draw();let origin=null;
      const point=e=>{const box=preview.getBoundingClientRect();return {x:(e.clientX-box.left)*preview.width/box.width,y:(e.clientY-box.top)*preview.height/box.height};};
      preview.onpointerdown=e=>{e.preventDefault();origin=point(e);preview.setPointerCapture(e.pointerId);};
      preview.onpointermove=e=>{if(!origin)return;const p=point(e);draw({x:Math.min(origin.x,p.x),y:Math.min(origin.y,p.y),w:Math.abs(origin.x-p.x),h:Math.abs(origin.y-p.y)});};
      preview.onpointerup=e=>{
        if(!origin)return;
        const p=point(e),rect={x:Math.min(origin.x,p.x),y:Math.min(origin.y,p.y),w:Math.abs(origin.x-p.x),h:Math.abs(origin.y-p.y)};origin=null;
        if(rect.w<5||rect.h<5){draw();return;}
        suggestions.push({pageIndex,type:'Tarja manual',text:'Área selecionada',rect:{x:rect.x/scale,y:rect.y/scale,w:rect.w/scale,h:rect.h/scale},enabled:true});
        review();
      };
      preview.onpointercancel=()=>{origin=null;draw();};
      holder.append(preview);result.append(holder);
    }
    for (const [index, item] of suggestions.entries()) {
      const row=document.createElement('div');row.className='redact-choice';
      const label=document.createElement('label');label.className='check-row';
      const input=document.createElement('input');input.type='checkbox';input.checked=item.enabled;
      input.onchange=()=>{item.enabled=input.checked;};
      const text=document.createElement('span');text.textContent='Página '+(item.pageIndex+1)+' · '+item.type+' · '+item.text;
      label.append(input,text);row.append(label);putPreview(row,item);result.append(row);
    }
    const apply=document.createElement('button');apply.className='primary';apply.textContent='Gerar PDF com tarjas confirmadas';
    apply.disabled=!suggestions.length;apply.onclick=()=>generate(apply);result.append(apply);
    const note=document.createElement('p');note.className='hint';note.textContent='Uma cópia nova será gerada. Não compartilhe o original nem presuma conformidade automática com a LGPD.';result.append(note);
  }
  async function generate(button) {
    if (busy || !analyzedFile || files[0]!==analyzedFile) {status('Selecione e analise novamente o documento.',true);return;}
    const selected=suggestions.filter(s=>s.enabled);
    if (!selected.length) {status('Selecione pelo menos um trecho para ocultar.',true);return;}
    if (!confirm('Gerar a cópia rasterizada? Todo o texto original será removido do novo PDF e as tarjas selecionadas serão permanentes.')) return;
    busy=true;render();button.disabled=true;
    try {
      const output=await PDFLib.PDFDocument.create();
      for (let i=0;i<pages.length;i++) {
        const page=pages[i], original=page.canvas;
        const source=document.createElement('canvas');source.width=original.width;source.height=original.height;
        const r=source.getContext('2d');r.drawImage(original,0,0);
        r.save();r.fillStyle='#000';
        for (const item of selected.filter(item=>item.pageIndex===i)) {
          const x=Math.max(0,item.rect.x-7), y=Math.max(0,item.rect.y-5);
          r.fillRect(x,y,Math.min(source.width-x,item.rect.w+14),Math.min(source.height-y,item.rect.h+10));
        }
        r.restore();
        const blob=await new Promise((resolve,reject)=>source.toBlob(value=>value?resolve(value):reject(Error('Falha ao converter a página.')),'image/jpeg',.93));
        const bytes=await blob.arrayBuffer();
        const image=await output.embedJpg(bytes);
        const pg=output.addPage([page.width,page.height]);
        pg.drawImage(image,{x:0,y:0,width:page.width,height:page.height});
        status('Gerando página '+(i+1)+' de '+pages.length+'…');
      }
      download(await output.save(),'documento-dados-ocultados.pdf');
      clearState();result.hidden=true;
      showStage('✓ PDF com dados ocultados criado','Seu arquivo está pronto. Toque em Salvar PDF ou Compartilhar, logo abaixo. Revise a cópia final antes de enviá-la.', $('#results'),'↓ Ir para o PDF final');
      $('#processPanel').hidden=true;
      $('#results').scrollIntoView({behavior:'smooth',block:'center'});
      status('PDF final gerado com sucesso. Use os botões Salvar ou Compartilhar.');
    } catch(error) {status('Falha ao gerar PDF: '+error.message,true);}
    finally {busy=false;render();}
  }
  async function analyze() {
    if (busy || files.length!==1 || !/\.pdf$/i.test(files[0].name)) {status('Selecione um único PDF.',true);return;}
    clearState();analyzedFile=files[0];busy=true;render();resetResults();
    $('#processTitle').textContent='Analisando dados pessoais';
    $('#processSpinner').hidden=false;
    let worker, pdf;
    try {
      pdf=await readPdf(analyzedFile);
      if (pdf.numPages>8) throw Error('Este documento possui '+pdf.numPages+' páginas. Divida em blocos de até 8 páginas.');
      for (let n=1;n<=pdf.numPages;n++) {
        status('Examinando dados pessoais na página '+n+' de '+pdf.numPages+'…');
        const page=await pdf.getPage(n),base=page.getViewport({scale:1});
        const scale=Math.min(3,Number($('#redactQuality').value||1800)/Math.max(base.width,base.height));
        const viewport=page.getViewport({scale});
        const canvas=document.createElement('canvas');canvas.width=Math.ceil(viewport.width);canvas.height=Math.ceil(viewport.height);
        await page.render({canvasContext:canvas.getContext('2d'),viewport,background:'rgb(255,255,255)'}).promise;
        const content=await page.getTextContent();
        const selectable=(content.items||[]).filter(item=>item.str&&item.str.trim()&&item.transform).map(item=>{
          const transform=pdfjsLib.Util.transform(viewport.transform,item.transform);
          const height=Math.max(7,Math.hypot(transform[2],transform[3]));
          const width=Math.max(1,Math.abs(item.width||0)*scale);
          return {text:item.str,bbox:{x0:transform[4],y0:transform[5]-height,x1:transform[4]+width,y1:transform[5]}};
        });
        pages.push({canvas,width:base.width,height:base.height});
        suggestions.push(...detect(groupLines(selectable),n-1));
        const missingName=$('#redactName').checked&&!suggestions.some(item=>item.pageIndex===n-1&&/nome/i.test(item.type));
        // Em PDFs híbridos, o nome pode estar na imagem do cabeçalho enquanto
        // o restante da página tem texto pesquisável. Examine só o cabeçalho.
        const headerOnly=selectable.length>0&&!$('#redactForceOcr').checked&&missingName;
        if (!selectable.length||$('#redactForceOcr').checked||headerOnly) {
          if (!window.Tesseract) throw Error('O motor OCR não está disponível.');
          if (!worker) {
            status('Carregando OCR para páginas digitalizadas…');
            worker=await Tesseract.createWorker('por',1,{
              workerPath:'https://appassets.androidplatform.net/vendor/worker.min.js',
              corePath:'https://appassets.androidplatform.net/vendor',
              langPath:'https://appassets.androidplatform.net/vendor/lang'
            });
            await worker.setParameters({tessedit_pageseg_mode:'11',preserve_interword_spaces:'1'});
          }
          status((headerOnly?'Verificando nomes no cabeçalho':'Reconhecendo digitalização')+': página '+n+' de '+pdf.numPages+'…');
          let ocrCanvas=canvas;
          if(headerOnly) {
            ocrCanvas=document.createElement('canvas');
            ocrCanvas.width=canvas.width;
            ocrCanvas.height=Math.max(1,Math.round(canvas.height*.28));
            ocrCanvas.getContext('2d').drawImage(canvas,0,0,ocrCanvas.width,ocrCanvas.height,0,0,ocrCanvas.width,ocrCanvas.height);
          }
          const data=(await worker.recognize(ocrCanvas,{}, {blocks:true,text:true})).data;
          suggestions.push(...detect(groupLines(OcrStudio.wordsFrom(data)),n-1));
          if(headerOnly){ocrCanvas.width=0;ocrCanvas.height=0;}
        }
        status('Página '+n+' de '+pdf.numPages+' analisada.');
      }
      suggestions=suggestions.filter((item,index,array)=>!array.slice(0,index).some(previous=>{
        if(previous.pageIndex!==item.pageIndex||previous.type!==item.type)return false;
        const a=previous.rect,b=item.rect;
        const intersection=Math.max(0,Math.min(a.x+a.w,b.x+b.w)-Math.max(a.x,b.x))*Math.max(0,Math.min(a.y+a.h,b.y+b.h)-Math.max(a.y,b.y));
        return intersection>0.55*Math.min(a.w*a.h,b.w*b.h);
      }));
      suggestions=suggestions.slice(0,300);
      review();
      showStage('✓ Análise concluída','A análise terminou, mas o PDF com tarjas ainda NÃO foi gerado. Revise as sugestões e toque em Gerar PDF com tarjas confirmadas.',result,'Revisar sugestões e gerar PDF ↓');
      status('Análise concluída. Próximo passo: revise as sugestões e gere o PDF final.');
    } catch(error) {status('Falha na análise: '+error.message,true);clearState();}
    finally {if(worker)try{await worker.terminate();}catch(_){}if(pdf)try{await pdf.destroy();}catch(_){}busy=false;render();$('#processPanel').hidden=true;}
  }
  const previousRun=$('#run').onclick;
  $('#run').onclick=()=>tool==='redact'?analyze():previousRun();
})();
