# Correção da falsa pendência de duração — HIST-R13

O período 15/02/2027 a 16/03/2027 soma 30 dias inclusivos e é válido para a opção aceita de 30 dias. O defeito estava na coleta dos intervalos do exportador.

A atribuição antiga usava `$blocks=if(...){@(Get-Blocos...)}else{@(Get-Bloco...)}`. O if enumera a saída de cada ramo: quando havia apenas um intervalo, a variável recebia um PSCustomObject em vez de array. No Windows PowerShell 5.1, `.Count` desse objeto não fornece a quantidade 1 esperada pela verificação. Assim, os registros de intervalo único eram indevidamente excluídos. Os dois intervalos de 15+15 continuavam como array e passavam. No PowerShell 7 o objeto escalar expõe Count=1; isso explica a diferença em relação aos testes anteriores.

A atribuição agora envolve o if inteiro em `@(...)`, preservando um array mesmo com zero ou um intervalo. A regra de duração continua exigindo 30 dias, duas parcelas válidas de 15 ou FR de 20 dias. Não houve relaxamento das validações nem mudanças no JSON, nos aceites ou nos CPs.

Na base recebida em 31/10, o modelo da contagem do Windows PowerShell 5.1 reproduziu exatamente o sintoma: 134 válidos e 45 falsas pendências na versão anterior. Com a correção: 179 válidos, zero dessas falsas pendências. Essa quantidade corresponde à base enviada, não necessariamente a alterações feitas depois no computador do usuário.

Pendências reais agora mostram a opção aceita, o tipo, o aquisitivo e as datas/durações lidas para permitir conferir a causa. Os cabeçalhos da planilha/XML permanecem iguais e o importador Access não precisou mudar.

Instalação: feche o sistema e substitua somente FeriasDCE.ps1. Preserve Dados, Backups e o JSON atual. Gere novamente tanto o XML quanto o Excel, se utilizar os dois. Use o novo XML no módulo de conferência/importação já instalado. Não é necessário reimportar o módulo VBA por causa desta correção. O importador continua conferindo o que já foi cadastrado, portanto a conferência deve mostrar os registros anteriormente inseridos como existentes e os intervalos recuperados como novos ou divergentes conforme o banco real.

Validação: testes agora exigem a expressão de array na AST, exercitam a 1ª/2ª/3ª opção com um único intervalo, simulam a ausência de Count em PSCustomObject do PowerShell 5.1 e comparam os resultados com os da execução normal. Também verificam que um intervalo realmente inválido continua bloqueado e que a mensagem informa sua duração. Não foi executado Windows PowerShell 5.1 nativo neste Linux; o modelo de semântica não substitui a confirmação visual no Windows.
