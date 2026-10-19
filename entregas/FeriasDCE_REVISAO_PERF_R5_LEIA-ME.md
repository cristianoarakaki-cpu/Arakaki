# Férias DCE — PERF-R5

Ajuste dos pontos 2 e 3 da revisão externa sobre PERF-R4. Não é uma nova promessa de redução do tempo da primeira abertura.

- Falha ao iniciar ou concluir o cálculo: invalida o resultado pronto, marca atualização pendente, remove as linhas/valores antigos da exibição visível, libera ambas as grades e mostra a orientação para tentar novamente.
- Consultas por clique ficam bloqueadas enquanto a exibição está pendente. Isso evita consultar linhas desatualizadas após uma falha.
- Preparo em aba oculta: não muda as grades ou o texto da aba. Ao entrar durante um cálculo, o aviso de processamento é aplicado. Resultado pronto continua sendo reaproveitado com validação.
- Falha de um pedido antigo não limpa a exibição de um pedido mais recente.

## Instalação

Feche o sistema, guarde o FeriasDCE.ps1 atual fora da pasta de execução e substitua somente esse script pelo arquivo do ZIP. Abra pelo BAT habitual e confira PERF-R5 no título. Mantenha Dados, Backups, JSON e launcher/BAT.

Para voltar, restaure somente o script anterior; não restaure uma base JSON antiga.

## Pontos da análise que continuam em aberto

1. O snapshot completo continua sendo validado. Um cache com contador deve cobrir todas as alterações em memória, configuração, importação e filtros, além das gravações; usar apenas a revisão salva poderia reutilizar dados antigos.
2. Stop continua síncrono, chamado depois de ShowDialog retornar. A janela já está fechada, mas o processo pode levar tempo adicional para encerrar.
3. Escopo do worker foi testado em runspace real do PowerShell 7.4.6/Linux. Windows PowerShell 5.1 e WinForms do trabalho ainda precisam de validação local; a revisão não demonstrou uma falha de escopo nessa versão.
4. O recorte da consulta por texto permanece. Sua substituição por um motor modular exige uma mudança separada, com comparação de resultados. A verificação explícita da estrutura continua.

As regras de cálculo, aprovação/desaprovação e gravação em rede foram preservadas. Não altera permissões ou políticas.

## Testes

Parser, comparação de funções preservadas, runspace real com dados sintéticos e controlador assíncrono aprovados. Verificados erro real de pipeline, erro simulado de inicialização, controles liberados, descarte da exibição antiga, nova tentativa com cálculo real e controles inalterados na aba oculta. Preparo após sincronização e fechamento também testados com timers/sincronização sintéticos.

WinForms real e Windows PowerShell 5.1 não executados neste ambiente. Veja RESULTADOS_TESTES.txt. Se ocorrer falha local, envie o log do dia da pasta Logs.
