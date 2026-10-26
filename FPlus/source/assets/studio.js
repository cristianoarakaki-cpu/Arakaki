'use strict';
(() => {
  const paths = {
    ocr:'M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16ZM16 16l6 6M7 10h6M10 7v6',
    images:'M3 3h18v18H3zM3 16l6-6 5 5 3-3 4 4M16 7h.01',
    merge:'M4 3h7v7H4zM13 14h7v7h-7zM17 3v7M14 7l3 3 3-3M7 14v7M4 18l3 3 3-3',
    extract:'M5 3h14v18H5zM9 8h6M9 12h6M9 16h3',
    text:'M4 5h16M4 10h16M4 15h10M4 20h7',
    rotate:'M4 11a8 8 0 1 1 2 7M4 4v7h7',
    jpg:'M3 3h18v18H3zM3 16l6-6 5 5 3-3 4 4',
    remove:'M4 7h16M9 7V4h6v3M6 7l1 14h10l1-14M10 11v6M14 11v6',
    split:'M12 3v7M12 10l-7 7M12 10l7 7M3 14v7h7M14 21h7v-7',
    png:'M3 3h18v18H3zM3 16l6-6 5 5 3-3 4 4M16 7h.01',
    stamp:'M5 3h14v18H5zM8 17h8M9 7h6M12 7v6',
    optimize:'M8 3v5H3M16 21v-5h5M3 8l6-6M21 16l-6 6M4 15h5v5M20 9h-5V4',
    docx:'M5 3h10l4 4v14H5zM14 3v5h5M8 12h8M8 16h6'
  };
  document.querySelectorAll('nav button').forEach(button => {
    const key = button.dataset.tool;
    button.innerHTML = '<span class="nav-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="'+paths[key]+'"/></svg></span><span>'+cfg[key][0]+'</span>'+(key==='ocr'?'<em>OCR</em>':'');
  });
  const themeButton = $('#themeToggle');
  function applyTheme(theme) {
    document.documentElement.dataset.theme = theme;
    themeButton.textContent = theme === 'dark' ? '☼' : '☾';
    themeButton.setAttribute('aria-label', theme === 'dark' ? 'Ativar tema claro' : 'Ativar tema escuro');
    document.querySelector('meta[name="theme-color"]').content = theme === 'dark' ? '#10131b' : '#f5f6fa';
    try { localStorage.setItem('folha-theme', theme); } catch (_) {}
  }
  themeButton.onclick = () => applyTheme(document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark');
  applyTheme(document.documentElement.dataset.theme || 'dark');
  function menu(open) {
    document.body.classList.toggle('tools-open', open);
    $('#navBackdrop').hidden = !open;
    $('#openTools').setAttribute('aria-expanded', String(open));
    if (open) $('#closeTools').focus();
    else $('#openTools').focus({preventScroll:true});
  }
  $('#openTools').onclick = () => menu(true);
  $('#closeTools').onclick = $('#navBackdrop').onclick = () => menu(false);
  document.addEventListener('keydown', event => {
    if (event.key === 'Escape' && document.body.classList.contains('tools-open')) menu(false);
  });
  const oldSelect = selectTool;
  selectTool = function(key) {
    if (busy) { menu(false); status('Aguarde a conclusão ou cancele o OCR antes de trocar de ferramenta.'); return; }
    oldSelect(key);
    menu(false);
    $('#ocrReport').hidden = true;
    $('#processPanel').hidden = true;
    $('#acceptHint').textContent = key === 'images' ? 'Selecione imagens JPG ou PNG do seu aparelho' : key === 'ocr' ? 'Selecione um PDF ou imagens do seu aparelho' : 'Selecione arquivos PDF do seu aparelho';
    if (key === 'ocr') {
      $('#pageSettings').hidden = false;
      document.querySelector('label[for="pages"]').textContent = 'Páginas para OCR (vazio = todas)';
      $('#pageSettings .hint').textContent = 'A seleção vale para cada PDF. As demais páginas são preservadas.';
    }
  };
  $('#pageSettings').hidden = false;
  document.querySelector('label[for="pages"]').textContent = 'Páginas para OCR (vazio = todas)';
  $('#pageSettings .hint').textContent = 'A seleção vale para cada PDF. As demais páginas são preservadas.';
  const oldRender = render;
  render = function() {
    oldRender();
    $('#fileCount').textContent = files.length ? '('+files.length+')' : '';
    document.querySelectorAll('.settings input[type="checkbox"]').forEach(input => input.disabled = busy);
    if (busy) $('#processPanel').hidden = false;
  };
  const oldStatus = status;
  status = function(message, error=false) {
    oldStatus(message, error);
    if (busy) $('#progressDetail').textContent = message;
  };
  $('#updates').onclick = () => alert('Folha PDF+ 1.3.0\n\nInterface redesenhada, tema escuro e claro, menu de ferramentas e progresso do OCR.\n\nOCR: Tesseract.js 7.0.0 e núcleo WASM 7.0.0 com reconhecimento LSTM local. Novos controles de resolução, segmentação, contraste e inclinação; relatório de confiança e TXT. O motor foi atualizado da versão 5.1.1 para a 7.0.0. Não é um serviço de IA generativa na nuvem.\n\nPáginas já textuais são preservadas por padrão. Em páginas reconstruídas, links, formulários e assinaturas não são preservados. A aparência vem da renderização da página.\n\nWord exporta somente texto. Excel, PowerPoint e PDFs com senha ainda não são suportados.\n\nEsta versão atualiza o Folha PDF+ 1.2.0, mantendo o Folha PDF original separado.');
})();
