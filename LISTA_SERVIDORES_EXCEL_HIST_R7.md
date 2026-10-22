# Lista de servidores em Excel — HIST-R7

Acesse Lançamentos → Relatórios → Exportar lista de servidores (Excel), escolha o destino e salve o XLSX. A geração não exige Excel instalado.

A aba Servidores tem exatamente duas colunas: Matrícula e Nome. Inclui todos os servidores presentes na base atual, independente de filtros e do aceite de férias. Cada matrícula aparece uma vez, mesmo quando possui vários períodos aquisitivos. Matrícula é uma célula de texto literal: zeros iniciais e identificadores longos não são convertidos em números. O nome é exibido em maiúsculas, preservando acentos.

Pendencias informa cadastro sem matrícula, matrícula sem nome e matrícula com nomes diferentes nos períodos. Quando há mais de um nome, a lista exibe todos separados por barra, sem escolher um arbitrariamente. Uma matrícula ausente não gera uma chave inventada. A aba Instrucoes explica como gerar a segunda lista no banco, com Matrícula, CP e Nome. A exportação não vincula CPs e não modifica o cadastro.

O escritor XLSX existente foi estendido com parâmetros opcionais para nome da aba, instruções e cabeçalhos de pendências. Os padrões da exportação de aceitas para Access foram preservados e seus testes foram executados novamente.

Validação específica: 13 verificações para lista completa, deduplicação por matrícula, preservação de zeros, matrícula longa, nomes divergentes, cadastro incompleto, dados originais inalterados, conteúdo real do XLSX e base vazia. Leitura independente com openpyxl confirmou duas colunas, matrículas textuais, caracteres especiais e instruções próprias. Interface WinForms e interação no Windows precisam de validação visual.
