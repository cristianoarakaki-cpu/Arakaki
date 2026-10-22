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

Sem equalizador, playlists personalizadas ou navegação separada por pastas. A fila segue a biblioteca completa, inclusive ao iniciar a reprodução pela busca ou pelos favoritos. Favoritos são vinculados ao identificador local do arquivo. A lista usa componentes nativos simples e ainda precisa de otimização para bibliotecas muito grandes. O Android pode encerrar o processo e cancelar o temporizador; a fila e a posição não são restauradas após encerramento do processo. O APK de debug é destinado a teste, não a publicação na Google Play.


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
