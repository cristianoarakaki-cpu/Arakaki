## Onda Música 0.50.0 — Proteção de anúncios no YouTube

YouTube no Onda → Menu → Proteção de anúncios. Proteção local ativada por padrão, com opção de desligar e recarregar se atrapalhar a página. Conta solicitações publicitárias bloqueadas na sessão, não quantidade de anúncios. A preferência fica salva neste celular.

Bloqueia subrecursos de seis domínios exclusivos de publicidade e seus subdomínios, respeitando limites de nome; não bloqueia a página principal, youtube.com, youtubei.googleapis.com, googlevideo.com ou ytimg.com. Uma folha de estilo local oculta cartões patrocinados móveis conhecidos. Não altera respostas do player, não pula vídeos, não automatiza botões, não burla verificações e não garante remover anúncios inseridos no próprio fluxo do vídeo. O YouTube pode alterar o site ou restringir reprodução com bloqueadores.

Implementação própria: não incorpora nem é afiliada ao AdGuard. Sem VPN, certificado instalado, DNS global, servidor intermediário, API paga, lista externa, varredura contínua, timer ou observador de DOM. Regras simples por solicitação e estilo uma vez por carregamento de página. Só na aba YouTube; downloads, navegador externo e demais aplicativos não são filtrados. Mantém busca por voz, encerramento do navegador ao sair e funções anteriores. Economia de bateria não foi medida em aparelho físico. Instale sobre a versão atual, sem desinstalar.

## Onda Música 0.49.0 — Busca por voz no YouTube

Downloads → YouTube: novo campo de busca e microfone do Onda. Toque no microfone, diga o nome da música ou artista e veja os resultados do site oficial dentro da própria aba. Pode digitar ou corrigir o texto e buscar pelo botão ou teclado. Não inicia reprodução ou download automaticamente.

Usa o diálogo de reconhecimento de fala do Android em português do Brasil, somente ao tocar. Sem API paga ou nova permissão de gravação para o Onda; disponibilidade e eventual uso da internet dependem do serviço de voz instalado no aparelho. Se não existir serviço compatível, permite digitar ou usar o microfone do teclado. Cancelar não faz pesquisa. Termos limitados a 160 caracteres, com acentos e símbolos codificados no endereço HTTPS oficial.

A pesquisa é mantida ao recriar a tela; o resultado da voz também é aplicado se o navegador tiver sido encerrado durante o diálogo. Preserva encerramento do WebView ao sair, bloqueio de acesso a arquivos e reprodução por gesto do usuário. Sem escuta contínua, serviço novo em segundo plano ou medição de bateria física. Mantém Central organizada, destino automático e funções anteriores. Instale sobre a versão atual, sem desinstalar.

## Onda Música 0.48.0 — Central de downloads organizada

Central de downloads com busca local por nome, formato ou origem, ignorando acentos e maiúsculas. Filtros de status combinados com áudio/vídeo e ordenação por data, nome ou bytes transferidos, acessíveis no menu sem encher a tela. Busca e filtros são preservados ao recriar a tela. Até 200 registros já existentes; não varre arquivos do celular.

Compartilhar arquivo nos registros concluídos usa o seletor do Android, com acesso temporário somente de leitura ao arquivo escolhido. Verifica acesso antes de compartilhar; arquivos removidos ou com autorização revogada mostram orientação. Não envia links temporários de download nem compartilha pastas inteiras.

A Central escuta mudanças do histórico enquanto visível. A atualização periódica só roda durante uma operação ativa e para ao sair da tela. Sem nova permissão, rede de busca, serviço permanente ou medição de bateria física. Mantém destino automático e demais recursos. Instale sobre a versão atual, sem desinstalar.

## Onda Música 0.47.0 — Destino automático e seleção de áudio

Downloads → Destino → Salvar automaticamente nas pastas do Onda. Escolher o formato inicia a gravação no destino padrão, sem a confirmação adicional de salvar. Para playlists, marcar os vídeos, tocar Baixar e escolher o formato usa Onda/Áudios ou Onda/Vídeos automaticamente. A primeira autorização de pasta pelo Android agora é guardada também quando a seleção foi feita pelo fluxo da playlist; antes ela valia para aquela operação sem virar o padrão do Onda. Dados e permissões válidos sobrevivem à atualização.

Se não houver configuração, o app tenta recuperar somente a autorização ligada ao último download concluído. Não escolhe uma pasta aleatória entre permissões de outros recursos. Sem essa referência, pede uma pasta uma vez; recusas ou acesso revogado podem exigir nova autorização. Selecionar uma pasta já chamada Onda reutiliza a própria pasta, evitando Onda/Onda. Não move, apaga nem reorganiza arquivos anteriores. Autorizações de arquivo avulso não concedem automaticamente acesso à pasta inteira.

O botão Destino oferece Outro local no próximo download, Perguntar o local a cada download e Autorizar ou mudar a pasta do Onda. O desvio de uma operação não desativa o padrão automático. Uma escolha manual permanente anterior é respeitada; use a opção de salvar automaticamente para ativar. Se o processo perder o formato pendente durante a autorização, guarda a pasta e solicita escolher o formato novamente, sem pedir a pasta outra vez.

Áudio do YouTube: se não houver M4A separado, mas houver um MP4 progressivo com som, o app oferece MP3, M4A ou AAC extraídos desse vídeo. Escolhe a menor resolução conhecida para reduzir transferência; a saída continua no formato solicitado. Não trata vídeo sem som como fonte de áudio e não troca MP3 por MP4 silenciosamente. Ainda depende de AAC compatível na fonte e dos limites de tamanho/conversão. Quando não há opção, o erro informa o formato solicitado e as opções disponíveis. Se a playlist falha sem concluir arquivos, a primeira causa aparece também no resumo. A subpasta de uma playlist só é criada após encontrar o primeiro formato utilizável.

Cabeçalho Downloads ajustado para o botão Central não quebrar sua palavra. Introdução reduzida e controle de destino visível. Nenhum serviço novo, análise contínua, permissão ampla de armazenamento ou API paga. Testes com pasta real, primeira autorização lembrada, segundo download sem seletor, restauração de autorização anterior, destino alternativo único e persistência após falha. Mantém OCR, YouTube, aparências e funções anteriores. Não garante desbloqueio de provedores nem foi medido consumo em aparelho físico.

Instale sobre a versão atual, sem desinstalar.

## Onda Música 0.46.0 — YouTube no Onda, páginas públicas e AAC

Downloads agora tem abas Links e YouTube. A aba YouTube abre o site móvel oficial dentro do Onda, com pesquisa e navegação do próprio site. Escolha um vídeo ou playlist e toque Ver formatos para baixar: o endereço passa para o analisador do Onda. Também há atalho YouTube no Onda em Explorar. A página usa Android System WebView e pode exigir atualização desse componente. Navegação restrita aos domínios oficiais do YouTube; login externo pode ser feito no navegador. Reprodução depende de toque, sem autoplay forçado.

A página WebView é pausada e destruída ao sair da tela; voltar recarrega o último endereço, sem garantir a posição do vídeo. Sem navegador, vídeos ou scripts ocultos em segundo plano, serviço adicional de varredura ou nova permissão. O site oficial usa rede e processamento enquanto estiver aberto. Downloads continuam sendo solicitados explicitamente e usam a Central e o serviço já existente.

O analisador também aceita páginas HTTPS públicas que declarem arquivos MP4, MP3, M4A ou AAC em tags video/audio/source, metadados Open Graph ou dados estruturados VideoObject/AudioObject. Não executa scripts da página. Lê até 1 MB de HTML, considera até 12 declarações, confere até 6 candidatos (prefixo de até 64 KB) e oferece até 3 fontes acessíveis. Cada fonte tem opções identificadas; extração de áudio depende de faixa AAC compatível. Mantém validação do arquivo real antes de salvar, limite de tamanho, cancelamento e reconexões. Usa o referer da página, sem cookies de login, servidores de download terceirizados ou solução de desafios.

Novo formato de áudio AAC (.aac, ADTS): extrai pacotes AAC-LC mono/estéreo sem recodificar. MP3 a 192 kbps e M4A continuam disponíveis quando compatíveis, inclusive em playlists; AAC também pode ser escolhido na fila e salvo em Onda/Áudios. M4A/AAC evitam a conversão MP3, mas não melhoram a qualidade da fonte. Tipos AAC incompatíveis são recusados com orientação para usar M4A.

A atualização não permite baixar de qualquer site. Conteúdo protegido por DRM, players dinâmicos sem arquivo declarado, streams HLS/DASH, lives e páginas que exigem login/verificação não são suportados. A disponibilidade do YouTube e TikTok continua dependente do provedor, da região e da rede; verificação anti-bot pode impedir formatos mesmo quando o vídeo toca no site oficial. A versão do NewPipe Extractor continua v0.26.5, última release pública consultada nesta atualização. Sem API paga. Testes incluem preservação de cada pacote AAC, arquivo AAC reconhecido pelo Android, serviço real de download, parser com fontes falsas e limites, navegação e encerramento do WebView e página pública real de teste.

Instale sobre a versão existente, sem desinstalar. Mantém OCR, aparências, pastas, favoritos e demais recursos. Não há medição de consumo em aparelho físico.

## Onda Música 0.45.0 — OCR local e conferência de boletos

PDF → Menu → Texto da página: usa o texto original primeiro; se estiver vazio, reconhece a imagem por OCR. OCR da página permite ler também partes digitalizadas de páginas que já têm texto. Modelo rápido em português incluído no APK, sem baixar modelo no celular nem enviar documentos. Texto reconhecido é identificado como OCR e pode ser selecionado ou copiado; não modifica o PDF nem cria uma camada de texto sobre a página.

Reconhecer boleto combina linhas do texto, barras ITF e OCR quando não encontrou uma linha válida no texto original. Valida campos e dígito geral, mostra a origem e informa quando linha e barras coincidem ou trazem códigos diferentes. Não troca letras por números nem corrige dígitos por tentativa. A partir desta versão, o usuário confere o resultado e toca Copiar código antes de colocá-lo na área de transferência. Dígitos consistentes não garantem autenticidade: confirme beneficiário e valor no banco.

OCR sob comando, uma página por vez, resolução limitada a 2,5 milhões de pixels, motor de uma única thread, ajuste de contraste e tentativas de rotação limitadas. Botão Cancelar leitura; sair da tela solicita interrupção. Mantém até duas páginas reconhecidas apenas na memória enquanto o documento está aberto. Sem análise contínua, varredura de arquivos, serviço de OCR ou nova permissão. PDFs até 16 MB para texto/OCR; leitura visual continua até 64 MB e 5.000 páginas. Respeita restrições de cópia. Depende da nitidez, tamanho das letras e organização do documento; não garante ausência de erros, reconhecimento de manuscritos ou correção de perspectiva.

Tesseract4Android 4.9.0 standard e modelo por.traineddata do tessdata_fast, com revisão fixada e integridade conferida na compilação. Avisos de Tesseract, Leptonica, libpng e IJG em Downloads → Licença e código-fonte. Para compilar, Python 3 e internet são usados na tarefa prepareOcrModel; o modelo fica incluído no APK, e o OCR não usa a internet em execução. Testes cobrem PDF de imagem real, rotação, cancelamento, texto nativo, permissão de cópia, linha com dígito errado e divergências entre fontes. Não há medição de economia de bateria em aparelho físico.

Instale sobre a versão atual, sem desinstalar. Mantém aparências, pastas, favoritas e demais recursos. Não altera a disponibilidade de downloads do TikTok.

## Onda Música 0.44.0 — Aparências para escolher

Menu → Aparências: lista de cinco interfaces escuras com prévia — Onda Original, Nebulosa, Circuito, Cyber Solar e Grafite. Muda cores, gradientes e cantos dos cartões e controles; mantém organização, funcionalidades e tamanho de fonte do Android. Pode voltar ao Onda Original a qualquer momento. A escolha fica salva somente neste aparelho, permitindo que cada pessoa use sua própria aparência.

A aplicação repinta as telas existentes, sem recriar atividades, reiniciar o tocador ou alterar fila/posição. Os atalhos ficam nos menus de Músicas, Vídeos e Explorar. Prévias estáticas desenhadas no próprio app; não há animação contínua, downloads de temas, nova permissão ou API paga. Leitura de PDF e imagem de vídeo preservam as cores do conteúdo. A preferência de aparência não integra o backup de listas atual.

Mantém conversor local AAC, arquivos do Onda, pastas, favoritas e os demais recursos. A indisponibilidade de downloads do TikTok continua pendente e não é resolvida por esta mudança visual.

## Onda Música 0.43.0 — Conversor local, arquivos e controles de reprodução

Menu → Conversor local: selecione um vídeo ou áudio com faixa AAC, comum em MP4/M4A/AAC. Gere MP3 a 192 kbps ou extraia M4A sem recodificar a faixa AAC. Confere compatibilidade antes de oferecer os botões; esta primeira versão não converte todos os codecs de áudio. Processamento no aparelho, sem API paga. Até 512 MB e 30 minutos por operação, com notificação, cancelamento e resultado na Central. Originais preservados, arquivos temporários removidos e saída incompleta excluída quando o provedor permite. Pode salvar em Onda/Áudios ou escolher outro local. MP3 não melhora a qualidade da fonte.

Menu → Arquivos do Onda: navegue pela pasta configurada e subpastas, busque nomes na pasta atual, ordene por nome/data/tamanho e abra áudio, vídeo e PDF no Onda. Até 1.000 itens por pasta e 30 níveis de navegação. Atalho Converter áudio nos arquivos compatíveis. Não move, renomeia nem exclui arquivos. Se o acesso expirar, configure a pasta novamente pela Central. Provedores de nuvem podem depender da internet.

Menu → Controles de áudio: velocidade de 0,5× a 2× com tom preservado, voltar 10 segundos e avançar 30 segundos. A velocidade é guardada para próximas reproduções de áudio; mudar o ajuste não inicia a reprodução. Vídeos usam velocidade própria no Modo Aprender e ganham os comandos Voltar 10 segundos e Avançar 30 segundos no menu, preservando pausa/reprodução e desativando A–B se o salto sair do trecho. Precisão da busca depende do arquivo.

Mantém pastas, cópia de favoritas, histórico e funções anteriores. O bloqueio externo do TikTok continua pendente; esta atualização não promete resolver HTTP 403.

## Onda Música 0.42.0 — Central de downloads, pastas e biblioteca organizada

Biblioteca → menu → Organizar biblioteca → Copiar favoritas para a pasta do Onda. Após confirmar, copia as favoritas locais disponíveis para Onda/Áudios, preservando formato, originais e marcações. A cópia usa serviço em primeiro plano com notificação, progresso, cancelamento e registro na Central; não converte nem move arquivos. Até 1.000 referências por operação e 512 MB por arquivo; evita referências equivalentes quando reconhecidas, mas repetir a operação pode criar novas cópias. A pasta deve estar configurada e ativa. Arquivos indisponíveis são relatados e saídas incompletas são removidas quando o provedor permite.

Central de downloads pelo botão Central em Downloads: histórico local por arquivo, fila da playlist, estado, trecho transferido, conclusão e falha. Filtros Todos, Em andamento, Concluídos e Falhas/interrupções. Abrir arquivos concluídos e Tentar novamente, que preenche o link original para reanalisar os formatos e escolher novo destino. Não guarda URLs temporários dos servidores de mídia. Até 200 registros; limpar histórico não apaga os arquivos. Registros começam nesta versão. Não retoma bytes após encerrar a operação; a recuperação de conexão dentro do download continua disponível.

Central → menu → Escolher pasta do Onda: escolha a pasta base pelo Android uma vez. Cria Onda/Áudios e Onda/Vídeos, com acesso persistente quando o provedor permite. Downloads e conversões do download podem usar essas pastas; playlists criam sua própria subpasta dentro do tipo correspondente. Pode escolher Outro local a cada operação e alternar para pedir destino sempre. Cria arquivos novos, sem substituir existentes; o provedor resolve nomes repetidos. Mudança de pasta não move arquivos anteriores. Acesso revogado, cartão removido e pastas na nuvem podem exigir nova seleção/conexão. Não acrescenta um conversor independente de arquivos nesta versão.

Menu da biblioteca → Organizar biblioteca: título, artista, álbum, duração crescente/decrescente e mais recentes. Ordenação por artista/álbum inclui cabeçalhos de grupos. Filtro Downloads do Onda mostra os áudios registrados pelo app, inclusive abertos/recebidos; mantém busca e favoritas. Duração/data ausentes ficam após valores conhecidos. Preferências locais, sem alterar nomes, metadados ou arquivos. Não inclui busca/exclusão de duplicatas nem nova extração de capas.

A pendência do TikTok permanece: o teste anterior reconheceu o vídeo, mas os arquivos foram recusados com HTTP 403. Esta atualização não promete resolver o bloqueio externo. YouTube e links diretos mantêm os caminhos existentes.

## Onda Música 0.41.1 — Correção da consulta ao TikTok

Consulta vídeos do TikTok com a página para computador, pois a página móvel pode retornar somente a tela de compartilhamento sem arquivo. Mantém a mesma identificação de navegador ao baixar o vídeo. YouTube e arquivos diretos mantêm as consultas anteriores. Confere um pequeno trecho do arquivo antes de oferecer os formatos e tenta até quatro endereços de vídeo publicados pela própria página quando um deles é recusado. Não usa login, solução de verificações nem serviço externo. A disponibilidade continua dependendo do site.

## Onda Música 0.41.0 — Mais tipos de link em Downloads

Aceita YouTube (vídeo, Shorts, youtu.be, playlists e Mixes), vídeos públicos do TikTok (vt.tiktok.com, vm.tiktok.com, tiktok.com/t e links completos /@autor/video/id) e arquivos HTTPS diretos terminados em .mp4, .mp3 ou .m4a, inclusive com parâmetros de assinatura. Também aceita o texto de compartilhamento com exatamente um link. Sites não listados, fotos/perfis/lives do TikTok, HTTP sem TLS, listas HLS e links de redes locais/reservadas não são aceitos.

TikTok é consultado diretamente pela página pública, com redirecionamentos limitados. Não usa login/cookies de conta, APIs pagas, servidores de download externos, solução de verificações nem remoção de marcas. A disponibilidade depende do site e da região. Se a página expõe o arquivo do vídeo, oferece MP4 original e extração do áudio completo em MP3/M4A (requer AAC compatível). Bloqueios de verificação, conteúdo privado, removido ou mudanças no site podem impedir a análise; a tela informa o serviço e o motivo disponível. Isso não garante que todos os vídeos do TikTok possam ser baixados.

Arquivos diretos: análise limitada a 64 KB, preservação do original, MP3 pronto sem nova conversão e validação real das faixas pelo Android antes de salvar. Arquivos MP4/M4A com AAC podem oferecer extração para MP3. Arquivos/páginas inválidos são recusados. Mantidos cancelamento, limite de 512 MB, prazos e reconexão existentes. YouTube usa os caminhos anteriores de extração, conversão e playlists.

## Onda Música 0.40.0 — Onda Conecta

Menu → Onda Conecta compartilha áudios, vídeos e PDFs na mesma rede Wi-Fi privada (IPv4). Ambos precisam desta versão ou de uma versão compatível. Quem recebe escolhe uma pasta local no seletor Android e mostra o QR. Quem envia seleciona até 10 arquivos e lê o QR pela câmera, por imagem ou cola o código de conexão. A lista precisa ser aceita no receptor antes de criar arquivos. O QR contém endereço local, chave aleatória e impressão do certificado TLS; não compartilhe fora dos aparelhos envolvidos. Não requer conta nem servidor de transferência, e o Wi-Fi não precisa ter acesso à internet. Redes de convidados, VPNs e isolamento de clientes podem impedir a conexão.

Conexão criptografada com certificado conferido pelo QR e SHA-256 por arquivo. Limites: 10 arquivos, 512 MB por arquivo, 1 GB por envio. O provedor precisa informar o tamanho dos arquivos. Espera inicial de 3 minutos; aprovação em até 1 minuto. QR de uso único; gere outro após cada tentativa. Recebidos ficam na pasta escolhida e no Meu espaço quando houver capacidade; áudios também são registrados na biblioteca de downloads. Onda não substitui arquivos existentes intencionalmente; o provedor escolhe o nome de arquivos repetidos.

Mantenha a tela Conecta aberta nos dois celulares. O app mantém a tela acesa durante a sessão; sair interrompe o envio. Não há serviço de transferência permanente, detecção automática de aparelhos nem varredura da rede. Recusa não cria arquivos. Falha/cancelamento preserva os arquivos confirmados e tenta remover o arquivo incompleto; provedores podem impedir sua exclusão. Nova tentativa começa de novo, sem retomada de bytes. A câmera só é aberta no leitor de QR e as imagens não são salvas. Não inclui sincronização de reprodução nesta versão.

## Onda Música 0.39.0 — Busca unificada

Menu → Busca unificada reúne músicas por nome/artista/álbum, vídeos da biblioteca, PDFs adicionados ou abertos, coleções e texto das anotações. Filtros: tipo, favoritas de áudio e Continuar. Toque numa anotação para ler e abrir o minuto/página marcado. Até 200 resultados visíveis; refine a consulta. Não pesquisa o texto completo dos PDFs.

Use Acesso e atualizar para permitir músicas/vídeos ou reler a biblioteca; Adicionar arquivo abre o seletor do Android, inclusive para PDFs e documentos fora da biblioteca. Arquivos removidos ou sem permissão podem precisar ser selecionados novamente. Até 10 mil áudios e 10 mil vídeos na leitura, além das referências limitadas do Meu espaço. Metadados em memória, processamento fora da interface, espera curta ao digitar e linhas recicladas; nenhuma varredura contínua, nova API ou serviço pago.

Voz na biblioteca e na busca: “abra minha coleção Estudo”, “continue o último vídeo”, “continue o último PDF”, “continue a última música”, “continue o último conteúdo”, “busque no Onda Chitãozinho e Xororó”. Coleções com nomes iguais exigem escolha. “Abra o PDF Fatura” filtra os resultados pelo nome para você escolher. Atalhos personalizados existentes têm prioridade na biblioteca. Pedidos de busca explícitos não executam comandos embutidos no título. Os comandos anteriores de música permanecem disponíveis. A busca é local/offline; o reconhecimento de voz depende do serviço configurado no Android. Retomada usa os pontos salvos; vídeo com áudio ativo em segundo plano retorna ao ponto atual do serviço.

# Onda Música 0.38.0 — Aulas e podcasts

Menu → Aulas e podcasts, também disponível no Estúdio de som: equilíbrio de fala com dinâmica ligada entre canais, proteção de picos e presença suave; opção independente de pular silêncios pelo Media3. Ambas desligadas inicialmente. Processamento local de PCM16 durante o fluxo de áudio, sem microfone, varredura de arquivos, API paga ou serviço de análise separado. O modo desligado preserva as amostras originais; a troca de efeito usa uma transição de 20 ms. Não modifica os arquivos. Aplicável ao player de músicas e áudio online; o motor de vídeo LibVLC permanece separado. Formatos ou saídas que usam passagem direta/offload podem não disponibilizar PCM compatível. A tela permite consultar a aplicação. Reduzir silêncios pode encurtar pausas intencionais, por isso é indicado para fala. Posições continuam no tempo do arquivo original. A equalização permanece independente; restaurar o som original da saída ativa desliga também os dois recursos de fala. Não há promessa de loudness padronizada, isolamento de voz, remoção de ruído ou compatibilidade universal.

## Histórico — Onda Música 0.37.1 — Meu espaço: continuar, coleções multimídia e anotações

Faixas concluídas naturalmente na fila voltam ao início no histórico; pular para outra faixa preserva o ponto de saída.

Menu → Meu espaço: pontos locais de áudio, vídeo e PDF, coleções mistas e notas ligadas a um minuto ou página. Toque para retomar; segure para organizar ou anotar. Crie uma coleção e adicione arquivos pelo seletor Android ou por Continuar. Referências locais, sem duplicar/excluir mídia, sem análise contínua e sem API paga. Até 200 referências, 30 coleções, 50 itens por coleção e 10 notas de 1.000 caracteres por arquivo, dentro de 1 MB de dados. Referências com notas ou em coleções não são descartadas para liberar espaço. Os dados ficam neste celular e não integram o backup de listas anterior. Arquivos removidos ou sem acesso precisam ser selecionados novamente. A retomada usa a busca disponível no arquivo e no decoder. Áudio salva pontos nas ações e em intervalos de 15 segundos durante a reprodução; PDF, após renderizar a página. O histórico anterior começa a ser registrado após esta atualização; não reconstrói sessões antigas.

## Histórico — Onda Música 0.36.0 — Abrir com e áudio dos vídeos em segundo plano

Esta versão registra o Onda em “Abrir com” para áudio, vídeo e PDF. Ao receber áudio externo, lê os metadados e mantém a identidade de favoritos. Vídeos podem continuar como áudio em um serviço com notificação e controles, inclusive com tela bloqueada; a opção Pausar ao sair continua disponível no menu de vídeos. A troca entre os motores pode causar uma breve pausa. O modo não continua automaticamente após reiniciar o processo; respeita perda de foco e desconexão do fone. Para continuar vendo a imagem, use Janela flutuante. Gerenciadores precisam fornecer o tipo correto e acesso ao arquivo; arquivos removidos, sem permissão ou protegidos permanecem indisponíveis.

Botão de favoritas do cartão Tocando agora redesenhado: coração vetorial em vez de caractere de fonte, área de toque de 48 × 48 dp, estados de contorno/preenchido e descrição Adicionar/Remover dos favoritos. Ícone independente do tamanho de fonte do Android, sem downloads de imagem ou animação contínua. Título e artista ficam separados do botão; a linha de metadados cresce conforme o texto, mantendo reticências nos nomes longos. Barra de posição com mais espaço e tempo em fonte um pouco maior. Sem música selecionada, o cartão volta ao estado inicial e o coração fica desabilitado. Preserva favoritas e controles existentes.

Tela cheia de vídeo: controles sobrepostos à imagem, sem reservar faixa inferior. Ocultação após 3,5 segundos de reprodução; toque na imagem para mostrar/ocultar. Pausar mantém os controles visíveis. Arrastar a posição reinicia o prazo de ocultação. Com exploração por toque de acessibilidade ativa, não oculta automaticamente. Voltar sai da tela cheia. A imagem ocupa a mesma área com controles visíveis ou ocultos; respeita a proporção do vídeo. O timer de progresso da interface para enquanto os controles estão ocultos e na janela flutuante, sem parar a reprodução.

PDF → Menu → Texto da página: extrai somente a página atual e abre texto selecionável. Toque e segure para selecionar um trecho e usar Copiar, ou use Copiar texto para o conteúdo exibido. Operação local em segundo plano usando PdfBox-Android 2.0.27.0 (Apache License 2.0), com avisos e licença em Downloads → Licença e código-fonte. Até 16 MB para extração e até 100.000 caracteres por página; a leitura visual continua até 64 MB. Respeita restrições de cópia informadas pelo PDF. Não faz OCR: páginas de imagem podem não ter texto e exibem aviso. Fontes, ordem e espaços dependem da codificação do documento; não é uma seleção sobreposta à imagem renderizada. Não modifica nem envia o PDF para servidor.

PDF → Menu → Reconhecer boleto: procura linha digitável no texto da página e código de barras Interleaved 2 of 5 na imagem renderizada, inclusive com rotação. Banco: 47 dígitos e validação dos três campos e do DV geral. Arrecadação: 48 dígitos com módulo 10 ou 11 conforme referência, campos e DV geral. Códigos de barras de 44 dígitos são convertidos à linha digitável correspondente; formatos ambíguos são recusados. Um resultado consistente é copiado automaticamente, sem pontuação, e mostrado na tela. Se houver mais de um código, o usuário escolhe qual copiar. A consistência dos dígitos não autentica o emissor nem os dados do boleto. Não executa pagamento. Busca somente na página atual, sob comando do usuário, sem monitorar documentos ou enviar dados a servidor. Não faz OCR geral, não lê QR Pix e depende de linha ou barras legíveis. Limite de 10 códigos por página. ZXing 3.5.3 (Apache 2.0); licença e avisos incluídos em Downloads → Licença e código-fonte.


## Modo Aprender e leitor de PDF

Vídeos → Menu → Modo Aprender: velocidade 0,5×, 0,75×, 1×, 1,25×, 1,5× e 2×. Abre pausado; selecione e toque em Reproduzir. Mantida na sessão do mesmo vídeo, inclusive retomada e fallback; outro vídeo volta a 1×. O resultado depende do decoder. Em Repetir trecho A–B, selecione Sem limite, 3, 5 ou 10 vezes. A contagem inclui a primeira passagem completa pelo fim B; tentativas de busca não contam. Ao concluir a quantidade, pausa e desativa a repetição, sem avançar para outro vídeo. Mantém pausa, cancelamento e busca manual fora do intervalo. Configuração e contagem somente na sessão.

Momentos salvos → selecione um momento → Anotação: até 1.000 caracteres, com parágrafos, editável ou apagável esvaziando o texto. Preserva marcações anteriores, nome, ID e posição; renomear não apaga a nota. Salvas no celular, associadas ao mesmo arquivo da biblioteca/seletor reconhecido, sem alterar o vídeo e fora do backup de listas. Os limites continuam em 30 momentos por vídeo e 100 vídeos.

Menu da biblioteca, Explorar ou vídeos → Leitor de PDF. Abrir usa o seletor de documentos Android; também aceita Abrir com Onda para arquivos content:// application/pdf com acesso concedido. Leitor nativo com página anterior/próxima, Ir à página, zoom de 50% a 200% e Continuar último PDF na última página renderizada, inclusive após reiniciar o app quando o provedor permite acesso persistente. O zoom pode ampliar a imagem dentro do limite de resolução de renderização. Não altera o arquivo. Não é editor, OCR ou leitor de PDFs com senha. Até 64 MB e 5.000 páginas; uma página por vez, renderização fora da interface, imagem limitada a 2,5 milhões de pixels. Cópia privada temporária para leitura; liberada ao fechar, e cópias interrompidas são limpas na próxima abertura. Sem serviço próprio, API paga, varredura de arquivos ou permissão adicional; documentos de nuvem dependem do provedor escolhido no Android. A leitura não solicita foco de áudio, permitindo manter música de fundo.

## Menus que cabem na tela

Os menus da biblioteca, vídeos, Explorar e DJ agora abrem em um painel central com lista rolável e botão Fechar fixo. Altura e largura são limitadas pela área útil informada pelo Android, respeitando as barras do sistema. Opções longas podem ocupar mais de uma linha, sem diminuir a fonte escolhida no celular. Mantém todas as opções, descrições de acessibilidade e ações existentes.

## Perfis de som por saída

Menu → Estúdio de som → Perfis automáticos por saída. Um perfil para alto-falante, fone com fio, Bluetooth, USB, HDMI e outras saídas, com nome editável de até 40 caracteres. Todos os dispositivos Bluetooth compartilham um perfil. Escolha qual perfil editar; editar uma saída inativa não muda o perfil da saída atual. Restaurar som original afeta somente o perfil em edição quando o modo automático está ligado. Desligar o modo automático recupera os ajustes gerais anteriores.

A opção começa desligada. Ao ativar, copia os ajustes gerais para a saída atual somente se ela já estiver identificada e ainda não tiver perfil; demais saídas começam com efeitos desligados. A identificação vem do AudioTrack real do ExoPlayer, por eventos de roteamento, sem escolher a saída, varrer Bluetooth ou manter análise contínua. Antes de o Android identificar a saída, mantém som original. O último dispositivo identificado não é persistido entre processos. Não inicia reprodução nem altera volume do sistema; o Android continua responsável pelo pareamento e roteamento. Efeitos e compensação de ganho dependem do aparelho. Vale para músicas e áudio online, não para vídeos LibVLC. Sem nova permissão, API paga ou serviço de rede. Os perfis ficam neste celular e não integram o backup de listas. Trocas físicas de fones e Bluetooth exigem validação no aparelho real.

## Repetir trecho A–B

Vídeos → Menu → Repetir trecho A–B: informe início e fim em segundos, m:ss ou h:mm:ss. Intervalo mínimo de 2 segundos. Ativar prepara o trecho com o player pausado; Reproduzir inicia a repetição. O intervalo aparece junto ao tempo do vídeo. Pausar mantém a configuração; Desativar, selecionar outro vídeo, reproduzir um momento salvo ou buscar fora do intervalo cancela a repetição. Vale somente para a sessão atual, sem persistência após recriar/fechar o player. Usa os eventos já emitidos pelo LibVLC, com tentativas limitadas para arquivos que não respondem à busca; não promete repetição sem intervalos nem precisão de quadros.

Menu de vídeos → Marcar momento guarda uma cena com nome e posição. Momentos salvos permite Reproduzir daqui, Renomear e Excluir. Abrir esses diálogos pausa o vídeo; Reproduzir daqui inicia o trecho. Até 30 marcações por vídeo e 100 vídeos, sem exclusão automática de marcações antigas. Salvas neste celular, associadas ao arquivo; não fazem parte do backup de listas. No Android 10 ou superior, referências locais reconhecidas da biblioteca e do seletor de documentos compartilham as marcações. Sem servidor nem API paga.

Tela de vídeos reorganizada: sem área preta nem controles inativos antes de escolher um arquivo; atalho Abrir, painel adaptável, tempo separado dos botões e reprodução por ícone. Busca e botões acomodam fontes maiores do Android. Mantidos tela cheia, PiP, legendas, gestos e retomada.

Nova fila pelo menu: veja a música atual e as próximas, escolha uma faixa para ouvir agora, reorganize ou remova as próximas. Segure uma música na biblioteca para colocá-la como próxima ou no fim da fila, sem iniciar a reprodução. Reorganizar desativa o aleatório; remover todas as próximas também desativa a repetição. Comandos com uma fila desatualizada são recusados pelo serviço.

Menu → Temporizador: ao terminar esta música, após 3 músicas ou após 5 músicas, além dos minutos existentes. Voz: “pare ao terminar esta música” ou “pare após três músicas”. A voz aceita de 1 a 20 faixas. Somente finais naturais contam; pular faixas não consome a contagem. Cancelar ou trocar para minutos substitui o anterior. A fila termina normalmente se tiver menos músicas que o pedido. O temporizador não inicia som e vale somente para o processo atual. Vídeos usam o tocador separado e não são controlados por esse temporizador de áudio. Fechar e abrir o aplicativo mantém a retomada pausada, sem restaurar o temporizador.

Usa a pausa nativa de fim de item do Media3, sem consultar a posição continuamente. Testes reais no emulador usam áudio de três segundos e verificam finais naturais e saltos manuais.

## Histórico — Onda Música 0.27.0 — Memória do DJ

Filas com músicas locais e downloads voltam após fechar o aplicativo com a mesma ordem, faixa e posição. O app abre pausado; não inicia som sozinho. O modo e os motivos das escolhas do DJ também são guardados. Retoma referências locais, sem guardar URLs temporárias de streaming. Se o Android não disponibilizar mais uma faixa na biblioteca, a seleção de retomada segue as disponíveis; documentos movidos, apagados ou sem permissão podem exigir localizar o arquivo novamente.

Menu → Ajustar sessão → Evitar esta música no DJ, ou diga “evite esta música”. O DJ também relaciona referências do mesmo arquivo quando o provedor local do Android permite identificá-las; não abre arquivos nem consulta provedores de nuvem para isso. A preferência vale para novas seleções do DJ, incluindo os modos de favoritas, e não apaga o arquivo nem remove a favorita. A música atual continua. Repetições futuras da mesma faixa em uma fila do DJ são removidas. As buscas e playlists manuais continuam disponíveis. Até 1.000 faixas evitadas; Reautorizar músicas evitadas permite desfazer a lista com confirmação. Preferências locais não são incluídas no backup de listas/favoritas/frases. Minhas frases inclui a nova ação.

Os motivos são guardados por faixa; se houver várias cópias da mesma referência numa fila manual, compartilham o último motivo salvo. Não há gravação de microfone, servidor de recomendações ou análise contínua. Reconhecimento da fala continua dependente do serviço Android.

Validação: testes de filas mistas e dados inválidos, integração com o serviço real, encerramento e recriação do processo no emulador, posição de 12 segundos e explicação restaurada. Mantém pacote e certificado para atualizar sem desinstalar.

## Histórico — Onda Música 0.26.0 — DJ Pessoal

Menu → DJ Pessoal: prévia com motivo de cada escolha, modos Para você, Só favoritas, Redescobrir, Minha viagem e Downloads e redescobertas. Filas locais de até 60 faixas, sem arquivos repetidos. Downloads podem participar mesmo sem duração indexada pelo Android.

Menu → Ajustar sessão: mais variedade, priorizar o artista atual e evitar repetir artistas identificados nas próximas faixas. Esses ajustes preservam a música atual, sua posição e o estado pausado ou tocando. A fila futura é recalculada somente quando você pede. Favoritas sem repetir artista pode gerar uma fila menor; arquivos sem artista identificado não são tratados como um mesmo artista.

Voz: “inicie o DJ Pessoal”, “monte minha viagem”, “mais variedade”, “mais desse artista”, “não repita artista”, “toque minhas favoritas sem repetir artista”, “misture meus downloads com músicas antigas” e “por que esta música?”. Também podem ser associados a atalhos em Minhas frases. O reconhecimento de fala depende do serviço Android; a interpretação e a seleção são locais, sem API de IA paga. Não há microfone sempre ligado.

Aprendizado: usa favoritas, escutas registradas no Onda e, a partir desta versão, reproduções que chegaram naturalmente ao fim após ouvir pelo menos 80% da duração. Avançar diretamente ao fim não gera uma escuta completa. O histórico anterior não é inventado. “Redescobertas” significa tempo sem ouvir no Onda, não o ano de lançamento da música. Não analisa humor, áudio, BPM ou preferências de outros aplicativos.

Pacote e certificado mantidos para atualizar sem desinstalar. A correção das favoritas dos downloads da versão 0.25.1 continua incluída.

## Histórico — 0.25.1

Corrige favoritas de áudios abertos pelos Downloads: documentos baixados entram na biblioteca do Onda mesmo sem indexação do Android. Recupera o último áudio de versões anteriores preservando a marcação existente. Os novos downloads de áudio são registrados após conclusão, inclusive em playlists.

Atualização do Onda principal (`br.com.onda.musica`), com os avanços validados no Onda Lab 0.24.1. Mantém o pacote e o certificado para instalar sobre o Onda 0.21.1 sem remover dados. O Onda Lab continua sendo outro aplicativo; dados privados do Lab podem ser transferidos por Backup e restauração, sem copiar automaticamente arquivos de áudio.

Menu → Downloads: vídeos individuais, playlists públicas e Mixes do YouTube; seleção com miniaturas, duração, marcação individual e botão fixo Baixar (quantidade). MP3 real a 192 kbps, M4A e MP4; até 100 vídeos por seleção, 50 para Mixes, e MP4 da fila até 720p. Recuperação limitada de quedas, relatório copiável e cancelamento mantendo arquivos concluídos. A disponibilidade dos conteúdos continua sujeita ao YouTube.

Menu → Atualizações consulta o canal do Onda principal e instala mediante confirmação do Android. O APK, manifesto de atualização e fontes são publicados juntos após compilação, testes de atualização de dados, regressão do player e testes dos downloads.

Os detalhes, limites e licenças dos downloads estão em [DOWNLOADS.md](DOWNLOADS.md). Esta edição do aplicativo é software livre sob GNU GPL v3 ou posterior, sem garantia; veja [LICENSE](LICENSE). As dependências mantêm suas respectivas licenças.

## Histórico anterior

## Correção 0.21.1

Preserva nomes de listas e metadados formados apenas por emojis ou símbolos, sem combinar nomes diferentes durante a restauração.

## Novidades 0.21 — Backup e playlists por voz

Menu → Backup e restauração: exporte playlists, favoritas e frases de voz em JSON usando o seletor de arquivos do Android. O arquivo não contém músicas nem histórico, posição/fila, vídeos ou ajustes de som; copie seus áudios separadamente. Backups não são criptografados. Limite de 8 MB e 20.000 faixas referenciadas; permanecem os limites de 100 listas, 2.000 músicas por lista e 100 frases.

A restauração mostra uma prévia e acrescenta dados sem apagar os atuais. Listas de mesmo nome são combinadas mantendo a ordem existente; frases conflitantes mantêm a atual. Músicas são relacionadas por título e artista normalizados, álbum quando informado e duração com tolerância de 1,5 segundo; IDs do outro celular nunca são usados como identidade. Referências ausentes ou ambíguas são ignoradas e contadas. Pode importar novamente após copiar as músicas; a mesclagem evita duplicação. Ao exportar, referências a arquivos indisponíveis são contadas e não incluídas.

Voz: “adicione esta música à minha playlist Viagem”. Usa a faixa local atual, evita duplicação e oferece escolha para nomes ambíguos; listas inexistentes não são criadas automaticamente. Em Minhas frases, a ação Adicionar música atual à playlist aceita atalhos personalizados. Sem API paga. Campo de frase mantém o texto literal, sem correção automática.

## Novidades 0.20 — Fones e Bluetooth

Menu → Fones e Bluetooth em Músicas, Explorar e Vídeos. A tela abre as configurações Bluetooth para parear/conectar o fone e oferece o seletor nativo de saídas de mídia do Android quando há rotas compatíveis. Não faz busca Bluetooth em segundo plano nem força modo de chamada/SCO. O Android confirma o pareamento e negocia o codec; disponibilidade e troca de saída dependem do aparelho. Saídas disponíveis e rota informada pelo sistema são exibidas separadamente; não medimos qual dispositivo está efetivamente emitindo áudio.

Estúdio de som: novos perfis manuais Fones equilibrados, Fones voz nítida e Alto-falante claro, com compensação de ganho. Aplicam-se a músicas e áudio online; vídeos usam tocador separado. Não há amplificação garantida, calibração automática, alteração de codec ou simulação de áudio sem perdas. Ajustes e efeitos dependem do hardware. Monitoramento de saídas apenas enquanto a tela Fones e Bluetooth está aberta.

## Novidades 0.19 — Janela flutuante e voz para playlists

Vídeos: durante a reprodução, Menu → Janela flutuante abre o modo imagem em imagem do Android, com pausa/reprodução e os controles do sistema para expandir ou fechar. Depende do suporte e da permissão de imagem em imagem do aparelho. A entrada é explícita: sair normalmente continua pausando o vídeo. Não exige permissão para desenhar sobre outros apps.

Voz: diga “toque minha playlist Viagem” ou “toque a lista Treino”. Usa as playlists e os arquivos do aparelho, ignora arquivos indisponíveis e pede uma escolha quando há nomes ambíguos. Prioriza nome exato, aceita diferenças de acento. Pode criar atalhos em Minhas frases → Tocar playlist. Interpretação local sem API paga; o reconhecimento do microfone depende do serviço de voz instalado no celular.

## Novidades 0.18 — Continuar de onde parou

O Onda restaura a fila local, a faixa e a posição ao reabrir, sempre pausado. Toque Reproduzir para continuar. Preserva os modos de repetição e embaralhamento (a sequência aleatória pode mudar). Salva ao pausar, trocar, buscar e a cada 15 segundos enquanto toca; um encerramento abrupto pode perder os últimos segundos. Arquivos ausentes são ignorados; se a faixa atual faltar, começa a próxima disponível do zero. Filas online não são restauradas. Listas maiores que 10.000 faixas não são salvas. Nenhuma análise contínua ou serviço externo.

## Novidades 0.17 — Playlists

Menu → Playlists: crie listas, renomeie, escolha músicas por título ou artista, mova faixas e remova da lista. As listas ficam salvas no aparelho. Ouvir lista substitui a fila e toca na ordem exibida, sem embaralhar ou repetir. Arquivos indisponíveis ficam indicados e são ignorados na reprodução; excluir uma playlist não exclui músicas. Limites: 100 listas, 2.000 faixas por lista; listas locais, sem sincronização entre aparelhos.

# Onda — tocador Android 0.3.0

Primeira implementação nativa em Java, interface em português, Android 8.0 ou superior.

## Recursos implementados

- Biblioteca de arquivos de áudio indexados pelo Android, busca por título, artista e álbum.
- Reprodução local com AndroidX Media3/ExoPlayer.
- Reprodução em segundo plano, notificação de mídia e controles na tela bloqueada.
- Pausar/continuar, anterior/próxima, posição, modo aleatório e repetição.
- Favoritos persistentes no aparelho.
- Temporizador de pausa: 15, 30, 60 ou 120 minutos; funciona enquanto o serviço permanece ativo.
- Gerenciamento de foco de áudio e pausa ao desconectar fones.
- Acesso somente aos arquivos de áudio; sem conta ou anúncios. A busca de letras usa internet e envia somente título, artista e duração ao LRCLIB; o áudio permanece no aparelho.

MP3, FLAC, WAV, AAC/M4A e OGG são suportados conforme o contêiner, o codec e os decodificadores do aparelho. Arquivos protegidos por DRM não são contemplados.

## Letras online (0.3.0)

Toque em **Ver letra da música** no painel de reprodução. A busca usa LRCLIB (https://lrclib.net), sem chave ou login. Quando há LRC, o verso atual ganha destaque e a tela rola automaticamente. Tocar em um verso busca sua posição no áudio. Ao rolar manualmente, o acompanhamento pausa por cinco segundos. Letras sem tempos são exibidas como texto rolável. É possível corrigir título e artista e repetir a busca. A tela acompanha as trocas de faixa.

Até 100 respostas ficam no cache privado para reabrir sem internet; o Android pode limpar esse cache. Não há garantia de letra para toda música ou de que os tempos correspondam a uma versão ao vivo/remix. Há mensagens para faixa instrumental, letra ausente e falha de rede.

## Ouvir online (0.3.0)

Botão **Buscar e ouvir online** na biblioteca. A fonte é a Live Music Archive (`collection:etree`) do Internet Archive: busque artista ou música, abra um show e toque em uma faixa MP3. A fila passa a ser o show escolhido. O streaming usa o mesmo serviço Media3 do áudio local, incluindo controles e reprodução com tela desligada. Não é o catálogo comercial completo e não exige conta. As buscas enviam os termos ao archive.org. Sem download permanente: há somente o buffering normal do player. Letras continuam disponíveis conforme o LRCLIB.

Verificar no aparelho: busca vazia, artista conhecido, nenhum resultado, show sem MP3, falha de rede, troca de faixa, tela desligada e retorno à biblioteca.

## Gerar e instalar

1. Abra esta pasta como projeto no Android Studio com suporte ao Android Gradle Plugin 8.7.3.
2. Instale o Android SDK 35 e configure o Gradle 8.9 local em Settings > Build Tools > Gradle. Use JDK 17 ou 21. Este projeto não inclui o binário do Gradle Wrapper.
3. Sincronize as dependências e use Build > Generate App Bundles or APKs > Generate APKs (a nomenclatura pode variar por versão).
4. O APK de desenvolvimento será gerado em `app/build/outputs/apk/debug/app-debug.apk`.
5. Transfira para seu Android e permita a instalação pela origem escolhida. Ao abrir o app, permita acesso às músicas.

Alternativa no terminal, com SDK e Gradle instalados:

```sh
gradle assembleDebug lintDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

Alternativa no GitHub: neste repositório, abra Actions > Onda - Gerar APK Android > Run workflow e baixe o artefato Onda-Android-APK após a conclusão. O workflow fica em `.github/workflows/onda-android.yml` na raiz do repositório e compila a pasta `Onda`. Consulte o resultado da execução no GitHub Actions.

## Estado da validação

A versão 0.1 passou por compilação e lint no GitHub Actions, e o usuário confirmou reprodução no celular com a tela desligada. Para a versão 0.2, consulte a execução do GitHub Actions correspondente ao commit. O parser LRC tem teste executável em `tests/LrcTest.java`. Busca online, rolagem e sincronização precisam de validação final no aparelho. APKs debug de execuções diferentes podem usar certificados diferentes: se o Android recusar a atualização, desinstalar a versão anterior remove também os favoritos.

## Verificação no aparelho

- Android 8–12: aceitar e negar permissão de armazenamento; Android 13+: aceitar e negar permissão de áudio. Recuperar pelo botão de configurações e Atualizar.
- Biblioteca vazia, busca sem resultado, títulos acentuados e favoritos após fechar/reabrir.
- Tocar exemplos reais de MP3, FLAC, WAV, AAC/M4A e OGG; tratar arquivo removido/incompatível.
- Tela bloqueada, app em segundo plano, notificação, fones removidos e interrupção de áudio por outro app.
- Avançar, retroceder, buscar posição, repetir uma/todas e modo aleatório.
- Temporizador com tela apagada; confirmar pausa e cancelamento.
- Letras: faixa com sincronização, sem sincronização, instrumental, ausente e dados incompletos.
- Desconectar internet: mensagem de erro e reabertura de letra no cache; trocar de faixa durante busca; avançar/retroceder; retornar à biblioteca sem interromper áudio.

## Limites da primeira versão

Sem navegação separada por pastas. A fila segue os resultados selecionados; playlists, DJ e Estúdio de som estão disponíveis pelo menu. Favoritos são vinculados ao identificador local do arquivo. A lista usa componentes nativos simples e ainda precisa de otimização para bibliotecas muito grandes. O Android pode encerrar o processo e cancelar o temporizador; a fila local e a posição são restauradas conforme descrito acima. O APK de debug é destinado a teste, não a publicação na Google Play.


## Instalação 0.3.1

O APK é instalado como **Onda Novo**, com applicationId `br.com.onda.player`. Pode coexistir com o Onda antigo (`br.com.onda`), evitando o conflito de assinatura sem apagar os dados da instalação anterior. Favoritos da versão antiga permanecem nela e não são migrados automaticamente. As funções de músicas locais, letras e streaming estão incluídas. O workflow reutiliza a chave debug via cache do GitHub Actions, enquanto esse cache estiver disponível; não substitui uma configuração de assinatura de produção com chave privada persistente.


## Busca aprimorada (0.4.0)

No celular: filtro Tudo, Nome da música, Artista ou Álbum. A busca ignora acentos, maiúsculas e pontuação e aceita palavras em qualquer ordem. Exemplo: `joao coracao` encontra título Coração e artista João no filtro Tudo. A fila local passa a seguir os resultados visíveis ou favoritos ao tocar uma música.

Online: filtros Tudo, Artista e Música no repertório, ordenação por relevância, popularidade ou data do show, páginas de 20 resultados com total, sugestões das últimas oito buscas e filtro de faixas dentro do show. Voltar aos resultados mantém a página sem repetir a consulta. O filtro Música procura nos títulos e descrições dos shows: não é um índice completo de faixas e pode encontrar termos apenas na descrição. A fonte continua sendo Live Music Archive, não o catálogo completo de músicas comerciais.

Verificações: busca local sem acento, palavras em outra ordem, filtros de campo e sem resultados; fila da busca local; filtros online, mais resultados/anterior, retorno de um show, busca de faixa e limpeza do filtro; desconexão e nova tentativa. Os testes SearchTextTest e LrcTest rodam no CI; há teste ao vivo de consulta e streaming do acervo. Assinatura: antes de entregar, comparar o certificado do APK com o Onda Novo 0.3.1.

A consulta não exige `mediatype:audio`: esse filtro excluía registros da coleção etree. O teste de integração cobre também artista, ordenação e segunda página.


### Assinatura da versão 0.4

A comparação do APK 0.4 com 0.3.1 encontrou certificados diferentes: o cache antigo apontava para um arquivo inexistente, então a chave antiga não foi preservada. Esta distribuição usa **Onda Música** (`br.com.onda.musica`) e instala ao lado do Onda Novo, preservando os dados dele, sem migrar favoritos. A chave debug passa a ter caminho explícito `.signing/debug.keystore`, cache próprio e conferência do certificado esperado. Nunca publique o arquivo da chave no repositório. Se o cache desaparecer, recupere a chave original antes de emitir novas atualizações; o workflow deve interromper em caso de assinatura diferente.


## Atualizações dentro do app (0.5.0)

No cabeçalho, toque em **Atualizações → Verificar atualizações**. O app consulta as releases públicas `onda-v*` do GitHub, lê o manifesto `onda-update.json` e oferece download quando o versionCode é maior. Depois confere SHA-256, applicationId, versionCode e assinatura do APK contra a instalação atual. O instalador nativo exige confirmação do usuário; a primeira instalação por essa origem pode pedir autorização nas configurações do Android. Não há desinstalação automática.

A versão 0.5.0 precisa ser instalada uma vez sobre Onda Música 0.4. Onda e Onda Novo são pacotes diferentes e não recebem esta atualização. A mesma chave da versão 0.4 é obrigatória. O workflow publica release e APK apenas depois de compilação, testes e validação do certificado esperado; requer permissão `contents: write` no job.

Validação no aparelho: nenhuma atualização, sem internet, download, permissão negada/concedida, cancelamento da instalação e atualização preservando favoritos. Testes de manifesto rejeitam outro pacote, origem inválida, versão inválida e hash malformado. O fluxo final de instalação precisa ser testado no Android. Para publicação na Google Play, rever a distribuição por APK e o uso de REQUEST_INSTALL_PACKAGES conforme as regras aplicáveis.


## Consumo de bateria (0.5.1)

A barra de progresso da biblioteca para completamente quando a tela da atividade deixa de estar visível e quando a música está pausada; enquanto toca com a interface visível, atualiza uma vez por segundo. A letra acompanha a posição a cada 500 ms apenas em reprodução e visível; em pausa, muda somente por eventos. A rolagem só se repete ao mudar de verso ou após uma rolagem manual. O Wi-Fi lock fica restrito a faixas HTTP/HTTPS; músicas locais mantêm apenas o CPU lock necessário para reprodução com a tela apagada. O ExoPlayer gerencia a liberação dos locks quando a reprodução pausa. Nenhuma verificação periódica de atualizações ou letras foi adicionada.

Validar no celular: continuar tocando após apagar a tela, música local sem lock de Wi-Fi, troca local/online, pausa e retomada, retorno à biblioteca, seek com letra pausada e rolagem manual. Compilação não substitui medição: não há estimativa de percentual de economia sem ensaio no aparelho.


## Identidade visual (0.6.0)

Tema escuro com acentos ciano e violeta, cartões de músicas com ícones vetoriais, filtros com estado selecionado, controles de reprodução desenhados em Canvas e player compacto com ação de favoritos. As telas de biblioteca, letras, busca online e atualizações compartilham a mesma identidade. Ícone do app atualizado. Os elementos gráficos são estáticos; não há loop de animação nem downloads de capas. As otimizações de bateria da versão 0.5.1 permanecem.

`tools/capture_ui.py` usa áudio de demonstração temporário no emulador e captura as telas reais; esses arquivos de áudio não são incluídos no APK. As capturas ficam no artefato Onda-Visual-Preview do CI. Verificar layout, textos, tamanho dos controles, reprodução e navegação em aparelho físico.


## Voz e busca de músicas (0.7.0)

Microfone nas buscas local e online. Usa RecognizerIntent do Android em português; não adiciona serviço de escuta nem permissão de gravação ao Onda. No celular há preferência por reconhecimento offline quando suportado pelo serviço do aparelho; na internet, o texto reconhecido dispara a busca. Cancelar mantém a consulta anterior. Sem reconhecedor instalado, o app explica e permite digitar normalmente. A captura real de voz precisa ser testada em um aparelho com serviço compatível.

A fonte padrão online agora é **Catálogo • prévias**, usando a API pública iTunes Search no Brasil. Reúne buscas por artista e por termo, prioriza o artista correspondente, trata acentos e os conectores e/& e remove duplicatas de música/artista. Exemplo real testado: Chitaozinho e xororo. Cada resultado e a tela de bloqueio identificam **prévia**; tocar reproduz apenas o trecho promocional, com link explícito da faixa completa no Apple Music. Não há download offline nem cache de áudio das prévias. Letras sincronizadas são desativadas para esses trechos, que podem começar no meio da música. A disponibilidade varia por região/faixa; não é streaming gratuito de faixas comerciais completas.

**Shows completos** mantém o Internet Archive e amplia automaticamente o filtro caso uma busca específica não encontre shows. Há distinção entre serviço indisponível/resposta inválida e consulta válida sem resultados. As consultas de catálogo ficam em memória por cinco minutos, no máximo oito termos, evitando repetir downloads de metadados ao mudar de página.

Os testes cobrem o nome da dupla, prioridade de artista, números de ID, URLs e resposta inválida; `tests/check_catalog.py` confere o artista e baixa bytes reais de uma prévia. O emulador verifica presença dos dois microfones; não simula reconhecimento de fala.


## Versão 0.8.0 — Onda Lab

Comandos de voz pelo botão de microfone: “próxima música”, “pause”, “toque minhas favoritas”, “toque [nome]” na biblioteca e “pare em 30 minutos”. O reconhecimento depende do serviço de voz instalado no celular; não há escuta em segundo plano. Na internet, “toque [nome]” mostra resultados para escolher uma prévia.

Coleções favoritas, mais tocadas, recentes e redescobrir usam apenas os arquivos e histórico deste celular. A reprodução é contada após até 30 segundos de escuta efetiva; músicas curtas usam metade da duração, mínimo 5 segundos. Possíveis duplicatas comparam título/artista e duração com tolerância de 1,5 segundo, sem apagar arquivos ou comparar áudio.

Fade suave desligado ou de 1 a 3 segundos: desce volume no fim e sobe no início da próxima faixa automática; sem sobreposição. Não aplicado a prévias de catálogo, faixas muito curtas ou duração desconhecida. Agendamento pontual e rampas curtas evitam processamento permanente.


## Versão 0.9.0 — Vídeos do celular

Botão Vídeos do celular: lista MediaStore com busca por título e nome do arquivo, fila dos resultados, seek, pausar e tela cheia em paisagem. Abrir arquivo usa o seletor de documentos sem exigir acesso à biblioteca inteira, inclusive para formatos que o MediaStore não indexa. Android 13+ pede READ_MEDIA_VIDEO separadamente de música; Android 14+ aceita seleção parcial.

LibVLC Android 3.7.7 amplia contêineres e codecs além do decoder nativo do Android. MP4, MKV, AVI, MOV, WebM, FLV, WMV, MPEG, TS e outros: suporte não é garantia para todo codec, arquivo danificado ou protegido. DRM não é suportado. Usa decoder de hardware quando disponível e uma nova tentativa por software em falha. Bibliotecas nativas aumentam o tamanho do APK.

Ao reproduzir vídeo o controlador pausa a música antes de obter foco de áudio, evitando sobreposição. Interrupções de áudio e desconexão de fones pausam vídeo. Ao ir para outro app ou bloquear a tela, o vídeo pausa e libera foco; não retoma sozinho. Mantém tela acesa somente durante reprodução visível. A música mantém o funcionamento anterior em segundo plano. Libera descritores de arquivo e o motor ao fechar a tela.

LibVLC © VideoLAN e colaboradores, licença LGPL 2.1 ou posterior, incluída em app/src/main/assets/libvlc-license.txt e acessível pela tela de informações. Sem modificações no motor; fonte, versões e instruções para recompilar as bibliotecas substituíveis em https://code.videolan.org/videolan/libvlcjni e https://code.videolan.org/videolan/vlc-android . Artefato Maven org.videolan.android:libvlc-all:3.7.7. O código do Onda é disponibilizado neste repositório para reconstruir o APK com outras versões da biblioteca.

O APK de distribuição inclui ARM de 32 e 64 bits com bibliotecas comprimidas, para permanecer abaixo de 64 MiB e funcionar com o atualizador anterior. O CI guarda esse APK antes de reconstruir uma variante x86_64 apenas para os testes do emulador; essa variante não é publicada. Os mesmos código Java, versão e bibliotecas LibVLC são usados nas duas compilações.

A atividade de vídeo também aceita ACTION_VIEW com URI content:// e MIME video/*, para usar “Abrir com Onda” no gerenciador de arquivos com permissão temporária de leitura. O motor abre o descritor de arquivo concedido, sem precisar converter o caminho em acesso irrestrito ao armazenamento. Formatos não indexados como vídeos pelo Android podem ser abertos pelo seletor ou pelo gerenciador de arquivos.


## Versão 0.10.0 — Menus e navegação

Três destinos principais na barra inferior: Músicas, Vídeos e Explorar, com seção atual destacada. A mudança de seção reaproveita a biblioteca principal e fecha a tela anterior de vídeo/online, evitando empilhar players.

Menu da biblioteca: Coleções inteligentes, Letra da música, Temporizador, Recarregar biblioteca e Atualizações. O botão Filtrar abre a escolha de Todos os campos, Música, Artista ou Álbum. As abas Todas/Favoritas e os controles essenciais permanecem à vista; o campo de busca ganha largura.

Menu de vídeos: Abrir arquivo, Acesso aos vídeos, Recarregar vídeos e Formatos e licenças. Navegação inferior se recolhe durante a digitação e em tela cheia. No Explorar, fontes e filtros ficam em um painel recolhido, acessível pelo menu ou tocando na identificação da fonte. A indicação de prévias continua visível.

Os menus e a navegação usam componentes nativos estáticos, sem novos serviços ou animações em segundo plano. O emulador verifica os destinos de navegação, filtros, menus e ações transferidas, além da reprodução de vídeo e tela cheia.


### Versão 0.11 — comandos de voz
Toque no microfone e diga “toque minhas músicas favoritas”, “adicione essa música aos favoritos”, “remova dos favoritos”, “ative o modo aleatório”, “repita a música”, “repita todas”, “não repetir”, “pause”, “continue”, “próxima música” ou “pare em 30 minutos”. “Ajuda” e Menu → Comandos de voz mostram exemplos. “Onda,” e “por favor” são aceitos. Favoritas usam arquivos locais disponíveis; lista vazia orienta salvar uma música. Comandos explícitos de pesquisa não executam ações. O reconhecimento depende do serviço de voz do aparelho, acionado pelo botão; não há escuta permanente. Em Explorar, nomes continuam pesquisando o catálogo.

### Versão 0.12 — interpretação local gratuita
IA local sem chave, API ou custo adicional: classificador TF-IDF por exemplos de intenções em português, calculado apenas ao receber um pedido. Reconhece variações dos controles do player; não conversa sobre assuntos gerais. Limiar de similaridade e margem entre intenções evitam executar pedidos incertos, que permanecem como busca. Menu → Assistente com IA permite ativar/desativar (ativado por padrão). Não envia texto, áudio ou biblioteca para um provedor de IA, não baixa modelos e não mantém serviço de interpretação em segundo plano. O reconhecimento da fala é separado e depende do serviço do aparelho, podendo usar internet. Exemplos: “coloca aquelas músicas que eu mais gosto”, “guarda essa música nos favoritos”, “mistura a ordem das músicas”. Comandos diretos continuam disponíveis com o classificador desativado.

### Versão 0.13 — frases de voz personalizadas
Menu → Minhas frases: criar, ditar, editar e excluir até 100 atalhos. Cada frase executa uma ação escolhida (favoritas, reprodução, pausa, faixa, favoritos, aleatório, repetição, busca, ajuda ou temporizador de 0 a 120 minutos). Buscas guardam nome/artista; 0 cancela o temporizador. Correspondência exata após normalizar acentos, caixa, pontuação e Onda/por favor; atalhos têm prioridade sobre a interpretação local; comandos padrão são reservados e funcionam mesmo com o classificador local desligado. Frases duplicadas são rejeitadas; pesquisar/buscar explícitos ficam reservados a buscas. Dados somente em preferências locais, preservados em atualizações com a mesma assinatura. Sem API, cobrança ou escuta em segundo plano.

### Versão 0.14 — Estúdio de som
Menu → Estúdio de som na biblioteca e em Explorar: equalizador de cinco faixas de referência (60/230/910/3600/14000 Hz, ±6 dB), reforço de graves e presets Original, Voz, Sertanejo, Rock, Pop e Graves suaves. Curva interpolada em escala logarítmica para as bandas reais do Equalizer do aparelho. BassBoost depende de suporte e controle nativos. Estado mostra efeitos disponíveis/indisponíveis; não aplica efeitos globais nem a vídeos LibVLC. Configurações locais preservadas; botão restaura Original e desativa tudo. Compensação conservadora de ganho reduz risco de saturação ao reforçar frequências; não é normalização por análise do áudio. Ajustes inicialmente desligados; efeitos liberados ao desligar ou encerrar e desativados na pausa. Sem análise contínua, visualizador animado, internet ou nova dependência. Testes de matemática e de interface não substituem avaliação auditiva em aparelhos e fones reais.

### Versão 0.15 — DJ automático local
Menu → DJ automático: prévia de filas de até 15, 30 ou 60 músicas do celular. Modos Para você, Só favoritas e Redescobrir; Nova mistura refaz a seleção e Ouvir seleção substitui a fila, desativa aleatório/repetição e mantém a ordem exibida. Recomendações por seleção ponderada, baseadas em favoritas e no histórico do próprio Onda; não faz análise acústica, BPM, detecção de humor ou recomendações de catálogo online. Reduz o peso de escutas recentes, valoriza favoritos/hábito no modo pessoal e arquivos pouco ou nunca ouvidos no modo Redescobrir. Evita IDs repetidos e possíveis cópias com título/artista e duração semelhante (1,5s), sem apagar arquivos. Prefere separar os dois últimos artistas quando houver alternativas; artistas desconhecidos não são tratados como um artista único. Com poucas faixas, usa o que estiver disponível. Processamento somente ao gerar fila, em tarefa finita fora da interface; sem serviço de recomendação, download, cobrança ou análise contínua. O histórico cresce com a escuta real registrada pelo serviço de áudio.

### Versão 0.16 — vídeos com posição, legendas e gestos
A posição é guardada localmente ao pausar, trocar de vídeo, buscar outra posição e sair da tela. Ao selecionar um vídeo iniciado, oferece Continuar/Recomeçar; perto do início/fim ou com duração alterada, recomeça. Até 100 posições por URI (documento e biblioteca podem ter URIs diferentes); não faz gravação contínua em disco e não promete recuperar a última posição após encerramento abrupto antes de salvar. CC/Menu → Legendas carrega SRT, VTT, ASS e SSA de até 2 MiB pelo seletor nativo, copiados para cache privado somente durante a sessão do vídeo; trocar de vídeo ou fechar libera a cópia. Desativar remove a seleção de legenda. Gestos verticais na metade esquerda ajustam o brilho da janela, na direita o volume do vídeo (0–100%, salvo localmente); não alteram brilho/volume globais. Menu → Gestos e posição explica e restaura os controles. Recursos funcionam também em tela cheia; vídeos continuam pausando ao sair. Compatibilidade de arquivos/legendas depende do motor e da codificação.

A abertura de vídeo também verifica se chegaram quadros: se houver reprodução sem imagem por 8 segundos, tenta uma vez o decodificador de software. A verificação é cancelada quando chegam quadros ou ao pausar, sem sondagem contínua. A API String de addSlave recebe caminho local absoluto da cópia de legenda, sem prefixo file://.

Retomada e inclusão de legenda aguardam o relógio de reprodução iniciar e a janela de vídeo estar pronta, evitando buscas prematuras que podem interromper o relógio de alguns arquivos MPEG-TS.

A seleção ou desativação de legendas é aplicada uma única vez por abertura de mídia, sem reconfigurar a faixa a cada atualização de tempo.

A precisão da retomada e da sincronização de legendas depende dos timestamps e da capacidade de busca do arquivo. A validação detalhada dos novos controles usa MP4; a regressão de reprodução mantém MP4, MKV, AVI, WebM, FLV, WMV, MOV e TS.
