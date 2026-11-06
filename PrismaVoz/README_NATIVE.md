# Prisma Voz Android nativo 1.3.0

App Android independente de navegador e WebView. Interface em controles Android; renderização pelo `PdfRenderer` do sistema; voz pelo motor TTS escolhido; OCR latino incorporado Google ML Kit 16.0.1. Em Android 15+, tenta primeiro a extração de texto fornecida pelo sistema. Nas demais versões usa OCR local, inclusive em PDFs com texto selecionável. Sem exigir conta Google ou download posterior do modelo latino.

Mantém o pacote `com.arakaki.prismavoz` e a assinatura anterior. Não é renomeação para contornar o Play Protect. Nenhuma configuração do Play Protect é alterada. Um APK e seus testes não constituem liberação do Google; se houver bloqueio, não force a instalação.

## Recursos e limites

Abra PDFs pelo seletor do Android, visualize páginas, escolha voz offline ou online disponível, velocidade/tom e intervalo. Pause, continue ou pare no app/notificação. O modelo OCR reconhece escrita latina, incluindo português, inglês e espanhol; não garante manuscritos ou texto ilegível. O modo sensível usa até 3200 px e 6 milhões de pixels, com tentativa de contraste para páginas com pouco texto. Grupos curtos preservam Unicode, números e hífens explícitos. A continuação por palavra depende do motor de voz.

Leitura em segundo plano usa serviço de reprodução, foco de áudio e wake lock apenas durante fala. A lista de vozes depende do Android; configure e instale os dados de voz no sistema. O PDF é copiado temporariamente para cache privado e apagado ao fechar; cópias deixadas por encerramento abrupto são limpas na próxima inicialização. Limites: PDF 25 MB e 500 mil caracteres por sessão.

O OCR processa conteúdo no aparelho; bibliotecas do SDK podem coletar dados técnicos/diagnósticos conforme os termos do fornecedor. A opção de atualizações/vozes online controla os fluxos do app, sem afirmar que controla toda telemetria interna do SDK. Vozes online podem transmitir texto ao fornecedor. A atualização interna preserva SHA-256, pacote, versão, assinatura e confirmação do Android.

## Compilar

JDK 21 completo, Gradle 8.11.1, SDK 35/build-tools 35.0.0. Dependências travadas e verificadas por SHA-256. Os diretórios `assets/` e `dependencies/` do leitor web anterior não são entradas do build nativo. Só `native-assets/` entra no APK.

```sh
ANDROID_HOME=/caminho/sdk PRISMA_GRADLE=gradle bash PrismaVoz/build.sh verify
# Testes do emulador x86_64 (não muda os ABIs ARM da distribuição):
gradle -p PrismaVoz/native-build -PemulatorBuild=true assembleDebug assembleDebugAndroidTest
```

O workflow Prisma Voz — leitor Android nativo compila release ARM/ARM64 e testes, roda Android 29 AOSP com Wi-Fi/dados desligados, verifica `PdfRenderer`, OCR real de páginas normais e claras/inclinadas e uma interface sem WebView. Não mede emissão audível do TTS nem a classificação do Play Protect.

O candidato assinado é publicado como pré-lançamento após a validação. O canal estável não é ativado automaticamente por esse fluxo. A assinatura continua privada e permanente; não se publica chave ou credencial.
