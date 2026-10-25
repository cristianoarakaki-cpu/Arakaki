# Onda Música 0.32.0 — Repetir trecho A–B

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
