# Revisão de interface — Onda 0.72.0

Equilíbrio de volume: novo controle opcional em Estúdio de som, em formulário rolável e com altura natural. YouTube: botão de repetição ao concluir e estado de carregamento separado de reprodução iniciada; erros de leitura visíveis. Preferência automática por áudio pt-BR no modo com tela desligada, com aviso de idioma e fallback informado. Nenhuma Activity nova.

Escopo: revisão do código das 30 Activities e verificação dos controles nativos em 28 telas principais com fonte 130% no emulador. Não implica que toda página remota ou todo aparelho foi visualmente testado.

- YouTube: botão de áudio nativo com estados de preparação, pausa e retomada; mesma sessão do tocador, fila local preservada. Entrada automática em PiP retirada a pedido do usuário. Testes determinísticos verificam áudio real com tela desligada, identidade dos controles e falha sem retomar música anterior. Não afirmam disponibilidade do provedor.
- Faixas da coletânea: tela nova com lista de posições, ajuda compacta, análise explícita/cancelável, nomes editáveis e remoção de divisões. Arquivo original somente leitura; cache privado, sem análise contínua.
- Google Imagens: texto web em 100%, ajuste manual preservando pesquisa/WebView, painel arredondado e busca/compartilhamento preservados. A página pertence ao provedor e pode mudar.
- WebViews: pausa por página e destruição ao sair; evita pauseTimers global para não suspender outro vídeo PiP visível.
- YouTube: campos e textos compactos, viewport responsivo, tela cheia preservada, pausa e destruição da página ao sair; áudio nativo explícito independente da WebView.
- Rádio: cidade brasileira local por nome/UF, seletor rolável e fechado dentro da área útil; consulta de emissoras com coordenadas até 50 km. Favoritas continuam independentes do filtro.
- Menus: ícone desenhado independentemente da fonte, com toque mínimo de 48 dp; corrige recorte do glifo em seis telas detectado na auditoria 130%.
- Formulários: ações com altura natural e mínimo 48 dp, seletores multilinha; atualizações em ScrollView.
- Música/vídeo/PDF/OCR/menus/conexão/coleções/voz: controles existentes preservados e suíte de regressão mantida.

`ScreenLayoutReviewTest` abre Main, Online, Downloads, Central, Conversor, Arquivos, Imagens, Rádios, YouTube, Favoritos do YouTube, Vídeo, PDF, Aparências, Fones/Bluetooth, Som, Fala, Faixas da coletânea, Backup, Atualizações, Frases, Fila, Playlists, Coleções inteligentes, DJ, Meu espaço, Busca unificada, Letras e Conecta. Inspeciona altura do texto nativo visível e alcança o fim de formulários roláveis. Exclui WebView de terceiros da inspeção de texto nativo; há testes específicos de sua configuração e compartilhamento.

A tela de exclusão tem seus próprios testes de consentimento em Android 10/15. O scanner QR foi revisado no código quanto a superfície, cancelamento e liberação da câmera, e continua dependente de teste físico para avaliar câmera/foco. Não abre câmera nem inicia transmissões no teste de layout.

Os testes geram `screen-layout-review.json`, `radio-city-ui.json`, `image-internet-tests.json`, `youtube-native-audio.json` e `youtube-back-35.json`. A publicação aguarda a suíte completar com sucesso. Não são adicionados listeners de auditoria ou polling ao aplicativo.
