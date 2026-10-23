# Análise — Controle de Documentos V1.64.35

**Conclusão:** a correção do contrato da grade de backups está presente, mas o pacote ainda contém **seis comportamentos problemáticos reproduzidos em testes dirigidos**. As prioridades são a restauração da Lixeira depois do COMMIT, a limpeza de sinais por uma instância que não possui o motor e a reversão incompleta da troca de repositório.

O código fornecido não foi modificado. Esta entrega é uma avaliação, não uma atualização corrigida.

## Escopo e evidências

| Arquivo | Linhas | Funções, incluindo internas | Erros de parser |
|---|---:|---:|---:|
| Controle_Documentos.ps1 | 5.006 | 118 | 0 |
| Motor_Dados.ps1 | 2.213 | 68 | 0 |

Os oito hashes do manifesto conferem com os arquivos do ZIP. SHA256 das fontes:

- `Controle_Documentos.ps1`: `C9B3CC9A61A67AAF519386E50ED3DE0EFE9D5C816A1F82A9FB6D91D0055EFD46`.
- `Motor_Dados.ps1`: `42FE0C68769C511A33EE6EBFA6596631A1E19093ECA68CDF8B4524C6E9BC604A`.

A revisão concentrou-se em restauração, encerramento/concorrência, configuração, integridade, gravação de arquivos, Lixeira e consultas/cache. O inventário das 186 funções é automático; ele não significa que todas as funções foram executadas ou que cada linha recebeu um teste individual.

Executei o parser e trechos/funções originais extraídos do AST em PowerShell 7.4.6/Linux. Os testes usam arquivos fictícios em diretórios descartáveis. Controles, mensagens, configuração e acesso SQL são simulados onde necessário. Não iniciei o aplicativo nem acessei banco ou compartilhamento operacional. O teste SQLite/WAL é separado, em Python com SQLite real, e não executa a restauração Windows.

## Problemas confirmados

### P06 — Alta: falha depois do COMMIT apaga os PDFs restaurados da Lixeira

**Fonte:** `Motor_Dados.ps1`, linhas 1522–1535; função iniciada na linha 1411.

A função confirma a transação (`COMMIT`) e define `$tx=$false`. Em seguida grava `RESTAURADO.json`. Se essa gravação falhar, o `catch` remove todos os arquivos em `$created`, mesmo com a transação já confirmada. Os registros restaurados permanecem no banco e passam a apontar para PDFs ausentes no repositório ativo. A cópia preservada na Lixeira continua existindo; o teste não demonstrou perda irreversível dessa cópia.

**Reprodução:** executei a função original com um PDF fictício, cópia/verificação reais e SQL simulado que registra o COMMIT. Uma recusa real do sistema de arquivos ao gravar o marcador, provocada deterministicamente por um diretório nesse nome, acionou a exclusão do PDF ativo após o COMMIT. Isso prova o controle de fluxo; não é um teste integrado do driver SQLite nativo.

**Correção:** separar falhas anteriores e posteriores ao COMMIT. Só remover os arquivos criados enquanto a transação ainda puder ser desfeita. Depois da confirmação, preservar os PDFs e tratar falha de marcador como pendência de metadados/auditoria, com possibilidade de repetir a gravação do marcador.

**Regressão necessária:** sucesso normal; falha SQL antes do COMMIT; marcador recusado depois do COMMIT; repetição da operação; verificação de existência e hash de todos os PDFs vinculados.

### P01 — Alta: instância sem posse do motor apaga os sinais da instância ativa

**Fonte:** `Motor_Dados.ps1`, linhas 2067–2089 e 2202–2212. A interface também pode iniciar outra instância após uma falha de PING em `Controle_Documentos.ps1`, linhas 337–350.

Se a aquisição de um lock falhar, o script usa `exit 0`, mas o `finally` continua sendo executado. Ele cria `Dados/worker.stop` e remove `motor.ready`, `motor.info.json` e `motor.stop` sem verificar se essa instância adquiriu os locks ou iniciou o trabalhador. Uma segunda tentativa de abrir o motor pode, portanto, interferir no motor que deveria apenas respeitar.

**Reprodução:** executei o `finally` original com os streams de lock nulos e sinais fictícios de um motor já ativo. Os sinais foram apagados e `worker.stop` foi criado. Não iniciei nem encerrei um processo Windows real.

Existe ainda uma janela de concorrência: os locks são liberados antes de remover os sinais. Outra instância pode assumir o motor nesse intervalo. Essa intercalação específica não foi executada no teste.

**Correção:** registrar propriedade dos locks e do trabalhador; limpar apenas recursos pertencentes à instância; conferir identidade/PID/token do heartbeat; manter os locks até concluir a limpeza que exige exclusividade.

**Regressão necessária:** abrir uma segunda instância local e outra com a mesma pasta de rede. O motor original deve continuar respondendo, sem perder heartbeat nem receber parada indevida do trabalhador.

### P02 — Alta: falha na troca do repositório deixa configuração parcialmente alterada

**Fonte:** `Controle_Documentos.ps1`, linhas 2760–2771 e 2796–2820.

A função grava a nova configuração antes de atualizar o ponteiro compartilhado. `$configCommitted` só se torna verdadeiro depois das duas ações. Se a configuração foi gravada e o ponteiro falhar, o `catch` não executa a reversão, porque a flag ainda é falsa. Mesmo assim, a mensagem afirma que a configuração anterior foi restaurada.

**Reprodução:** executei `Apply-DocumentsRepositoryChange` com persistência de configuração simulada como bem-sucedida e falha injetada na gravação do ponteiro. O valor persistido capturado ficou em NOVO, `DocumentsRoot` permaneceu em ORIGEM e a mensagem declarou reversão concluída.

**Correção:** guardar os estados anteriores e controlar cada alteração efetivamente realizada. Reverter a configuração mesmo que o ponteiro ainda não tenha sido confirmado. Verificar a reversão antes de informar sucesso. Preferir escrita de configuração por temporário e substituição, sem presumir atomicidade entre disco local e ponteiro de rede.

**Regressão necessária:** falha na configuração; falha no ponteiro após gravar configuração; falha na reinicialização; falha durante a própria reversão. Mensagens devem refletir o estado realmente verificado.

### P03 — Média: restauração ignora o destino secundário configurado

**Fonte:** `Controle_Documentos.ps1`, linhas 3089–3104. A configuração editável aparece nas linhas 2850 e 2874; o motor usa o destino de proteção nas linhas 2002–2005.

`Get-DatabaseBackupCandidates` procura a pasta local e um caminho fixo na unidade G. Não consulta `BackupDocumentosDestino`, embora o sistema permita escolher outro destino e o motor grave backups nele.

**Reprodução:** criei arquivos candidatos fictícios na pasta local e em outro destino configurado. A função original devolveu apenas o candidato LOCAL. Uma unidade G fictícia foi usada para não tocar em nenhuma unidade existente.

**Consequência:** um backup existente no destino configurado pode não aparecer na tela de restauração.

**Correção:** obter o destino pela mesma configuração usada por `Backup-Database`, acrescentar a subpasta `Banco` e manter o caminho antigo apenas como compatibilidade explícita, com deduplicação.

### P04 — Média: hash legado válido com tamanho ausente faz o backup falhar repetidamente

**Fonte:** `Motor_Dados.ps1`, linhas 483–503; verificação de tamanho em `Copy-VerifiedFileAtomic`, linhas 404–411.

O tamanho ausente vira zero. Quando o hash já existe e coincide, o arquivo é marcado como OK, mas seu tamanho real não é preenchido. Em seguida o backup recebe tamanho esperado zero e rejeita o arquivo não vazio. A atualização final mantém o tamanho ausente, repetindo o problema na auditoria seguinte.

**Reprodução:** executei `Run-IntegrityAudit` com PDF fictício e hash correto, tamanho legado zero, destino de backup ativo e acesso SQL simulado. O relatório real produzido apresentou principal OK, backup FALHA e tamanho zero.

**Correção:** distinguir tamanho desconhecido de tamanho conhecido. Se o hash registrado coincide com o arquivo e o tamanho estava ausente, preencher o tamanho observado. Não substituir silenciosamente um hash divergente nem ignorar um tamanho positivo conhecido que não confere.

### P05 — Média: ID do pedido pode fazer a resposta sair da pasta de respostas

**Fonte:** `Motor_Dados.ps1`, linhas 2179–2195.

O ID recebido no JSON é validado apenas como não vazio e depois usado na construção dos caminhos `.tmp` e `.resp.json`. Um identificador com `../` escapa da pasta de respostas.

**Reprodução:** executei o bloco original de gravação com um ID fictício contendo subida de diretório. A resposta foi escrita fora da pasta esperada, dentro do diretório descartável do teste.

**Alcance:** depende de alguém ou algum componente conseguir fornecer um pedido com esse ID. Não foi demonstrado que o cliente normal gere esse formato, nem houve acesso não autorizado a uma pasta real. As permissões do compartilhamento continuam relevantes.

**Correção:** conferir o formato gerado por `Lib/Rpc.ps1`, validar o ID no servidor, recusar separadores/caminhos e confirmar que o caminho final está dentro de `IPC/Respostas`. Não confiar apenas na validação feita pelo cliente.

## Pontos adicionais a validar

### SQLite/WAL e parada do trabalhador — risco alto condicionado

O banco usa WAL (`Motor_Dados.ps1`, linhas 103–113). A restauração espera o lock do motor, mas não demonstra espera explícita pelo término do trabalhador nem checkpoint verificado antes de copiar a base atual e trocar o arquivo (`Controle_Documentos.ps1`, linhas 2983–3044). O `finally` do motor sinaliza o trabalhador e logo fecha seus próprios recursos. O código do trabalhador não veio no pacote.

Executei uma demonstração com SQLite real: a conexão tinha **1 documento confirmado**, enquanto uma cópia apenas do arquivo `.db` tinha **0 documentos** e ainda retornava `integrity_check=ok`, porque a transação estava no WAL. Isso mostra que integridade estrutural e SHA256 de uma cópia não provam que todas as transações confirmadas entraram nela.

Não é prova de que a restauração Windows desta instalação já perca dados: depende das conexões que permanecem abertas, do checkpoint e do driver não fornecido. Antes de aprovar esse fluxo, parar motor e trabalhador de forma verificável, manter exclusividade durante toda a manutenção e usar backup/checkpoint SQLite apropriado. Não apagar WAL/SHM cegamente enquanto puderem conter transações válidas.

### Backup confirmado pode não ser o mesmo aplicado

`Restore-DatabaseBackupSafe` valida um snapshot antes das confirmações, depois lê o arquivo selecionado novamente para criar o snapshot que será aplicado. A segunda cópia é validada contra seu próprio hash, mas não comparada ao hash apresentado na primeira validação. Se o arquivo de origem mudar entre essas etapas, o estado aplicado pode diferir do que foi confirmado. É um risco estático, sem reprodução do fluxo completo Windows nesta análise. Manter a cópia validada imutável até o fim ou abortar se o hash mudou.

### Base atual corrompida pode impedir recuperação

A cópia anterior à restauração precisa passar em `Test-DatabaseFileDirect` antes de aceitar a troca, mesmo que o backup escolhido seja válido. Assim, uma base atual já corrompida pode bloquear o próprio recurso de recuperação. Definir um fluxo explícito de recuperação que preserve os bytes da base corrompida para diagnóstico, sem exigir que ela seja íntegra para aplicar uma cópia boa.

### Pesquisa e tarefas longas podem bloquear a interface

Há sincronização de cache em segundo plano e preferência por cache local, o que é positivo. Porém `Perform-Search` ainda pode chamar RPC síncrono com timeout de 60 segundos (linhas 749–762). A auditoria integral percorre arquivos e hashes no mesmo motor que atende os pedidos. Em base grande ou rede lenta, isso pode atrasar pesquisas e PING. Não medi esses tempos na máquina do trabalho.

## O que está correto ou bem encaminhado

- O produtor da lista de backups agora expõe `Data`, `Origem`, `Nome`, `Tamanho` e `Caminho`, além dos aliases anteriores. O teste do contrato dessas propriedades passou.
- A grade usa esses campos e guarda o objeto do candidato em `Row.Tag`.
- A validação do candidato usa cópia local antes de abrir o SQLite, evitando abrir diretamente o backup da unidade externa/rede.
- Há verificação de cabeçalho, integridade SQLite, hash e tamanho; confirmação dupla; preservação da base anterior; e um caminho de retorno do arquivo antigo se a troca/validação falhar. Essas proteções não anulam os problemas descritos.
- Cópias de PDFs têm verificação SHA256, há Lixeira e histórico, e vários fluxos de gravação usam transações.
- O pacote não inclui `documentos.db` nem uma base que substitua os dados do usuário.

## Limites desta avaliação

Este é um pacote de atualização. Não vieram `Lib/Util.ps1`, `Lib/SQLiteNative.ps1`, `Lib/Rpc.ps1`, `Lib/ClientCache.ps1`, `Lib/PdfOcr.ps1` nem `Trabalhador_Background.ps1`. A ausência é compatível com um pacote parcial, mas impede avaliar integralmente o driver SQLite, transporte RPC, OCR, cache e comportamento do trabalhador. Não deve ser registrada como defeito de instalação se esses arquivos já existem no sistema completo.

Os textos de auditoria incluídos reconhecem verificações estáticas e teste Windows pendente. Encontrar nomes de funções ou a presença de `SHA256`, `COMMIT` e `Rollback` não comprova correção funcional desses caminhos.

Não executei WinForms, Windows PowerShell 5.1, EDR, permissões Windows ou SMB real. Os seis testes reproduzem controle de fluxo e operações de arquivo com as simulações descritas; não equivalem a seis testes completos do sistema em produção.

Não publiquei as fontes do pacote nem dados operacionais nesta entrega. O ZIP de evidências contém somente relatório, testes, resultados e inventário. O aplicativo permanece sem alterações.

## Prioridade de correção

1. P06: impedir que falha após COMMIT remova arquivos do estado confirmado.
2. P01: limitar limpeza e parada à instância que possui o motor/trabalhador.
3. P02: corrigir reversão parcial de configuração e mensagens de resultado.
4. Validar parada completa, exclusividade e WAL no fluxo de restauração.
5. P03/P04/P05: destino configurado, tamanho legado e confinamento do ID.
6. Validar no Windows com duas instâncias, falhas injetadas de gravação e cópias descartáveis de banco/PDFs, conferindo os dados antes e depois.

Para reproduzir os testes dirigidos em PowerShell 7.4.6/Linux, extrair as fontes originais em uma pasta e executar `pwsh -NoProfile -File ./testes_dirigidos.ps1 -SourceDirectory /caminho/das/fontes`. O script confere os hashes da versão, simula Windows Forms e SQLite onde indicado e cria/remove arquivos fictícios. O teste WAL separado usa `python teste_sqlite_wal.py`. Não executar os testes na sessão que hospeda o sistema real.
