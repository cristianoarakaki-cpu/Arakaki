# Férias DCE → Access — HIST-R13

Correção atual: veja CORRECAO_HIST_R13.md. A coleta de intervalos foi corrigida para Windows PowerShell 5.1; basta substituir o PS1 e gerar os arquivos novamente. O módulo Access não mudou.

O fluxo de importação HIST-R12 parte do FeriasDCE.ps1 HIST-R11 enviado em 31/10/2026. Mantém a exportação Excel e acrescenta um caminho de importação conferida no Access, com os mesmos 13 campos da tabela apresentada. Não altera o JSON, Dados, Backups, nem o inicializador gráfico existente.

## Instalar

1. Feche o sistema de férias e substitua somente FeriasDCE.ps1 pelo arquivo deste pacote, na pasta atual do programa. Preserve o JSON e as pastas Dados/Backups.
2. Faça backup do banco Access e trabalhe primeiro numa cópia para validar o fluxo.
3. No Access: Alt+F11 → Arquivo → Importar arquivo → modImportarFeriasDCE.bas. É um módulo novo. Se já existir um módulo com esse nome, guarde seu conteúdo anterior e substitua-o; não mantenha duas cópias das mesmas funções públicas.
4. Use Depurar → Compilar e salve. O módulo utiliza DAO, já disponível normalmente no Access, e MSXML6/ADODB/FSO por late binding. Não cria Excel nem depende de VBS.

## Exportar e conferir

No sistema de férias, abra Lançamentos → Relatórios → **Gerar arquivo para importar no Access (conferir duplicatas)**. Salve o XML.

No Access, abra o editor VBA, pressione Ctrl+G para a Janela Imediata e execute:

```vb
ConferirFeriasDCE
```

Selecione o XML. Essa opção só lê a tabela e abre o relatório de conferência HTML. Não insere dados. Para importar após revisar o resultado, execute:

```vb
ImportarFeriasDCE
```

Também pode chamar cada procedimento no evento Ao Clicar de um botão. Não use macro ExecutarCódigo para chamar estes Subs diretamente; use Procedimento de Evento:

```vb
Private Sub SeuBotao_Click()
    ImportarFeriasDCE
End Sub
```

A importação apresenta novamente a conferência e pede confirmação antes de gravar. O ano pode ser informado para os NOVOS registros: 0000 mantém a regra anterior de preencher depois; entrada em branco preserva o ano do XML. Ano, observação e datas de registros existentes não são atualizados. O XML original não é modificado.

## Mapeamento

- ID_Ferias: omitido, porque é Numeração Automática.
- Codigo do Servidor: CP positivo; a matrícula continua sendo a identidade principal dentro do sistema de férias.
- Observação: texto curto, sem truncamento silencioso; o tamanho real do campo é conferido.
- Periodo Aquisitivo_1 / Periodo Aquisitivo_2: início/fim do aquisitivo.
- Agendar Após: fim do aquisitivo + 2 dias.
- Ferias_30_Inicio / Ferias_30_Final: 30 dias comuns ou FR de 20 dias, distinguida pelo campo Processo_20Dias.
- Ferias_Par_1QIn / Ferias_Par_1QFin / Ferias_Par_2QIn / Ferias_Par_2QFin: duas parcelas de 15 dias, sem sobreposição.
- Programacao_Ano: número 0 por padrão, editável na importação para os novos registros.
- Processo_20Dias: Sim para FR; Não para as férias comuns.

As datas do XML são ISO YYYY-MM-DD, convertidas por DateSerial no VBA sem depender do formato regional. Apenas férias explicitamente aceitas e não fixas são exportadas. Fixas/bloqueadas ficam excluídas mesmo com aceite marcado. CP ausente, inválido, divergente ou compartilhado por matrículas distintas impede a exportação daquele registro. O aplicativo não grava diretamente no Access.

## Como as duplicatas são tratadas

O período é identificado por CP + início/fim do aquisitivo. Dentro dele, admite-se uma programação comum e uma FR, conforme a estrutura atual do sistema. Programacao_Ano e observação não criam uma nova férias: diferenças nesses campos não justificam inserir novamente.

- JA_EXISTE: mesmo CP/aquisitivo/modalidade e mesmas datas. É ignorado, preservando os valores do Access.
- DUPLICATA_BASE: já há mais de uma cópia igual na tabela. Nenhuma nova é acrescentada; as cópias anteriores precisam ser revistas separadamente.
- DIVERGENTE_BASE: já existe uma programação diferente para o mesmo CP/aquisitivo/modalidade, ou o marcador de 20 dias é incompatível. Não sobrescreve e não insere outra versão.
- REPETIDO_ARQUIVO: o XML repete as mesmas férias. Só a primeira ocorrência é candidata; as outras são ignoradas.
- DIVERGENTE_ARQUIVO: há datas diferentes para o mesmo CP/aquisitivo/modalidade dentro do XML. Todas as versões desse grupo são bloqueadas.
- INVALIDO: campos, tipos, datas ou duração inválidos. Não é inserido.
- NOVO: elegível para inserção após confirmação. O relatório final passa a INSERIDO somente quando o lote foi confirmado.

Datas das duas parcelas são comparadas em ordem normalizada, para uma mera inversão da ordem das parcelas não criar outra férias. Se a base tiver aquisitivo incompleto para o CP, o acréscimo é bloqueado para revisão. Férias já existentes não são apagadas nem atualizadas. Se for necessário registrar mais de uma programação da mesma modalidade no mesmo aquisitivo, trate esse caso antes de usar esta regra conservadora; o importador o sinaliza como divergência.

**Use o importador para esse fluxo; não repita a colagem manual da planilha.** O Excel anterior permanece disponível, mas colar manualmente não consulta os registros existentes.

## Transação e vários usuários

Após a confirmação, o importador reserva um arquivo de controle junto ao banco físico de destino, relê a tabela e só insere registros previamente autorizados que continuem novos. As inserções ficam numa transação DAO; um erro antes do commit provoca rollback. Se não for possível confirmar rollback por falha de rede/conexão, a mensagem orienta conferir a tabela e o backup antes de repetir.

O arquivo vazio `<banco>.ferias-importacao.lock` pode permanecer na pasta: o bloqueio aberto, não sua existência, indica importação ativa. Não o apague durante uma importação. É necessário poder criar/abrir esse arquivo na pasta do banco. Em tabelas vinculadas a outro Access, usa o arquivo do backend. ODBC não é suportado por esta versão.

A reserva coordena importações feitas por este módulo. Não é uma restrição geral do banco contra outros programas ou inserções manuais simultâneas. Para bloquear duplicação em todos os caminhos seria necessário analisar os dados reais e definir um índice único apropriado no backend. Nenhum índice nem tabela auxiliar é criado automaticamente. Valide inicialmente sem outras pessoas alterando a tabela durante a importação.

O módulo encontra uma única tabela chamada Ferias ou Férias e valida os nomes/tipos mostrados na imagem. Caso as duas existam, interrompe para não escolher o destino errado. Regras próprias da tabela, vínculos e permissões continuam sendo respeitados pelo Access. O relatório de conferência é salvo em TEMP e contém os CPs e períodos analisados.

## Teste prático e reversão

Primeiro execute ConferirFeriasDCE numa cópia do banco e compare um período conhecido. Depois teste importar poucos novos registros e repetir o mesmo XML: a segunda execução deve mostrar JA_EXISTE e não aumentar a quantidade de linhas. Teste também uma divergência de datas, arquivo repetido, cancelamento e erro de validação numa cópia. No uso em rede, valide dois front-ends com o mesmo backend antes do uso normal.

No ambiente Linux foram executadas 20 rodadas da exportação/serialização e verificações de contrato, com culturas/datas diferentes, XML nulo/Unicode, CPs, exclusão de fixas e preservação do Excel/JSON. O VBA foi revisado estaticamente; **não foi compilado nem executado no Access**, que não está disponível neste ambiente. Não foi fornecido ACCDB/MDB para validar regras particulares, os dados já existentes ou índices do banco.

Para reverter o programa, restaure o FeriasDCE.ps1 anterior. O módulo novo só atua quando chamado. Importações confirmadas devem ser revertidas usando o backup/conferência do banco; não há rotina de exclusão automática neste pacote.
