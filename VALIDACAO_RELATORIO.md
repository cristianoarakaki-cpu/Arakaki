# Relatório de coincidências — V1.0.135-R2

## Atualização

Faça backup e substitua somente `FeriasDCE.ps1` na pasta onde o sistema já está instalado. Preserve Dados, Backups, launcher e demais auxiliares. Gere novamente o relatório de conflitos pelo aplicativo para usar o novo layout.

O ZIP contém também `Exemplo_relatorio_conflitos.html` e `Previa_relatorio_conflitos.png`, ambos com dados fictícios. O HTML pode ser aberto no navegador para experimentar busca, filtros e impressão sem iniciar o aplicativo.

## Melhorias

- Ícones SVG embutidos para calendário, servidores, turnos, gravidade, confirmação, pendências, busca, limpeza e impressão. Não dependem de internet nem de fontes externas. Os ícones acompanham rótulos de texto.
- Nomes, matrículas, turnos e períodos separados para facilitar a leitura.
- Explicação do motivo de cada classificação. Coincidências em turnos diferentes continuam como Atenção; datas e critérios de classificação foram preservados.
- Busca sem distinção entre maiúsculas/minúsculas e acentos, filtros combináveis de classificação e situação e mensagem de ausência de resultados.
- Totais dos cartões representam o relatório completo; a contagem de resultados e o texto de filtros explicam o recorte. A impressão respeita os filtros.
- Impressão A4 horizontal com cabeçalho repetido das tabelas, ícones e espaçamento compacto; layout de tela adaptado a celular.

## Validações executadas

SHA-256 do script validado: `b4abe709d2f6043aacb078539307c62a68076daf710f3de5d09145b581339f7e`.

Parser PowerShell: sem erros. Dez grupos de regressão de funções executados em uma rodada, com 10 aprovados e zero falhas: sintaxe, FR isolada, datas/duração/sobreposição, legado e contagem FR, resets, classificação/recomendação, simultaneidade e calendário, estrutura JSON/inicialização, commit atômico e Save/backup/lock/conflito entre instâncias.

Comparação entre os geradores R1 e R2 com 14 cenários sintéticos (28 HTMLs gerados): classificação, situação, datas de coincidência, duração e quantidade de participantes idênticas. Totais dos cartões também conferidos.

```text
Calculo e totais preservados: todos (3 ocorrencias)
Calculo e totais preservados: sem-pendentes (2 ocorrencias)
Calculo e totais preservados: mesmo-turno (1 ocorrencias)
Calculo e totais preservados: entre-setores (2 ocorrencias)
Calculo e totais preservados: vazio (0 ocorrencias)
Calculo e totais preservados: um-servidor (0 ocorrencias)
Calculo e totais preservados: encontro-no-ultimo-dia (1 ocorrencias)
Calculo e totais preservados: dias-adjacentes (0 ocorrencias)
Calculo e totais preservados: tres-simultaneos (3 ocorrencias)
Calculo e totais preservados: matricula-duplicada (0 ocorrencias)
Calculo e totais preservados: turno-desconhecido (1 ocorrencias)
Calculo e totais preservados: desconhecido-filtro-mesmo-turno (0 ocorrencias)
Calculo e totais preservados: intersetor-ignora-mesmo-setor (0 ocorrencias)
Calculo e totais preservados: intersetor-mesma-matricula (0 ocorrencias)
Filtros por nome com acentos, classificacao, situacao e combinacoes: OK
Estado sem resultados e limpeza de filtros: OK
SVGs locais resolvidos e dimensionados: OK
Dados HTML escapados: OK
Impressao respeita filtros; PDFs gerados: OK
Layout desktop e celular sem overflow da pagina: OK
Erros JavaScript: zero
Renderizacao e filtros com navegador offline: OK
```

PDF completo e PDF filtrado gerados no Chromium e lidos para conferir o conteúdo: A4 horizontal, controles de busca/impressão ausentes no papel e registros ocultos pelos filtros ausentes no PDF. O conjunto de exemplo completo gerou duas páginas; uma ocorrência filtrada gerou uma página. A paginação varia conforme os dados.

A captura de tela e o PDF filtrado foram inspecionados visualmente. As matrículas e nomes do exemplo são fictícios. O teste de dados HTML incluiu texto contendo marcação de script e confirmou que permaneceu escapado, sem execução.

## Limites

Validação executada em PowerShell 7.4.6 e Chromium sobre Linux, com dados sintéticos. As funções e o corpo do evento de aprovação usam algumas dependências simuladas no verificador de regressão. A interface WinForms completa não foi executada em Windows PowerShell 5.1 nesta sessão. Planilhas de produção, acesso SMB real e integração com impressora física não foram testados. Não há garantia de ausência de todos os defeitos do aplicativo.
