# Conferência de identidade HIST-R3

A prévia compara o nome extraído da coluna C do relatório com os nomes dos registros locais de mesma matrícula. A comparação ignora acentos e caixa, mas exige as demais palavras iguais. Nomes abreviados ou com partículas diferentes podem provocar aviso; o aviso não determina qual origem está correta.

A tela passa a mostrar nome da planilha e do cadastro lado a lado, linha de origem, detalhes completos copiáveis e filtro de nomes divergentes. O CSV de não importados também contém o nome cadastrado e a matrícula encontrada. Matrícula encontrada para diagnóstico não autoriza importação: divergências continuam sem vínculo automático. Nenhum nome ou dado operacional é alterado por essa melhoria.

Validação: análise sintática sem erros; Rodada.ps1 seed 2026 pt-BR com base real original, 316 verificações aprovadas; Identidade.ps1 com oito verificações aprovadas, incluindo bloqueio da divergência, nome equivalente aceito e exportação CSV. Interface WinForms requer validação visual no Windows.
