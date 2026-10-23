# Protocolo HTML no Access

Importe o módulo modProtocoloHTML.bas no seu banco de desenvolvimento/cópia de segurança: Alt+F11 → Arquivo → Importar arquivo. No botão Protocolo do formulário, configure Ao Clicar como [Procedimento de Evento] e coloque esta chamada dentro do evento existente:

```vb
Private Sub NomeRealDoBotao_Click()
    GerarProtocoloHTML Me
End Sub
```

Mantenha o nome real que o Access criou para o evento. Não crie um segundo evento com o mesmo nome. Se já houver código no botão, examine esse código antes de substituir sua ação.

O módulo procura um único subformulário com os campos Matricula, Nome e Cargo; também aceita Matrícula e Nome do Servidor/NomeServidor. O texto exibido no cabeçalho da grade pode ser diferente do nome real do campo. Se houver mais de uma grade compatível, informe o nome do CONTROLE de subformulário, que pode ser diferente do nome do formulário:

```vb
GerarProtocoloHTML Me, "NomeDoControleDaGrade"
```

Se o botão estiver no próprio formulário contínuo, a chamada sem nome também funciona. O módulo usa RecordsetClone da grade encontrada; não consulta a tabela inteira nem remove o filtro/ordenação. Exporta todos os registros do filtro, inclusive os que estejam fora da área visível ao rolar, e não somente a linha selecionada. Não executa Requery, Edit, Update nem grava no banco. Linhas novas ainda não salvas não fazem parte do conjunto exportado.

O arquivo é criado em TEMP/SYSENF_DCE_Protocolos com nome único, codificação UTF-8 e aberto pelo navegador padrão. Se o navegador impedir a abertura, a mensagem informa o caminho para abri-lo manualmente. Os arquivos contêm os dados exportados e permanecem na pasta temporária até sua limpeza.

A tabela tem Matrícula, Nome do Servidor, Cargo e Semestre. Cada linha tem uma lista com Selecione, 1, 2, 3, 4 e 5. O botão Imprimir / Salvar PDF imprime o valor escolhido, sem a caixa de seleção. As escolhas ficam apenas na página aberta: não são gravadas no Access e não devem ser consideradas salvas no HTML original ao fechar/reabrir. Para conservar o resultado preenchido, use Salvar PDF na impressão.

Nenhuma referência adicional ao DAO/ADO precisa ser marcada: os objetos são criados por late binding. O módulo usa os componentes padrão do Access/Windows (ADODB.Stream e Scripting.FileSystemObject), sem API específica de 32/64 bits. Não é um arquivo VBS.

Não foi fornecido o banco ACCDB/MDB: o módulo e o procedimento estão preparados para importação, mas o botão ainda precisa ser associado no Access. A execução VBA e o RecordsetClone com o filtro real precisam ser conferidos no Access/Windows. O HTML foi validado no navegador com registros fictícios, caracteres especiais e impressão dos semestres selecionados.

## Atualização R2 — título e recebido

O título inicial é PROTOCOLO_ESTAGIO PROBATORIO_ENFERMAGEM. Na barra superior do HTML, altere o campo Titulo para usar outro texto; o cabeçalho e o título do navegador acompanham a edição e o PDF utiliza o texto escolhido. A alteração vale para aquela página aberta. Para definir outro título inicial na chamada do Access:

```vb
GerarProtocoloHTML Me, "", "OUTRO TITULO"
```

Se informar o controle da grade, mantenha seu nome no segundo argumento. A chamada antiga `GerarProtocoloHTML Me` continua funcionando.

O quadro RECEBIDO aparece ao final do documento, depois da tabela, com Data ____/_____/ANO ATUAL e linha de Recebido por. O ano usa a data do computador no Access e é atualizado pelo navegador ao abrir e imprimir. O quadro é mantido inteiro na impressão, sem ficar sobreposto às linhas da tabela; em listas longas aparece ao final, na última página.

Para atualizar uma instalação que já tem o módulo anterior: no editor VBA, remova somente o módulo modProtocoloHTML antigo (guarde uma cópia se desejar) e importe o novo arquivo BAS. Não importe os dois módulos simultaneamente, pois as funções públicas teriam nomes duplicados. O evento do botão pode continuar com a mesma chamada. Gere um novo HTML para receber as alterações.

Verificação R2: edição do título, escape de caracteres, retorno ao título inicial quando vazio, semestre independente por servidor e quadro recebido na impressão foram verificados no Chromium. A validação de execução do VBA continua dependendo do Access/Windows.

## Atualização R3

O campo Semestre oferece 1, 2, 3, 4 e 5. Título configurável, recebido e ano automático foram preservados. Substitua o módulo anterior e gere um novo HTML; a chamada do botão permanece igual.
