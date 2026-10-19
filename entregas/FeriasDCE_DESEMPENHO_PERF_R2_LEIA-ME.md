# Férias DCE — PERF-R2

Correção para a pausa ao abrir Planejamento por Setor. O cálculo agora ocorre em um runspace de leitura separado, usando uma cópia dos dados. A janela pode continuar respondendo enquanto o cálculo termina. A grade fica desabilitada com a indicação de cálculo e é preenchida em lote ao concluir. Mudanças nos filtros ou dados descartam resultados antigos.

A Central reaproveita o resumo institucional já calculado quando válido; suas demais operações ainda não são todas assíncronas. Sincronização/importação automática e outras ações ainda podem causar espera. Não há promessa de tempo específico de abertura.

## Instalação

1. Feche o sistema em seu computador.
2. Guarde uma cópia do FeriasDCE.ps1 atual fora da pasta de execução.
3. Extraia o ZIP e substitua SOMENTE FeriasDCE.ps1 na pasta do sistema.
4. Abra pelo BAT que já funciona e confirme PERF-R2 no título.
5. Abra Planejamento e teste mudanças de filtros. Durante o cálculo, a janela deve responder e mostrar a indicação de processamento.

Mantenha Dados, Backups, arquivos JSON, launcher e BAT existentes. A correção de gravação em rede permanece, assim como as regras de aprovação/desaprovação. Para voltar à versão anterior, restaure somente o script guardado; não restaure uma base JSON antiga.

## Verificações e limites

Parser aprovado. Funções de negócio, salvamento SMB e handlers de aprovação/desaprovação comparados com PERF-R1 e preservados. Testes em runspace real verificaram equivalência do cálculo, isolamento da cópia, filtros concorrentes, descarte de resultados obsoletos, cache e falhas. Renderização com controles sintéticos verificou 36 linhas, 12 meses, totais e inserção em lote.

Ambiente de teste: Linux, PowerShell 7.4.6, dados sintéticos. Não foi possível executar WinForms real nem medir a abertura no Windows PowerShell 5.1 do trabalho. Os tempos no relatório são dos testes sintéticos, não uma previsão para seu computador.

O worker não grava a base, não inicia processo externo e herda o modo de linguagem da sessão. Não altera políticas de execução ou permissões.

Se ainda houver travamento, envie o log do dia da pasta Logs, principalmente as linhas PERF-R2 e CENTRAL, informando em qual tela e ação ocorreu. Isso permite separar cálculo, desenho e sincronização em rede.
