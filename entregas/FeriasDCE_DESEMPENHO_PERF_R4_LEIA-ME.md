# Férias DCE — PERF-R4

Prepara o Planejamento em segundo plano logo após a carga inicial, aproveitando o tempo antes da primeira visita à aba. Se houver sincronização automática ao abrir, aguarda essa sincronização terminar antes de preparar a cópia.

## Comportamento esperado

- Ao entrar no Planejamento, um resultado já pronto e ainda válido é reaproveitado.
- Se entrar imediatamente após iniciar, o cálculo pode ainda estar em andamento e a grade mostrar “Calculando...”. Esta mudança antecipa o trabalho; não elimina o tempo de cálculo.
- Alterações nos dados/configuração/filtros são revalidadas. Um resultado antigo não substitui os dados atuais.
- O preparo não substitui um pedido de cálculo já iniciado pelo usuário e usa o worker de leitura existente.
- O resultado fica somente na memória desta sessão. Não há novo arquivo de cache em disco.

## Instalação

1. Feche o sistema e guarde uma cópia do FeriasDCE.ps1 atual fora da pasta de execução.
2. Extraia o ZIP e substitua somente FeriasDCE.ps1.
3. Abra pelo BAT habitual e confirme PERF-R4 no título.
4. Aguarde alguns segundos após a carga/sincronização inicial e entre no Planejamento. Compare também o acesso imediato após iniciar.

Mantenha Dados, Backups, JSON, launcher e BAT. Aprovação/desaprovação, cálculo e correção de gravação na rede foram preservados. Para voltar, restaure somente o script anterior, sem restaurar JSON antigo.

## Testes e limites

Testados o agendamento sem duplicação, a ordem de sincronização/preparo, dados atualizados após sincronizar, proteção do pedido ativo/cache válido e liberação de timer no fechamento. O teste executou o handler de inicialização com timers e sincronização simulados. O controlador também foi testado com um runspace real de cálculo e dados sintéticos.

Ambiente: Linux / PowerShell 7.4.6. A interface WinForms e o Windows PowerShell 5.1 do trabalho precisam de validação no seu computador. Não há promessa de abertura instantânea. A sincronização em rede conserva seu próprio tempo de execução.

Não altera políticas de execução ou permissões. Se ainda houver espera depois de permanecer alguns segundos na tela inicial, envie o log do dia da pasta Logs; a linha PERF-R4 “preparando planejamento apos carga inicial” identifica o início do preparo.
