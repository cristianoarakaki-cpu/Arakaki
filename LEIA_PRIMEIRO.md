# Cabeçalho dos formulários HTML — Escala Mensal V83 R1

MÊS/ANO fica acima do valor, com mês e ano separados por espaços em torno da barra. O título do responsável fica acima do nome, qualquer que seja o título configurado (diretoria, gerência, coordenação ou chefia). O nome e o título continuam sendo obtidos do cadastro de assinaturas, com a prioridade existente por setor, setor pai e geral e o fallback original para a chefia do setor. Valores continuam escapados para HTML.

A alteração é somente visual: duas linhas do HTML e duas regras CSS no gerador compartilhado de prévias individuais e combinadas. O valor usa uma linha própria sem quebra automática. Não há alterações em banco de dados, servidores ou assinaturas.

Instalação: feche o sistema, substitua somente Aplicativo_Escala.ps1 na pasta atual e abra novamente. Preserve Dados e Backups. Gere novamente a prévia/formulário; os HTMLs já salvos não são reescritos.

Verificação: sintaxe PowerShell validada por AST. As instruções reais do gerador foram executadas para quatro títulos, incluindo caracteres especiais. As prévias foram renderizadas no Chromium nos modos tela e impressão; foram verificadas a posição do nome abaixo do título e ausência de quebra nos valores apresentados. Foi gerado PDF para conferência. A aplicação WinForms não foi executada no Linux. Não foram incluídos banco de dados nem relatórios pessoais nesta entrega pública.
