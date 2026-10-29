# Prisma PDF — Android, offline primeiro

Aplicativo novo, com interface e implementação próprias. Pacote `com.arakaki.prismapdf`, separado dos apps Folha anteriores.

## Instalar sem cadastrar senha

[Baixar Prisma PDF 1.0.0](https://github.com/cristianoarakaki-cpu/Arakaki/releases/download/prisma-v1.0.0/Prisma-PDF.apk) · [Página da versão](https://github.com/cristianoarakaki-cpu/Arakaki/releases/tag/prisma-v1.0.0)

O Android pede autorização para instalar o APK. O usuário não precisa de conta no app, senha, GitHub Secrets ou chave de assinatura. A instalação em aparelho ainda deve ser validada pelo proprietário. O código, os testes em navegador e a compilação já foram verificados.

## Ferramentas locais

Leitor PDF com pesquisa; OCR em português, inglês e espanhol; boletos por texto, barras ITF e OCR com verificação de dígitos; juntar, extrair e girar páginas; otimizar estrutura; JPG/PNG para PDF; PDF para PNG e TXT. Salvamento e compartilhamento usam o Android. A biblioteca só guarda cópias quando o usuário toca Guardar.

Bibliotecas e modelos vêm no APK. Não há conta, telemetria, upload automático ou CDN durante o uso. Os arquivos não são enviados a um servidor para serem processados.

## Ações online opcionais

O controle Permitir ações online começa desligado. Quando ativado, permite importar PDFs de links HTTPS públicos e consultar/baixar novas versões no GitHub. O WebView bloqueia destinos externos; as requisições escolhidas pelo usuário usam a camada nativa. Não há conversão remota nem Word/Excel nesta versão.

## Assinatura e publicação sem secrets do usuário

O APK é assinado fora do repositório, com uma chave privada mantida em armazenamento protegido do ambiente de execução. A chave e a credencial gerada automaticamente não são incluídas no APK, no repositório ou em artifacts públicos. O certificado público está em `signing/certificate.sha256`.

A preservação dessa chave privada é indispensável para assinar versões futuras que atualizem a mesma instalação. O workspace privado não substitui um cofre durável ou um backup privado permanente; se esse ambiente for substituído sem preservar a chave, não será possível recriá-la a partir do APK. Não anuncie assinatura automática na nuvem: a Action de compilação apenas valida; a assinatura precisa ocorrer no ambiente que possui essa chave.

`distribution/` preserva o APK já assinado, dividido em partes com hashes. A Action **Publicar Prisma PDF assinado** reúne as partes, verifica SHA-256, assinatura, certificado fixado, alinhamento, pacote e versão, publica o arquivo e baixa novamente a release para conferir a integridade antes de atualizar `PrismaPDF/update.json`. Não substitui releases públicas existentes nem rebaixa versões. Não requer senha ou secret do usuário.

Para uma atualização, compile as mudanças, use `tools/sign_private_local.py` no ambiente privado que contém `/workspace/.prisma-signing/active` para assinar com a mesma chave privada, aumente versão/código e substitua todas as partes e os metadados de distribuição no mesmo commit. O app verifica pacote, versão, assinatura e hash antes de abrir o instalador. O Android solicita confirmação; não há instalação silenciosa.

Os scripts experimentais de chave criptografada permanecem como infraestrutura e testes, mas não são invocados pelas Actions ativas. Não gere outra chave para esta identidade. O fluxo anterior de PRISMA_SIGNING_PASSWORD foi retirado da automação de compilação.

## Desenvolvimento e dependências

JDK 17, Android SDK plataforma/build-tools 35, Python 3 e Node.js. `bash PrismaPDF/build.sh verify` valida uma compilação sem assinatura. `tools/vendor.py` reconstitui bibliotecas empacotadas e verifica todos os hashes, sem internet. Configure as ferramentas de desenvolvimento uma vez; o app usa os arquivos locais.

PDF-lib 1.17.1 (MIT), PDF.js 3.11.174, Tesseract.js/core 5.1.1 e modelos @tesseract.js-data por/eng/spa 1.0.0 (Apache-2.0). Os avisos completos acompanham o APK em `assets/THIRD-PARTY-NOTICES.txt` e os arquivos vendor. PDF.js usa sempre `isEvalSupported: false`.

## Limites e validação

Android 8+ com WebView atualizado. 25 MB por arquivo, 20 entradas e 60 MB no total; OCR/boletos até 12 páginas; PNG até 20 páginas. PDFs com senha devem ser desbloqueados antes. OCR pode errar e rasteriza páginas; revise o resultado. Regravar arquivos pode invalidar assinaturas digitais. Otimizar a estrutura não garante redução de tamanho.

A leitura de boletos não verifica autenticidade ou beneficiário. Confira os dados no banco antes de pagar. Barras ITF devem estar horizontais e nítidas. A biblioteca local é apagada ao desinstalar ou limpar os dados do app.

Passaram testes de regras, ITF sintético, operações PDF, leitor, busca, biblioteca e OCR português em navegador com solicitações externas bloqueadas, além da compilação Android. A importação HTTPS nativa real, a instalação e a atualização devem ser verificadas em aparelho.

## Versão 1.1.0

Três novas ferramentas locais: dividir até 20 páginas em PDFs individuais, numerar páginas com início entre 1 e 1.000.000 e aplicar marca d’água de texto com três intensidades. Todas aceitam seleção e ordem de páginas. Os originais não são sobrescritos. Numeração e marca consideram rotação e área visível (CropBox). Texto latino e pontuação são aceitos; emojis são recusados antes de produzir o arquivo. Uma marca visual não impede edição posterior.

## Versão 1.2.0

Remoção de páginas com seleção obrigatória e preservação de ao menos uma página; inserção de até 20 páginas em branco no início, fim ou entre páginas, em A4 retrato/paisagem e Carta. Consulta de dados básicos e limpeza do Info e XMP do catálogo: não é anonimização e não remove conteúdo, comentários, anexos ou metadados de páginas. Busca de ferramentas na tela inicial. Os resultados continuam sendo cópias que o usuário escolhe salvar.

## Versão 1.3.0

Modo claro, escuro ou conforme o sistema, com seletor em Sobre e atalho no cabeçalho. Preferência salva no aparelho, aplicada antes da renderização da interface e sincronizada às barras Android. O PDF conserva as cores originais. Favoritas locais por ferramenta, filtro e busca sem acentos. Leitor com zoom de ajuste à largura até 200% e salto para página validado. PDFs e biblioteca não são enviados à rede.
