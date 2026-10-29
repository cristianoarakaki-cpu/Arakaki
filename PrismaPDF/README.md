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

## Versão 1.3.1

Correção de texto saindo dos botões: cartões em duas colunas no celular (uma em telas até 340px), títulos e descrições com quebra segura e crescimento vertical. Alinhamento no topo e espaço próprio para favoritas. Cabeçalho adaptável e margem inferior calculada pela altura real da navegação. Validação visual com larguras de 320 a 960px e simulação de fonte ampliada de 100% a 200%.

## Versão 1.4.0 — Ocultar dados

Análise local de até 12 páginas, com texto + OCR (padrão) ou só texto selecionável. Detecta possíveis CPF/RG/CNPJ, e-mails, telefones, CEP, nomes por campos e heurística, registros CRM/Coren/CRO/CRP/CREA/OAB e outros. Termos personalizados (até 100, um por linha) permitem localizar nomes, registros ou expressões específicas sem diferenciar acentos e maiúsculas. Sem lista de termos persistente nem upload. Nomes encontrados em campos são procurados nas outras páginas. Números são candidatos mesmo com checksum inválido: possíveis erros de OCR também exigem revisão.

Revisão por página com lista selecionável, prévia e retângulos manuais. Geração exige visualizar todas as páginas e confirmar a revisão; nenhum resultado é criado na análise. A cópia é um PDF novo somente com PNGs dos pixels já cobertos de preto, sem copiar páginas, texto, Info/XMP, formulários, anexos ou assinaturas do original. Não existe opção de retângulo reversível sobre o PDF original. O original permanece no aparelho; resultados só são salvos ou compartilhados quando solicitados.

Limitações: a detecção é heurística e pode omitir dados ou ter falsos positivos; imagens, escrita à mão, conteúdo mal posicionado, nomes sem padrão, QR codes e contexto exigem revisão. Texto/PDF e OCR podem reconhecer os mesmos dados e gerar marcações sobrepostas. Para evitar expor letras de um mesmo objeto textual, a máscara automática cobre o item/trecho inteiro que intersecta o dado; pode esconder conteúdo além do necessário. A cópia rasterizada perde pesquisa, acessibilidade textual, formulários e validade de assinaturas digitais. O recurso auxilia a minimização de dados, mas não certifica conformidade com a LGPD nem anonimização do documento.

## Versão 1.5.0 — Interfaces

Galeria em Sobre → Aparência, com atalho Escolher interface na tela inicial. Estilos Prisma, Neon, Aurora, Terminal e Essencial: variações de cores, bordas, fundos, tipografia e apresentação das ferramentas (cartões ou listas). Aplicação imediata, opção de restaurar Prisma e preferência local independente do modo claro/escuro/automático. Não afeta documentos, cores de PDFs, marcações de ocultação nem recursos offline. Todos os recursos visuais são arquivos locais, sem fontes, imagens ou estilos remotos.

## Versão 1.6.0 — Conferência da cópia final

Após gerar o PDF ocultado, o app reabre os bytes da cópia final e executa OCR offline em cada página. Procura as categorias escolhidas, os termos adicionais e os valores das marcações selecionadas. Alerta por página sem exibir os valores no resumo. Verifica também a ausência de texto, anexos/catálogo Names, formulários, XMP e anotações na cópia produzida.

Sem achados: disponibiliza o resultado com aviso de limitações do OCR. Com achados: permite voltar à página e acrescentar marcações ou disponibilizar a cópia com alertas após confirmação explícita; o estado no resumo não muda. Falha/interrupção: mostra conferência incompleta, bloqueia a disponibilização e permite repetir. Alterações nas marcações invalidam a conferência e retiram resultados anteriores.

Resumo opcional TXT: versão, data UTC, SHA-256 do PDF de saída, contagens de páginas/marcações e categorias de alertas, sem nomes, documentos, termos pesquisados ou nome do arquivo original. Não é certificado de anonimização ou de LGPD. Nenhum alerta significa apenas que o OCR não reconheceu os padrões procurados.

## Versão 1.7.0 — OCR reforçado

Módulo OCR compartilhado por PDF pesquisável, boletos, ocultação e conferência. Imagens pequenas são ampliadas em até 2× e limitadas a 2600px no maior lado; renderização de PDFs para OCR passa a até 2600px. Giro manual para reconhecimento (0/90/180/270) com caixas mapeadas de volta à imagem original. Modo reforçado (padrão) faz duas leituras: original e luminância com contraste por percentis, sem binarização agressiva. Se a primeira leitura é vazia ou de baixa confiança, a segunda tenta segmentação de texto esparso. Modo rápido mantém uma leitura.

PDF pesquisável escolhe uma leitura com critérios de confiança e cobertura, apresenta índices e texto para conferência/exportação TXT. Os índices do mecanismo não são taxas reais de acerto. A aparência original é preservada. Nenhuma substituição automática O/0/I/1 é feita. Boletos continuam passando por verificadores. Ocultação procura candidatos em ambas as leituras, sem descartar palavras de baixa confiança. A conferência sempre usa duas leituras, mantém achados de qualquer uma, deduplica ocorrências equivalentes entre passagens e sinaliza divergência/baixa confiança por página no resumo sem expor palavras.

Limitações: preparação e seleção são heurísticas; fotos desfocadas, sombras, escrita à mão e inclinação ainda podem exigir nova captura e revisão. Giro é manual, sem modelo de orientação adicional. Recursos e modelos continuam totalmente locais.
