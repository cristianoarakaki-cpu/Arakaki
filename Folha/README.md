# Folha PDF para Android

OCR offline em português, inglês e espanhol; imagens para PDF; junção; extração; PDF para texto; girar páginas; PDF para JPG; nome personalizado e compartilhamento.

A partir da versão 1.1.0, o app verifica `Folha/update.json` neste repositório ao abrir, no máximo a cada seis horas. O menu Atualizações permite verificar imediatamente ou desativar a consulta automática. Apenas informações de versão são consultadas; documentos não são enviados. O download exige ação do usuário e a instalação exige confirmação do Android. Antes da instalação, o app verifica SHA-256, pacote, versão e certificado de assinatura. As releases usam tags `folha-v*`; Onda usa seu próprio canal.

Requer Android 8 ou superior e Android System WebView atualizado. Documentos grandes podem exceder a memória do celular. PDFs com senha devem ser desbloqueados previamente. PDF para JPG limitado a 30 páginas por operação. Arquivos compartilhados permanecem no cache privado do app até limpeza dos dados/cache pelo Android.

## Publicação

`distribution/` contém partes do APK já assinado localmente. A Action `Publicar Folha PDF` reúne as partes, verifica SHA-256 e assinatura e publica `Folha-PDF.apk` e `folha-update.json` na release. A chave privada de assinatura fica fora do repositório. A Action não compila nem assina APKs e não altera releases já publicadas. Para uma versão nova, compile e assine localmente com a mesma chave, aumente versionCode/versionName, substitua todas as partes e atualize update.json no mesmo commit. Não reutilize tags de versões existentes.

`source/` contém os arquivos próprios do aplicativo e um script para baixar as dependências versionadas. Bibliotecas: pdf-lib 1.17.1 (MIT), PDF.js 3.11.174, Tesseract.js 5.1.1 e tesseract.js-core 5.1.1 (Apache-2.0); modelos @tesseract.js-data 1.0.0.

OCR mantém a imagem da página com texto invisível, sem preservar vetores, links ou formulários. Revise o texto reconhecido quando precisar de precisão.
