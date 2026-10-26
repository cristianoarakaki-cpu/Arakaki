# Folha PDF+ — canal oficial e base recuperada 1.9.3

Aplicativo Android `com.folha.pd2`, versão **1.9.3**, versionCode **15**, Android 8 ou superior. Este diretório continua o APK enviado pelo proprietário, sem substituí-lo pelo protótipo PDF Fluxo. O canal Folha original (`com.folha.pdf`) continua separado.

## Instalar e atualizar

O APK assinado é publicado na release `folha-vplus1.9.3`, com o nome `Folha-PDF.apk` exigido pelo atualizador instalado. O canal consultado pelo app é `FPlus/update.json`. Após instalação, use **Atualizações → Verificar atualizações agora**. A consulta automática depende da opção ativada no menu nativo, da abertura do app e de conexão à internet. O Android exige confirmação para instalar: não há instalação silenciosa. Não desinstale para atualizar se quiser preservar a biblioteca local.

Conversões e OCR usam arquivos locais, incluindo modelos em português, inglês e espanhol. Consultas e downloads de novas versões precisam de internet; os documentos não precisam ser enviados para atualizar.

## Publicação automática

A Action **Publicar Folha PDF Plus** é acionada por alterações em `distribution/`, `release.json`, ferramentas de publicação ou no workflow. Ela:

1. Reúne o APK original a partir das partes e verifica tamanho e SHA-256 de todas as partes e do APK.
2. Usa `apksigner` e `aapt` para verificar assinatura, certificado original, pacote, versionCode e versionName.
3. Publica o APK em uma release, sem sobrescrever uma release pública existente.
4. Baixa novamente o APK publicado, confere SHA-256 e só então atualiza `FPlus/update.json`, recusando regressão de versão.

`release.json` é a entrada de publicação. `update.json` é a saída do canal e não deve anunciar um download antes de a release existir. O canal do Folha original e o aplicativo Onda não são alterados por este fluxo.

Para uma próxima versão, compile e assine com **a mesma chave privada** do aplicativo instalado, aumente versionCode e versionName e atualize todas as partes, `parts.json` e `release.json` no mesmo commit. A automação distribui um APK já assinado; não inventa alterações no app nem gera a chave original. Se o certificado mudar, a publicação é recusada. Nunca coloque keystores ou senhas no Git.

## Conteúdo recuperado e limites

- `distribution/`: preservação exata do APK recebido, dividido em partes binárias.
- `source/assets/`: JavaScript, HTML e CSS próprios recuperados do APK, sem modificações funcionais.
- Bibliotecas e modelos completos permanecem dentro do APK preservado. Execute `python3 FPlus/tools/extract_vendor.py` para extraí-los localmente.
- `apk-analysis.json`: metadados do manifesto, hash e certificado extraído.
- Os arquivos Java originais **desta edição Plus** e a chave privada não vieram no APK e não foram recuperados. `Folha/source` pertence à edição original e não equivale ao código nativo desta versão. Portanto esta base não é apresentada como um projeto Android integralmente recompilável.

## Análise estática

O APK contém biblioteca local com pesquisa e visualização, OCR, juntar/extrair/excluir/dividir páginas, conversão para imagens e texto/Word, rotação, rodapé, otimização estrutural, boletos e ocultação de dados pessoais com regras personalizadas. OCR pode errar; Word extrai texto sem preservar layout completo. A detecção de dados pessoais exige revisão e não certifica conformidade com a LGPD.

A ocultação gera páginas rasterizadas sem objetos/textos originais; perde pesquisa, links, formulários e assinaturas digitais. O código de entrada limita tamanho, extensão, assinatura de arquivo e duplicação.

Alguns textos do atualizador nativo ainda mencionam **1.5.0**, embora o manifesto instalado declare **1.9.3**; a interface usa substituições para exibir a versão atual. Isso deve ser corrigido no código nativo numa próxima compilação. O canal anterior do repositório estava em 1.4.1, sem download. Esta publicação preserva o APK original; não corrige esses textos dentro do binário.

Verificações locais: estrutura ZIP, hashes, metadados binários do manifesto, certificado e sintaxe dos scripts próprios. A verificação criptográfica completa é executada por `apksigner` na Action antes de publicar. Não foi feito teste em aparelho Android nem validação jurídica de LGPD.
