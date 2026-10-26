# Dados dos Servidores em HTML — Access

Conversão do procedimento Comando12_Click enviado pelo usuário. A rotina mantém a consulta, os relacionamentos, os nove campos, a ordenação por setor/nome, os oito filtros e as sete exclusões de setores. A saída detalhada e os quatro resumos passam para um arquivo HTML, aberto no navegador. Não cria XLSX, não instancia Excel e não altera o banco.

## Instalação

1. Guarde uma cópia do código atual do botão para eventual reversão.
2. No Access, Alt+F11 → Arquivo → Importar arquivo → modDadosServidoresHTML.bas. Esse é um módulo NOVO e independente de modProtocoloHTML.
3. No módulo do formulário, localize somente o procedimento Comando12_Click. Substitua esse procedimento pelo conteúdo completo de Evento_Comando12_Click.txt. Não apague os demais eventos ou procedimentos do formulário.
4. Use Depurar → Compilar, salve, feche e reabra o formulário. Clique no mesmo botão.

Evento completo:

```vb
Private Sub Comando12_Click()
    ExportarDadosServidoresHTML
End Sub
```

O nome público e as funções auxiliares estão no módulo importado. A referência DAO é a mesma já usada pelo código original. Os demais componentes usam late binding. Não há API de Windows específica de 32/64 bits nem script VBS. O BAS/TXT é ANSI Windows-1252, compatível com o editor VBA.

## Comportamento

Os filtros são: ano de admissão, mês/ano de admissão, ano de vencimento de contrato, mês/ano de vencimento, setor, cargo, vínculo e nome. Deixar em branco ignora aquele filtro. Anos devem ter quatro dígitos e mês/ano deve estar em MM/YYYY. Entrada inválida é solicitada novamente. Cancelar agora encerra a exportação sem criar arquivo; isso é informado em cada pergunta. Filtros textuais mantêm o LIKE do Access com asterisco, como no código original, e aspas simples são escapadas.

As tabelas continuam sendo Cadastro Pessoal, Dados Funcionais e Setores. Os campos continuam sendo Codigo do Servidor, Nome do Servidor, Cargo, Tipo de Vinculo, Data Admissao, Data Venc Contrato, Setor, Horário de Trabalho e Data Saida. Matricula não foi acrescentada porque não estava na consulta original fornecida.

São excluídos os mesmos setores: ENCERRAMENTO DE CONTRATO, EXONERACAO, APOSENTADORIA, REDISTRIBUIDO, CEDIDOS, VACANCIA e DESISTENCIA. A consulta usa dbOpenSnapshot e não modifica cadastros. Os filtros vêm das perguntas do botão, conforme o original; não são filtros lidos de uma grade de formulário.

No navegador:

- Detalhado: todos os registros retornados pela consulta, na ordem original.
- Consolidado: resumos por setor, cargo, horário e cargo + horário.
- Imprimir / Salvar PDF: imprime a aba que estiver selecionada.
- Imprimir tudo: imprime detalhado e consolidado, com o consolidado começando em outra página.

Os resumos contam registros da consulta, inclusive repetições que ela produza, como fazia a versão Excel. Valores vazios não entram na categoria correspondente. O agrupamento cargo + horário usa dicionários separados, para não confundir valores que contenham os caracteres ||. Datas são exibidas em dd/mm/yyyy e preservam hora quando existente. O HTML escapa caracteres especiais e usa UTF-8.

O arquivo Dados_Servidores_*.html é salvo na Área de Trabalho reconhecida pelo Windows, inclusive quando redirecionada para OneDrive. Se não houver Área de Trabalho disponível, usa a pasta TEMP. Nomes de arquivo são únicos e a gravação não sobrescreve relatórios anteriores. Falhas de permissão ou abertura exibem uma mensagem com o caminho quando conhecido. Os dados ficam no computador, no arquivo HTML gerado; o exemplo fornecido contém somente dados fictícios.

## Validação e limites

Conferidos no Chromium: nove cabeçalhos, seis registros fictícios, campos vazios, zeros iniciais textuais, caracteres especiais, quatro resumos, caracteres || em cargo/horário, navegação das abas, impressão da aba selecionada e impressão completa. Foram verificadas também a ausência de automação Excel e a preservação das exclusões e dos oito filtros no código.

Access/VBA não está disponível no ambiente Linux: não foi possível compilar no Access nem executar a consulta contra o banco real. No Access, confira primeiro um filtro pequeno e compare registros e totais com a versão original; confira depois ausência de resultados, datas inválidas e cancelamento. Esta entrega está preparada para essa validação prática.

Para reverter, restaure o procedimento Comando12_Click anterior. O módulo novo só é chamado pelo evento alterado; não há mudança na estrutura das tabelas.
