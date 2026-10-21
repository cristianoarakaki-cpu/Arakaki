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
