# Protocolo HTML — margem de segurança V1.1

Ajuste aplicado somente ao CSS de impressão de `InicioHTML`:

- A4 retrato com margem externa de 15 mm.
- Recuo interno de 3 mm nas laterais da folha, acrescentando folga para as bordas.
- Largura da tabela e do quadro Recebido limitada à área disponível.
- Mantidos título editável, escolhas de semestre, leitura do filtro atual e quadro de recebimento.

## Instalar

Faça backup. No editor VBA, abra o módulo que contém `GerarProtocoloHTML` e substitua todo o conteúdo pelo arquivo `modProtocoloHTML.txt`. Não precisa excluir nem renomear seu módulo existente. Compile em **Depurar > Compilar**, salve e gere um HTML novo.

A chamada continua `GerarProtocoloHTML Me`, incluindo os argumentos opcionais já existentes.

O BAS é uma alternativa de importação. Para atualizar o módulo existente, prefira o TXT. Os dois arquivos estão em Windows-1252/ANSI com CRLF.

No diálogo de impressão do Chrome, selecione **A4**, **Retrato**, **Margens padrão** e **Escala 100%**. Confira a prévia antes da impressão física. Arquivos HTML gerados anteriormente continuam com o estilo anterior.

## Verificação

Foram gerados PDFs em Chromium real com 1 e 100 registros fictícios. A leitura das coordenadas dos elementos gráficos do PDF confirmou que nenhuma borda ficou fora da área de segurança de 15 mm; a menor folga medida à direita foi aproximadamente **17,5 mm**. O cenário de 100 registros gerou cinco páginas, incluindo o quadro Recebido.

Título editável, semestre selecionado e ocultação da barra na impressão foram conferidos. Somente `InicioHTML` mudou; os demais procedimentos e a chamada pública foram preservados.

Microsoft Access e impressora física não foram executados neste ambiente. A compilação VBA e a impressão na sua impressora precisam de conferência local. Este ajuste usa a área CSS de impressão e não muda configurações do driver.

`Validacao` contém os resultados e um PDF de uma página com dados exclusivamente fictícios. Não é necessário executar esses arquivos para usar o módulo.

Para reverter, reponha o módulo salvo no backup.
