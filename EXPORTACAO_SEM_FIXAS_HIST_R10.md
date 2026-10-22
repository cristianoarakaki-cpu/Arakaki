# Exportação para Access sem férias fixas — HIST-R10

A exportação ignora integralmente os registros marcados como férias fixas/bloqueadas antes de verificar os aceites comuns ou de FR. Esses registros não entram em Colar_Access nem em Pendencias. Um aquisitivo não fixo do mesmo servidor continua elegível quando aceito e válido.

Substitua somente FeriasDCE.ps1, mantendo Dados e Backups. Gere um novo Excel em Lançamentos → Relatórios → Exportar aceitas para Access (Excel). Descarte o Excel anterior para essa colagem: a regra antiga permitia fixas com aceite marcado. Nenhuma alteração na base JSON é necessária.

Os testes cobrem fixas sem aceite, com aceite comum, com aceite FR e com ambos; preservação do registro original; e manutenção de outro aquisitivo aceito do mesmo servidor. A interface WinForms e a colagem no Access precisam ser verificadas no Windows.

## Correção da conferência

O callback de “Atualizar registros” da conferência V1.0.157 agora captura o ScriptBlock da função Read-DatabaseSnapshotWithRetry antes de criar sua closure. Assim preserva o acesso à função e às dependências no escopo original. O teste extrai do código as instruções reais do callback e verifica leitura válida, rejeição de JSON inválido e preservação dos bytes em ambos os casos dentro de um módulo isolado.
