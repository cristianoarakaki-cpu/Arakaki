'use strict';
// Keep the user's selected PDF visible and ready while navigating between tools.
(() => {
  let activePdf = null;
  let switching = false;
  function banner(host, id) {
    const section = document.createElement('div');
    section.id = id;
    section.className = 'active-pdf-banner';
    section.hidden = true;
    const text = document.createElement('div');
    const label = document.createElement('small');label.textContent = 'PDF SELECIONADO';
    const name = document.createElement('strong');name.className = 'active-pdf-name';
    text.append(label,name);
    const clear = document.createElement('button');clear.className = 'secondary';clear.textContent = 'Trocar / limpar';
    clear.onclick = () => {
      activePdf = null;files = [];render();refresh();status('Documento removido da seleção. Escolha outro PDF.');
    };
    section.append(text,clear);host.prepend(section);
    return section;
  }
  const toolsBanner = banner($('#toolsView'), 'activePdfTools');
  const hubBanner = banner($('#hubView'), 'activePdfHub');
  function refresh() {
    for (const section of [toolsBanner,hubBanner]) {
      section.hidden = !activePdf;
      section.querySelector('.active-pdf-name').textContent = activePdf ? activePdf.name : '';
    }
  }
  const previousRender = render;
  render = function () {
    if (files.length && /\.pdf$/i.test(files[0].name)) activePdf = files[0];
    else if (!files.length && !switching) activePdf = null;
    previousRender();refresh();
  };
  const previousSelect = selectTool;
  selectTool = function (key) {
    switching = true;
    try { previousSelect(key); } finally { switching = false; }
    if (busy) return;
    if (activePdf && key !== 'images') {
      const additional = files.filter(f => f !== activePdf);
      files = [activePdf, ...additional];
      render();
      status('PDF selecionado: ' + activePdf.name + '. Escolha os ajustes e execute a ferramenta.');
    }
    refresh();
  };
  const priorViewerUse = $('#viewerUse').onclick;
  $('#viewerUse').textContent = 'Escolher ferramenta';
  $('#viewerUse').onclick = () => {
    if (busy) return;
    priorViewerUse();
    if (files.length) activePdf = files[0];
    FolhaWorkspace.hub();refresh();
  };
  // Choosing a document from the upload field also establishes the active PDF.
  refresh();
})();
