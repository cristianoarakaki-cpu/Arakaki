# Férias DCE — PERF-R3

Reduz o trabalho necessário para preencher Planejamento por Setor, mantendo o cálculo em segundo plano da PERF-R2.

## Mudanças

- Reaproveita consultas de cada registro dentro da cópia privada do cálculo. O índice é próprio dessa cópia, sem depender de ID ou matrícula, e o cache é reiniciado a cada pedido.
- Monta a opção efetivamente aprovada uma vez por registro, em vez de reconstruí-la a cada mês.
- Reutiliza o total projetado dos detalhes mensais para o resumo, evitando outra passagem pelos registros com a mesma chave e peso.
- Mantém descarte de resultados antigos, atualização da grade em lote e reaproveitamento do resultado válido ao voltar à aba.

A primeira abertura ainda pode mostrar a grade vazia e a indicação “Calculando...”. A tela é preenchida quando o resultado completo fica pronto. Este pacote reduz o cálculo, mas não promete abertura instantânea nem um tempo específico no Windows.

## Instalação

1. Feche o sistema.
2. Guarde uma cópia do FeriasDCE.ps1 atual fora da pasta de execução.
3. Extraia este ZIP e substitua somente FeriasDCE.ps1.
4. Abra pelo BAT habitual e confirme PERF-R3 no título.
5. Teste Planejamento, depois saia e volte à aba sem alterar os dados. O resultado válido deve ser reaproveitado.

Mantenha Dados, Backups, JSON, BAT e launcher existentes. A correção de gravação em rede e as regras de aprovação/desaprovação foram preservadas. Para reverter, restaure somente o script anterior; não restaure uma base JSON antiga.

## Validação e limites

Consulte RESULTADOS_TESTES.txt. Testes executados com PowerShell 7.4.6 em Linux e dados sintéticos. O cálculo e o controlador assíncrono foram executados; a interface WinForms real e o Windows PowerShell 5.1 do trabalho não estão disponíveis neste ambiente.

A otimização é somente de leitura na cópia do worker. Não modifica permissões ou políticas de execução. Sincronização/importação automática, consultas da Central e outras operações podem ter tempos próprios.

Caso a espera continue alta, envie o log do dia da pasta Logs e informe a ação/tela. As linhas PERF-R3 registram o tempo do cálculo, da cópia e do preenchimento da interface quando aplicável.
