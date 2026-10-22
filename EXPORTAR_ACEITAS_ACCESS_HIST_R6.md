# Excel das férias aceitas para colagem no Access — HIST-R6

Em Lançamentos → Relatórios → Exportar aceitas para Access (Excel), escolha o destino do arquivo XLSX. Não é necessário ter Excel instalado para gerar o arquivo.

A aba Colar_Access contém 13 campos, na ordem da tabela apresentada, a partir de Codigo do Servidor até Processo_20Dias. ID_Ferias é omitido porque é autonumeração. Copie os dados sem o cabeçalho e cole em novas linhas do Access, começando na coluna Codigo do Servidor. Não selecione a coluna ID_Ferias. Repita a colagem somente se tiver conferido que os registros ainda não existem no Access: a exportação não consulta esse banco para evitar duplicatas já existentes nele.

Mapeamento:

- Codigo do Servidor: CP, encontrado por matrícula exata nos registros e no histórico. CP ausente, inválido ou divergente vai para Pendencias.
- Observação: observações do período aquisitivo; textos acima de 255 caracteres vão para Pendencias, sem truncamento silencioso.
- Periodo Aquisitivo_1 e _2: início e fim do aquisitivo.
- Agendar Após: fim do aquisitivo + 2 dias.
- Ferias_30_Inicio/Final: intervalo aceito de 30 dias; também recebe o intervalo de FR de 20 dias em uma linha independente com Processo_20Dias marcado.
- Ferias_Par_1QIn/1QFin/2QIn/2QFin: as duas parcelas aceitas de 15 dias, inclusive se ocorrerem em anos diferentes.
- Programacao_Ano: número zero formatado como 0000; preencher manualmente antes da colagem.
- Processo_20Dias: -1 = Sim (caixa marcada no Access); 0 = Não.

A exportação considera toda a base, independente dos filtros da lista, e somente decisões de aceite explícitas. A partir de HIST-R10, todas as férias fixas/bloqueadas são excluídas, mesmo com aceite marcado. Outros aquisitivos não fixos do mesmo servidor continuam elegíveis. Opções pendentes não entram. Modalidade comum e FR são independentes: uma pendência da modalidade comum não remove uma FR aceita e válida. Linhas idênticas são deduplicadas; registros aceitos divergentes com mesmo CP/aquisitivo/modalidade vão para Pendencias.

As abas Pendencias e Instrucoes não devem ser coladas na tabela. O arquivo contém datas e números tipados, células vazias para campos sem uso e textos literais, sem fórmulas ou macros. Esta função não grava no Access nem altera Dados/Backups.

Validação independente com openpyxl: pacote XLSX abre com três abas, cabeçalhos corretos, datas reais, ano com formato 0000 e flags numéricas. Na cópia original enviada, a exportação produziu 54 linhas de colagem e 123 pendências por CP ausente. Essas quantidades não representam necessariamente a base atual do usuário. Testes sintéticos cobrem aprovações, CPs, 30 dias, 15+15, FR, dados inválidos, duplicatas e conflitos. A execução da interface e a colagem efetiva no Access precisam de validação no Windows, que não está disponível no executor Linux.
