# CP obrigatório no cadastro — HIST-R8

A tela Dados do servidor passa a exibir CP obrigatório ao lado da matrícula. O CP pode ser informado e corrigido; Salvar cadastro o propaga a todos os períodos aquisitivos daquela matrícula. Salvar opções também valida e propaga o CP. A matrícula permanece como chave principal e não é alterada pelo CP.

Novo servidor possui o mesmo campo obrigatório. Ao adicionar novo aquisitivo para uma matrícula existente, o construtor herda o CP disponível. Ausência ou divergência impede criar pelo construtor um novo registro sem CP. Bases antigas são carregadas sem excluir registros; é necessário completar o CP para salvar pelo editor.

Validação: número inteiro positivo até 2147483647, sem letras, sinal, decimais ou notação científica. CPs numericamente iguais, inclusive escritos com zeros redundantes, não podem pertencer a matrículas distintas. CPs divergentes entre aquisitivos aparecem como pendência no editor, sem selecionar arbitrariamente um deles. O usuário informa o correto e salva para uniformizar os períodos.

Cadastro em lote recebe CP obrigatório como quinta coluna da entrada: Matrícula | Nome | Setor | Período | CP. As quatro posições anteriores foram preservadas. Linhas sem CP, matrículas repetidas e CPs repetidos são rejeitados na validação antes de processar. O grid exibe uma coluna própria para completar o CP.

A exportação para Access passa a dar prioridade ao CP do cadastro atual; o histórico é consultado apenas quando não há CP no cadastro. Assim, corrigir o CP no cadastro não gera falso conflito com um CP antigo do relatório histórico. O histórico original não é reescrito, e divergências entre CPs atuais continuam bloqueadas na exportação.

A conferência de duplicidade usa uma passagem pelos registros e outra pelo histórico para evitar pesquisas aninhadas no lote. Uma medição sobre a cópia corrigida de 237 registros passou de aproximadamente 1098 ms para 28 ms por validação neste executor; esses tempos não estimam o desempenho no Windows do usuário.

CadastroCP.ps1 contém 32 verificações, incluindo as funções reais Salvar cadastro e Salvar opções com controles simulados, bloqueio sem mutação para CP vazio, preservação das outras matrículas e campos, herança no aquisitivo, lote e prioridade do cadastro atual sobre o histórico. Os testes de exportação Access foram atualizados para a nova regra explícita, preservando o teste de bloqueio quando há CPs atuais divergentes.

A interface WinForms e a execução integral em Windows PowerShell 5.1 precisam de validação no Windows. Nenhuma base de dados pessoal integra esta entrega.
