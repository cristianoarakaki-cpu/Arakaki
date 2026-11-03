# Revisão de interface — Onda 0.69.0

Escopo: revisão do código das 29 Activities e verificação dos controles nativos em 27 telas principais com fonte 130% no emulador. Não implica que toda página remota ou todo aparelho foi visualmente testado.

- Google Imagens: texto web em 100%, ajuste manual preservando pesquisa/WebView, painel arredondado e busca/compartilhamento preservados. A página pertence ao provedor e pode mudar.
- WebViews: pausa por página e destruição ao sair; evita pauseTimers global para não suspender outro vídeo PiP visível.
- YouTube: campos e textos compactos, viewport responsivo, PiP de vídeo em tela cheia, retorno preservando WebView; pausar/liberar ao sair sem PiP.
- Rádio: cidade brasileira local por nome/UF, seletor rolável e fechado dentro da área útil; consulta de emissoras com coordenadas até 50 km. Favoritas continuam independentes do filtro.
- Menus: ícone desenhado independentemente da fonte, com toque mínimo de 48 dp; corrige recorte do glifo em seis telas detectado na auditoria 130%.
- Formulários: ações com altura natural e mínimo 48 dp, seletores multilinha; atualizações em ScrollView.
- Música/vídeo/PDF/OCR/menus/conexão/coleções/voz: controles existentes preservados e suíte de regressão mantida.

`ScreenLayoutReviewTest` abre Main, Online, Downloads, Central, Conversor, Arquivos, Imagens, Rádios, YouTube, Favoritos do YouTube, Vídeo, PDF, Aparências, Fones/Bluetooth, Som, Fala, Backup, Atualizações, Frases, Fila, Playlists, Coleções inteligentes, DJ, Meu espaço, Busca unificada, Letras e Conecta. Inspeciona altura do texto nativo visível e alcança o fim de formulários roláveis. Exclui WebView de terceiros da inspeção de texto nativo; há testes específicos de sua configuração e compartilhamento.

A tela de exclusão tem seus próprios testes de consentimento em Android 10/15. O scanner QR foi revisado no código quanto a superfície, cancelamento e liberação da câmera, e continua dependente de teste físico para avaliar câmera/foco. Não abre câmera nem inicia transmissões no teste de layout.

Os testes geram `screen-layout-review.json`, `radio-city-ui.json`, `image-internet-tests.json`, `youtube-fullscreen-pip.json` e `youtube-back-35.json`. A publicação aguarda a suíte completar com sucesso. Não são adicionados listeners de auditoria ou polling ao aplicativo.
