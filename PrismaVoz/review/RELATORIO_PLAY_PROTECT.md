# Prisma Voz — revisão do alerta Play Protect

Data: 06/11/2026. Pacote: `com.arakaki.prismavoz`.

**O bloqueio não teve causa confirmada e não há confirmação de liberação pelo Google.** Os testes abaixo não são um laudo de antivírus. Não desative o Play Protect nem force instalação para testar.

## Arquivos examinados

- APK público 1.1.1: `https://github.com/cristianoarakaki-cpu/Arakaki/releases/download/prismavoz-v1.1.1/Prisma-Voz.apk`.
- SHA-256 do APK público conferido: `9d8220ca9428cca727ce982194339cc5e7aab6d1a5810d3880a3fe254a64912e`.
- SHA-256 do certificado preservado: `76a281f5ca3a25a42e490f2926482d63d597ba51ab48f24c2a1379258b14f7e1`.
- Candidata corrigida 1.2.0: SHA-256 `5b9ad37c3dbc49e17ed3b534189e302bfb3cae80550502591cc0d16998a03b85`; versionCode `4`; mesma assinatura e pacote.
- Arquivo local da candidata: `/workspace/Prisma-Voz-1.2.0-REVISAO.apk`.

A imagem fornecida mostra “App nocivo bloqueado”, mas não identifica versão, hash ou categoria da detecção. O arquivo exato que acionou o aviso no aparelho não foi fornecido. A correspondência confirmada é entre o APK público 1.1.1, os hashes do repositório e a assinatura fixada.

## Achados e correções

1. O runtime antigo trazia PDF.js 3.11.174, dentro da faixa afetada por CVE-2024-4367. O aplicativo já passava `isEvalSupported:false`, mitigação documentada pelo próprio fabricante. Ainda assim, o runtime foi substituído por PDF.js 4.10.38, versão posterior à correção 4.2.67. Integridade do tarball oficial npm conferida por SHA-512; arquivos de runtime fixados por SHA-256. O bundle legado foi removido, não apenas renomeado.
2. O leitor passou a aplicar Content Security Policy que bloqueia scripts inline/eval JavaScript, frames externos, objetos e envio de formulários. Compilação WebAssembly continua autorizada somente para permitir o OCR local. CMaps, fontes e modelos são empacotados no APK.
3. Safe Browsing permanece explicitamente ativo. Acesso WebView a arquivos e content providers foi desativado; o PDF escolhido é recebido pelo seletor nativo e entregue como dados ao leitor. A ponte de prontidão evita perder documentos abertos durante a inicialização.
4. O provedor de arquivos do atualizador agora só permite leitura do caminho fixo do APK verificado. Código legado de captura/escrita foi retirado.
5. A escolha do proprietário foi preservada: verificação, download e atualização dentro do app. `REQUEST_INSTALL_PACKAGES` continua declarada por esse motivo. Hash, pacote, versão, assinatura e confirmação do Android continuam obrigatórios. Não foi feita troca de identidade ou de assinatura para contornar a classificação.

O inventário do APK antigo contém somente INTERNET, ACCESS_NETWORK_STATE, FOREGROUND_SERVICE, FOREGROUND_SERVICE_MEDIA_PLAYBACK, POST_NOTIFICATIONS, WAKE_LOCK e REQUEST_INSTALL_PACKAGES. Nenhuma permissão de SMS, contatos, microfone, localização, acessibilidade, administração do dispositivo ou acesso amplo ao armazenamento foi encontrada no manifesto analisado. Isso descreve permissões; não prova ausência de comportamento nocivo.

## Testes e limites

- Assinatura e integridade do APK público verificadas; candidata compilada e assinada com a mesma chave.
- 5 verificações de fronteiras de segurança aprovadas, além das suítes de leitura/OCR.
- PDFs reais, extração, OCR português real em imagens claras/inclinadas, pausa/continuação com ponte Android simulada, cancelamento e interface pequena/ampliada passaram no navegador.
- PDF de teste com JavaScript em OpenAction não executou a ação; nome de arquivo contendo HTML foi exibido como texto; CSP bloqueou tentativa de script inline e frame externo.
- Durante os testes offline não houve destinos externos nem erros JavaScript não tratados.
- Consulta `npm audit` da árvore de dependências escolhida após a atualização: zero vulnerabilidades conhecidas retornadas. A árvore antiga também incluía alertas em ferramentas Node não distribuídas no APK; não foram classificados como falhas do runtime Android. Uma consulta de advisories não é um scanner de malware nem uma auditoria completa do produto.

Não foram executados antivírus externo, análise dinâmica do APK em aparelho, teste real do serviço TTS/instalador nem avaliação pelo Google Play Protect. O motivo da classificação do Google não está disponível nesta sessão. Nenhuma alegação de falso positivo confirmado ou de segurança absoluta é feita.

## Próximo passo externo

Há um rascunho em `PEDIDO_REVISAO_GOOGLE.txt`. A revisão deve ser encaminhada ao Google pelo responsável pelo aplicativo, com o APK/link e a tela do bloqueio. Formulário de referência: `https://support.google.com/googleplay/android-developer/contact/protectappeals`.

Os endereços oficiais Google consultados retornaram HTTP 403 nesta rede; não foi possível ler o formulário atual nem submeter uma solicitação. O advisory do fabricante foi lido em `https://github.com/mozilla/pdf.js/security/advisories/GHSA-wgrm-67xf-hhpq`.

A candidata está separada na branch `prismavoz/security-review`. A validação dessa branch não publica releases nem ativa atualização automática. O canal publicado não foi declarado liberado pelo Play Protect. Qualquer nova distribuição deve preservar os hashes e a assinatura e ser reavaliada diante do alerta.
