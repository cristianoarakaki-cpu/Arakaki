# Prisma Voz

Aplicativo Android dedicado a ler PDFs em voz alta, independente do Prisma PDF. Pacote `com.arakaki.prismavoz`, Android 8 ou superior. Não substitui nem modifica outros aplicativos.

## Uso

Abra um PDF de até 25 MB, escolha uma voz instalada, ajuste velocidade/tom e o intervalo de páginas e toque **Ler em voz alta**. Há pausa, continuação e parada no leitor e na notificação. O serviço de reprodução mantém a leitura com tela apagada; a continuidade real depende do motor de voz e das regras de bateria do aparelho. Ao continuar, motores compatíveis retomam a partir da palavra informada pelo Android; outros podem repetir um trecho curto de até cerca de 700 caracteres. Selecionar outro PDF para a leitura anterior.

As vozes vêm do motor padrão de texto para fala do Android; o botão de configuração abre os ajustes do sistema. A lista identifica vozes offline e online. Vozes online só são oferecidas após marcar a opção e exigem também **Permitir ações online**; podem enviar o texto ao fornecedor do motor de voz. Revogar ações online interrompe uma voz online. O app não instala nem compra vozes.

Para digitalizações, marque **Reconhecer páginas difíceis (OCR offline)**. O modo **Mais sensível** usa maior resolução (até 3200 pixels no lado maior e 7 milhões de pixels), contraste e correção de inclinação leve; em resultados fracos, tenta binarização local, texto disperso e orientação alternativa. **Rápido** faz uma passagem. **Quando o texto faltar ou parecer incompleto** também reconhece páginas com um cabeçalho curto ou caracteres quebrados; **Todas as páginas · Refazer texto** permite refazer camadas ruins. Uma cópia de texto nativo legível é preservada se a tentativa seletiva não recuperar mais conteúdo. Páginas com confiança baixa recebem aviso; não há garantia de transcrição exata. Modelos de português, inglês e espanhol estão incluídos. OCR pode demorar, errar palavras e interpretar incorretamente colunas/tabelas; revise documentos importantes. A ordem da fala segue a extração de texto do PDF, ou o OCR. Limite de 500.000 caracteres por sessão; selecione menos páginas para documentos extensos.

O app não guarda PDFs nem histórico. Preferências de voz/tema ficam locais. O texto da sessão fica em memória; um arquivo temporário privado transporta os dados para o serviço e é removido após iniciar. Parar, fechar a tarefa ou terminar a reprodução libera o texto e o áudio. Não há retomada após encerrar o processo do aplicativo. A permissão de notificação permite controlar a leitura sem retornar ao app.

## Atualização automática

Canal próprio `PrismaVoz/update.json`, releases `prismavoz-v*`. Com **Permitir ações online** ligado, ao abrir o app ele verifica o canal uma vez por dia e oferece a nova versão. Download e instalação exigem confirmação do usuário e do Android. Pode verificar manualmente em Conexão e atualizações. Pacote, versão, SHA-256 e assinatura são conferidos antes da instalação. Não há instalação silenciosa.

O workflow **Prisma Voz — validar e publicar** verifica bibliotecas, lógica, leitor e OCR em navegador offline, compila, confere o APK previamente assinado e só então publica o download. O canal só é ativado depois de baixar e conferir a release publicada. A assinatura é feita fora do repositório; a Action não recebe a chave privada. Preservar `/workspace/.prismavoz-signing/active` num backup privado durável é indispensável para futuras atualizações. Não gere outra chave para o mesmo pacote instalado.

## Desenvolvimento

Requisitos: JDK 17 ou 21 (com `javac`), Android SDK plataforma 35 e build-tools 35.0.0, Python 3 e Node 22. Bibliotecas locais são verificadas por SHA-256 e extraídas de `dependencies/`; não há CDN durante uso. Licenças em `assets/THIRD-PARTY-NOTICES.txt` e nos arquivos distribuídos.

```sh
python3 PrismaVoz/tools/vendor.py
node PrismaVoz/tools/test_speech.cjs
node PrismaVoz/tools/test_ocr.cjs
npm install --prefix /tmp/prismavoz-ui playwright@1.56.1 pdf-lib@1.17.1
PRISMA_NODE_MODULES=/tmp/prismavoz-ui/node_modules CHROME_BIN=/usr/bin/chromium node PrismaVoz/tools/browser_test.cjs
ANDROID_HOME=/caminho/android-sdk bash PrismaVoz/build.sh verify
```

No ambiente privado que contém a assinatura:

```sh
python3 PrismaVoz/tools/sign_local.py --tools "$ANDROID_HOME/build-tools/35.0.0" --input PrismaVoz/build/aligned.apk --output PrismaVoz/build/Prisma-Voz.apk
python3 PrismaVoz/tools/package_release.py --tools "$ANDROID_HOME/build-tools/35.0.0"
```

Nunca publique a pasta privada, a chave ou suas credenciais. Para uma nova versão, aumente `versionCode` e `versionName`, compile, teste, assine com a mesma chave e atualize as partes e metadados de distribuição. Não substitua uma release existente.

## Validação e limites

Testes de núcleo e navegador cobrem divisão segura de texto/Unicode, PDFs reais, seleção de vozes e autorização online com ponte Android simulada, controles de pausa/continuação/parada, cancelamento antes de iniciar áudio, acompanhamento da página, OCR português real em PDF de imagem, layout em 320–700px, fonte ampliada, tema e ausência de destinos externos durante OCR. Compilação Android e integridade/assinatura do APK são verificadas separadamente.

Esses testes não executam o motor TTS nem comprovam emissão de áudio, notificações, foco de áudio, tela apagada ou instalação/atualização em aparelho. Validar no Android: voz instalada e ausente; dados offline; autorização online; começo/fim/pausa/continuação; chamada telefônica e outro app de áudio; tela bloqueada; notificação permitida/negada; PDF grande; OCR; encerramento da tarefa; atualização com a mesma assinatura preservando preferências.

## Versão 1.1.0

Extração por coordenadas une fragmentos de uma mesma palavra, ordena linhas e identifica duas colunas simples quando há um vão central sustentado; linhas que cruzam as colunas delimitam blocos. Escrita vertical, RTL e glifos rotacionados preservam a ordem original do PDF. Quebras artificiais são unidas, ligaturas comuns normalizadas, hífens explícitos e valores numéricos preservados. Layouts complexos, fórmulas e tabelas podem continuar fora da ordem esperada.

O OCR sensível usa média local em memória limitada, escolhe candidatos por confiança/conteúdo e não altera o PDF. As tentativas extras só ocorrem em resultados fracos. Recortes inclinados recebem margem para não perder bordas. Reconhecimento de manuscritos, texto borrado e detalhes que não existem na imagem não é garantido.

Validação adicional: núcleo de extração com fragmentos, duas colunas e números; limiar adaptativo comparado pixel a pixel com uma implementação de referência; deskew sintético; OCR real em letras pequenas/claras, fundo irregular e inclinação, inclusive quando já existe um cabeçalho selecionável. A continuação por palavra exige teste prático com o motor TTS do aparelho.

### Versão 1.1.1

Preserva as melhorias da 1.1.0 e acomoda os controles de OCR em linhas inteiras para fonte ampliada, com teste de conteúdo dentro dos limites de cada rótulo.

## Candidata 1.2.0 — revisão de segurança

Mantém o atualizador interno, conforme preferência do proprietário. PDF.js atualizado para 4.10.38, com integridade do pacote oficial registrada em `dependencies/provenance.json`. O bundle legado e pdf-lib não utilizado foram retirados do runtime. CMaps e fontes são locais. O leitor usa CSP sem autorização de eval JavaScript; a autorização de compilação WebAssembly é restrita às bibliotecas locais de OCR. Safe Browsing permanece ativo. O seletor nativo entrega apenas o PDF escolhido pelo usuário, sem acesso WebView a arquivos ou provedores de conteúdo. O provedor do atualizador aceita somente leitura do APK verificado.

A branch `prismavoz/security-review` executa validação, mas não publica nem ativa o canal de atualização. O bloqueio informado pelo Play Protect ainda não teve causa confirmada nem liberação do Google. Não desative a proteção nem force instalação com o alerta ativo. A auditoria de dependências, os testes e a assinatura não substituem o veredito do Play Protect.
