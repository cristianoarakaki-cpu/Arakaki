# Conferência de CP no cadastro — HIST-R9

Em Lançamentos, o seletor Conferência CP oferece TODOS, COM PROBLEMA, SEM CP, CP INCOMPLETO, CP INVÁLIDO, CP REPETIDO, CPs DIVERGENTES e CP OK. A conferência agrupa por matrícula, que continua sendo a chave principal. SEM CP indica todos os registros sem CP; CP INCOMPLETO indica que apenas alguns aquisitivos dessa matrícula estão preenchidos. Um servidor pode apresentar mais de um problema e ser encontrado por cada categoria correspondente.

CP válido é inteiro positivo de até 2147483647. A comparação de CP usa o número normalizado, evitando falsos conflitos por zeros redundantes. CP REPETIDO exige uso por matrículas distintas; repetição entre aquisitivos do mesmo servidor é esperada. CPs DIVERGENTES identifica números diferentes nos registros da mesma matrícula. CP histórico não mascara lacunas no cadastro atual.

A coluna CP mostra os valores cadastrados, com destaque nas células problemáticas. O motivo completo está na dica ao passar o mouse. O editor também mostra o diagnóstico. O rodapé informa o total de servidores com problema na base inteira, enquanto a lista combina esse filtro com os filtros anteriores. Limpar filtros restaura TODOS. Um filtro CP sem resultados limpa o editor para evitar que ele continue mostrando um servidor oculto.

A interface conserva a altura compacta do painel anterior: os seletores da terceira linha compartilham o espaço, com listas suspensas mais largas para os textos completos. A conferência é calculada a cada atualização da lista, sem modificar registros, datas, decisões ou configuração persistente.

Os arquivos pessoais da base, planilha e relatórios de conferência foram tratados em diretório separado e não integram o repositório. Na cópia recebida foram identificados 122 servidores sem CP em todos os registros e 52 com preenchimento parcial. Após atualização por matrícula exata a partir da planilha autorizada, a conferência da cópia corrigida apontou 178 servidores e zero problemas de CP. A comparação estrutural preservou todos os outros campos dos 237 registros e os demais dados da base, alterando apenas nome, cp_relatorio e os metadados de revisão/gravação.

A exportação da cópia corrigida para Access produziu 177 linhas aceitas e nenhuma pendência. A planilha resultante foi verificada com openpyxl para ordem das colunas, tipos numéricos, datas, ano 0000 e ausência de fórmulas. A colagem real no Access e o funcionamento visual da interface ainda exigem validação no Windows.

FiltroCP.ps1 contém 29 verificações, incluindo a execução do Refresh-Grid real com grade simulada. A regressão completa foi executada em 20 rodadas e cinco culturas, com 8469 verificações aprovadas. Isso não representa 20 auditorias manuais independentes do projeto.
