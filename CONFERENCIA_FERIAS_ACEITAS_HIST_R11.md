# Conferência de férias aceitas — HIST-R11

Na janela de conferência, o seletor Opção agora contém Férias aceitas, além de 1ª, 2ª e 3ª opções. Ao escolher Férias aceitas, o tipo de análise passa a Programacao aprovada e fica desabilitado enquanto esse modo estiver selecionado. As modalidades comum e FR usam suas respectivas opções aceitas, independentemente. Pendentes não são contados. As férias fixas permanecem como compromissos do planejamento final.

Nesse modo, Equiv. base aceita e Saldo aprovado usam toda a base relida, com a regra institucional existente: limite mensal menos equivalentes confirmados, considerando fixas, parcelas de 15 dias, FR e deduplicação por servidor/aquisitivo. Setor, período e pesquisa filtram as quantidades e os detalhes, sem aumentar artificialmente o saldo institucional. O tipo de análise Programacao aprovada também recebe esse comportamento, mesmo com 1ª/2ª/3ª opção no seletor. As análises de solicitações e pendências continuam disponíveis.

A nova coluna Conflitos no setor vem marcada e integra CSV e Visualizar/PDF. Informa o outro servidor, matrícula, turno e datas da coincidência, limitadas ao ano/mês selecionado. A busca nominal e o filtro de modalidade não ocultam os participantes usados na detecção: são verificadas as férias confirmadas de toda a base. A coluna mostra conflitos dos compromissos do registro, inclusive comum/FR/fixas.

O cálculo de intervalos e a classificação são compartilhados com o relatório existente, inclusive quando o grupo de participantes muda no meio das férias: matrículas diferentes com datas coincidentes no mesmo setor geram ATENCAO; turno conhecido e igual gera CRITICO. Turno desconhecido não torna o conflito crítico. Coincidências são informativas e não alteram aprovações. A célula fica amarela para atenção e vermelha para crítico, com o texto completo no tooltip.

Para instalar, feche o aplicativo e substitua somente FeriasDCE.ps1. Preserve Dados/Backups e o JSON atual. A alteração não modifica cadastros nem períodos. As férias fixas continuam excluídas do Excel específico de colagem no Access; essa exportação é independente do resumo de ocupação da conferência.

Validação: testes executam o trecho real de cálculo do callback sem interface e verificam opção aceita distinta da solicitada, FR independente, fixas, pesos, saldo sem pendentes, filtros, duplicação, conflitos, limites inclusivos, virada do ano e preservação da base. WinForms e impressão no Windows precisam de validação local.
