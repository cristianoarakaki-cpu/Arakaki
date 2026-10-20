# Férias DCE — CORR-R6

Versão baseada na PERF-R5, com correções dos dez defeitos reproduzidos na auditoria e diagnóstico adicional de inconsistências semânticas. O identificador **CORR-R6** aparece na janela principal e na Central.

## Como atualizar

1. Feche o sistema em todos os computadores que usam a mesma pasta.
2. Guarde uma cópia do `FeriasDCE.ps1` atual e uma cópia de segurança da pasta `Dados`.
3. Extraia o ZIP e copie **somente o `FeriasDCE.ps1` da pasta principal** para a pasta do sistema, substituindo o arquivo de mesmo nome.
4. Preserve `Dados`, `Backups`, `Autorizacoes`, `Logs`, `Relatorios` e os arquivos de inicialização existentes. O pacote não contém uma base substituta.
5. Abra pelo inicializador que já funciona no seu computador. Esta atualização não exige VBS novo, mudança de permissões, instalação de PowerShell nem alteração da política de execução.
6. Confira **CORR-R6** no título da janela.

A pasta `Validacao` contém material técnico e dados fictícios. Não copie os seus arquivos para `Dados`, não execute `Referencia_PERF_R5.ps1` e não substitua o programa pela referência anterior. Não é necessário executar os testes para abrir o sistema.

## Correções aplicadas

| Auditoria | Comportamento corrigido |
|---|---|
| A01 | Todas as parcelas fixas entram na contagem institucional, inclusive adicionais e parcelas de outro ano. A chave do cache também considera os adicionais. |
| A02 | Zerar o planejamento limpa os adicionais. A importação registra o estado anterior completo; desfazer a importação restaura as parcelas manuais anteriores. |
| A03 | O relatório de aceites usa a mesma consulta institucional da Central. O filtro por setor do HTML usa os pesos calculados pelo motor, com deduplicação por matrícula/aquisitivo. A conferência inclui adicionais e não soma comum/FR em duplicidade. |
| A04 | Filtros de situação realmente excluem as linhas incompatíveis. |
| A05 | “Somente com sobreposição real” consulta as datas; duas férias no mesmo mês sem coincidência não geram sobreposição. “Sem limite” considera o limite institucional, conforme a política atual. |
| A06 | A escolha do último backup pré-reset ordena os timestamps válidos, independentemente do prefixo do nome. |
| A07 | Uma política mensal rejeitada não altera parcialmente a configuração ativa. |
| A08 | Falha no cálculo invalida o cache da faixa institucional, permitindo preencher os totais na tentativa seguinte com a mesma base. |
| A09 | O mapa diário de opção definida usa aprovações comum e FR independentemente e inclui compromissos fixos. Opções pendentes não são apresentadas como aprovadas nessa visão. |
| A10 | Corrigir o aquisitivo verifica se as férias fixas continuam posteriores ao novo fim aquisitivo. Uma correção válida continua permitida. |
| A11 | Diagnóstico separado identifica, por exemplo, aprovação sem opção preenchida e FR sem intervalo válido. A quantidade aparece em Configurações e os avisos do carregamento são registrados no log. Não apaga nem converte automaticamente registros antigos. |

A consulta de aprovação compartilhada também substituiu o recorte por `IndexOf`/`Substring` que montava parte do motor do worker. O cálculo em segundo plano, a rejeição de resultados antigos e o preparo antecipado foram mantidos.

A regra de equivalência preserva a usada pela Central: comum e FR usam o maior peso mensal, limitado a 1 por servidor/aquisitivo. As colunas de modalidade no relatório contam parcelas e podem ter soma diferente do total institucional; o texto do relatório explica essa diferença.

## Verificação realizada

Todos os checks abaixo terminaram com sucesso na fonte entregue:

- **11 cenários de regressão** correspondentes aos achados A01–A11.
- **20 verificações de integração** com registros fictícios, incluindo reversão de importação, parcelas de outro ano, mudanças no cache, coincidência na data de fronteira, aprovação só de FR e correção válida do aquisitivo.
- **8 cenários de persistência/recuperação**: substituição normal, JSON inválido, alternativa após acesso negado, alternativa recusada, alteração externa, backup divergente, rollback e temporário fora da pasta.
- **5 combinações de filtros/limites em runspace real**, com resultados iguais aos do cálculo síncrono, incluindo fixa adicional e FR aprovada separadamente.
- Controlador assíncrono: pedidos simultâneos, descarte de resultados antigos, alteração durante cálculo, aba oculta, falha, nova tentativa e encerramento.
- Preparo antecipado: aguarda sincronização, não substitui pedido ativo e libera o timer.
- Geração real do HTML de aceites, recálculo JavaScript dos **24 meses**, filtro por setor e deduplicação. O DOM foi simulado no Node.js.
- Trecho real de cálculo/detalhamento da conferência: comum/FR no mesmo mês, quinzena adicional com peso **0,5** e datas nominais correspondentes ao mês selecionado.
- Parser sem erros, BOM UTF-8 e CRLF preservados. Comparação com a PERF-R5 confirmou **14 funções de persistência/proteção e 3 eventos de decisão preservados**, além do controle das demais alterações fora do escopo.

Os testes rodaram em **PowerShell 7.4.6/Linux e Node.js**, carregando definições do AST sem iniciar a aplicação. Controles e confirmações foram simulados. Os testes de persistência usam arquivos descartáveis; a alternativa de renomeação é simulada. Nenhuma base operacional foi aberta, alterada ou enviada ao repositório.

Isso comprova os cenários descritos, não ausência absoluta de erros. **WinForms, Windows PowerShell 5.1, ACLs, MoveFileEx e SMB reais não foram executados neste ambiente.** O worker foi executado de verdade no PowerShell disponível; as janelas não foram abertas.

## Conferência no Windows

De preferência, confira inicialmente em uma cópia da pasta com dados de teste:

1. Abra Planejamento; teste “Somente críticas”, “Com férias fixas” e sobreposição real.
2. Compare uma fixa de duas quinzenas em meses diferentes com o total institucional e o relatório de aceites.
3. No relatório, selecione um setor e confira que o total continua coerente com os registros desse setor.
4. Teste aprovar e desfazer aprovação em um registro de teste, feche e reabra para verificar persistência.
5. Confira a troca de filtro durante cálculo e a primeira abertura da aba.

Não faça reset ou restauração na base de produção apenas para testar. A correção não recupera estados anteriores que versões antigas não tenham registrado. No reset de importações com snapshot antigo sem lista de parcelas, os adicionais identificados como importados são removidos e os sem essa identificação são preservados para conferência, com aviso no log.

A velocidade da primeira abertura continua dependente de leitura/sincronização e cálculo. Esta versão corrige consistência e recuperação; não promete eliminar os seis segundos observados na máquina de trabalho.

## Material técnico

`Validacao` contém scripts e resultados. Os testes são destinados a uma sessão descartável de PowerShell 7.4.6/Linux, pois usam tipos simulados de Windows Forms. Não os execute na sessão que hospeda o sistema real. `Referencia_PERF_R5.ps1` serve exclusivamente à comparação de integridade.

Executar nessa pasta: `pwsh -NoProfile -File ./test_integracao.ps1`, `test_conferencia.ps1`, `test_worker_filtros.ps1`, `test_async.ps1`, `test_warmup.ps1`, `test_smb.ps1` e `verify.ps1`. Após a integração gerar `RELATORIO_SINTETICO.html`, executar `node test_html.js`. Os resultados individuais estão nos arquivos `RESULTADOS_*`.

`SHA256SUMS.txt` permite conferir os bytes dos arquivos entregues. O relatório da auditoria permanece no GitHub para referência; os números de linha dele se referem à PERF-R5.
