# Onda — tocador Android 0.1.0

Primeira implementação nativa em Java, interface em português, Android 8.0 ou superior.

## Recursos implementados

- Biblioteca de arquivos de áudio indexados pelo Android, busca por título, artista e álbum.
- Reprodução local com AndroidX Media3/ExoPlayer.
- Reprodução em segundo plano, notificação de mídia e controles na tela bloqueada.
- Pausar/continuar, anterior/próxima, posição, modo aleatório e repetição.
- Favoritos persistentes no aparelho.
- Temporizador de pausa: 15, 30, 60 ou 120 minutos; funciona enquanto o serviço permanece ativo.
- Gerenciamento de foco de áudio e pausa ao desconectar fones.
- Acesso somente aos arquivos de áudio; sem conta, servidor, anúncios ou permissão de internet.

MP3, FLAC, WAV, AAC/M4A e OGG são suportados conforme o contêiner, o codec e os decodificadores do aparelho. Arquivos protegidos por DRM não são contemplados.

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

Compilação `assembleDebug` e verificação `lintDebug` concluídas com sucesso no GitHub Actions em 21/10/2026. APK de teste disponível em [Onda-Android-APK](https://github.com/cristianoarakaki-cpu/Arakaki/actions/runs/39526171391/artifacts/12312671968). Extraia o ZIP e instale `app-debug.apk`. Os testes em aparelho ainda NÃO foram executados.

## Verificação no aparelho

- Android 8–12: aceitar e negar permissão de armazenamento; Android 13+: aceitar e negar permissão de áudio. Recuperar pelo botão de configurações e Atualizar.
- Biblioteca vazia, busca sem resultado, títulos acentuados e favoritos após fechar/reabrir.
- Tocar exemplos reais de MP3, FLAC, WAV, AAC/M4A e OGG; tratar arquivo removido/incompatível.
- Tela bloqueada, app em segundo plano, notificação, fones removidos e interrupção de áudio por outro app.
- Avançar, retroceder, buscar posição, repetir uma/todas e modo aleatório.
- Temporizador com tela apagada; confirmar pausa e cancelamento.

## Limites da primeira versão

Sem streaming, equalizador, playlists personalizadas ou navegação separada por pastas. A fila segue a biblioteca completa, inclusive ao iniciar a reprodução pela busca ou pelos favoritos. Favoritos são vinculados ao identificador local do arquivo. A lista usa componentes nativos simples e ainda precisa de otimização para bibliotecas muito grandes. O Android pode encerrar o processo e cancelar o temporizador; a fila e a posição não são restauradas após encerramento do processo. O APK de debug é destinado a teste, não a publicação na Google Play.
