# Avaliação completa — FeriasDCE.ps1 PERF-R5

**Conclusão:** encontrei **10 problemas de comportamento reproduzidos com dados fictícios** e **1 lacuna de validação estrutural/semântica**. Quatro problemas têm prioridade alta: contagem de parcelas fixas, limpeza incompleta no reset, divergência entre totais de relatórios e seleção do backup mais recente. A sintaxe passou, mas isso não valida as regras de negócio.

A análise considera a **PERF-R5**, última versão entregue, e não os módulos Access da Agenda nem o arquivo antigo na raiz do repositório. O aplicativo **não foi modificado nesta avaliação**.

## Fonte e método

- Fonte: `FeriasDCE.ps1`, 930.751 bytes, 15.548 linhas; UTF-8 com BOM e CRLF.
- SHA256: `11E11DB8293C66367F023E773C22A899173D3B036CA9268C8AAFAB8B52640430`.
- Parser: PowerShell 7.4.6/Linux; zero erros sintáticos, 312 definições de funções (incluindo internas), 281 registros de eventos e 155.817 tokens.
- Leitura estática do arquivo completo por blocos, cruzamento dos fluxos e testes dirigidos de funções/eventos extraídos do próprio AST. Não foi iniciado o script completo.
- Os testes substituem confirmação, gravação, backup e controles por objetos simulados. Todos os servidores e períodos são fictícios; nenhuma base operacional foi aberta ou gravada.
- O teste A03 executa o trecho original de cálculo do relatório até a montagem das linhas. A09 exercita os blocos escolhidos pelo caminho do mapa diário. Os demais limites de simulação estão descritos em cada achado e no script.
- Não executei Windows Forms, Windows PowerShell 5.1, ACLs Windows, MoveFileEx nem SMB neste ambiente Linux. Compatibilidade de execução e tempos no computador de trabalho precisam de validação nesse ambiente.

**O que significa “linha a linha” nesta entrega:** o HTML contém as 15.548 linhas numeradas, com contexto de função e marcação dos achados; o CSV contém uma entrada para cada linha; o mapa cobre todas as 312 funções. A numeração, classificação estrutural e associação de contexto são automáticas. A avaliação técnica é apresentada por fluxo/trecho e não por 15 mil afirmações genéricas de “linha correta”. Não há garantia de ausência de outros defeitos nem certificação das normas administrativas de férias.

## Prioridades

P1 = corrigir antes de confiar nos totais, resets e restaurações afetados. P2 = corrigir no próximo conjunto de ajustes funcionais. D = melhoria de defesa, sem demonstração de defeito gerado pela interface.

| ID | Prioridade | Achado | Linhas principais |
|---|---|---|---|
| A01 | P1 | Parcela fixa adicional fica fora do total institucional | 1225–1256, 8659–8679, 9687–9734 |
| A02 | P1 | Reset mantém parcelas fixas adicionais | 3746–3838, 8073–8092, 7988–8015 |
| A03 | P1 | Relatório de aceites e Central calculam equivalências diferentes | 9651–9678, 13779–13960, 14310–14360 |
| A04 | P2 | Filtros de situação não removem as linhas esperadas | 10625–10640 |
| A05 | P2 | Filtro de sobreposição real devolve vazio | 9561–9578, 10631–10640 |
| A06 | P1 | Último backup pré-reset pode ser um backup mais antigo | 3887–3902 |
| A07 | P2 | Validação rejeitada deixa configuração alterada em memória | 14608–14643 |
| A08 | P2 | Recuperação de falha da PERF-R5 pode deixar totais vazios | 10411–10430, 10772–10787 |
| A09 | P2 | Mapa diário usa a opção comum para escolher a FR | 7075–7090, 1240–1288 |
| A10 | P2 | Correção do aquisitivo não confere datas fixas existentes | 5769–5845 |
| A11 | D | Validação estrutural não garante consistência das decisões | 301–326, 328–342 |

## Achados com evidências

### A01 — Parcela fixa adicional fica fora do total institucional

**Classificação:** Alta. **Fonte:** linhas 1225–1256, linhas 8659–8679, linhas 9687–9734.

**Reprodução:** Uma fixa de 15 dias em janeiro e outra parcela de 15 dias em março aparecem na grade por setor, mas março soma zero na contagem institucional. A ocupação de março deveria incluir a quinzena (0,5).

**Causa:** Get-OpcaoPlanejamento monta tipo FÉRIAS FIXAS com inicio2. Get-OptionBlocksObjeto só interpreta a segunda parcela quando o tipo começa com 15+15 DIAS. A consulta por setor usa outro caminho, que percorre os adicionais.

**Consequência:** Uma vaga pode parecer disponível mesmo estando comprometida. O defeito está no caminho de cálculo das fixas; não é apenas apresentação.

**Correção recomendada:** Centralizar a enumeração de todas as parcelas fixas e reutilizá-la em contagens, relatórios e consultas. Não depender de converter uma lista em uma opção de dois campos.

**Regressão a verificar:** Duas quinzenas em meses distintos; duas no mesmo mês; passagem de ano; registro sem adicionais. Comparar Central, faixa institucional e detalhamento.

### A02 — Reset mantém parcelas fixas adicionais

**Classificação:** Alta. **Fonte:** linhas 3746–3838, linhas 8073–8092, linhas 7988–8015.

**Reprodução:** O reset real foi executado com gravação e confirmação simuladas. Limpou a fixa principal e o bloqueio, mas preservou um item em fixos_adicionais. A consulta de conferência continuou apresentando esse item como FIXA.

**Causa:** Reset-PlanejamentoAtual não limpa fixos_adicionais. O reset das importações também precisa tratar esse campo e o estado anterior das parcelas. Algumas consultas consideram a presença dos adicionais suficiente, independentemente do bloqueio.

**Consequência:** O planejamento zerado pode continuar contendo compromissos antigos em relatórios. Uma operação posterior também pode reencontrar parcelas que o usuário acreditava ter removido.

**Correção recomendada:** Definir um estado completo da fixa: principal, adicionais, origem, ajuste e bloqueio. Reset e reversão de importação devem limpar ou restaurar esse conjunto de forma coerente.

**Regressão a verificar:** Importar duas parcelas, zerar planejamento e verificar ausência em todas as consultas; desfazer importação preservando exatamente o estado anterior.

### A03 — Relatório de aceites e Central calculam equivalências diferentes

**Classificação:** Alta. **Fonte:** linhas 9651–9678, linhas 13779–13960, linhas 14310–14360.

**Reprodução:** Com férias comuns de 17/01 a 15/02/2027 e FR de 16/02 a 07/03/2027, sem sobreposição de datas, o relatório de aceites soma 2 em fevereiro e a Central soma 1.

**Causa:** O motor institucional limita a contribuição mensal por servidor/aquisitivo e combina comum/FR pelo maior peso. O relatório soma os blocos por categoria; a conferência também tem agregação própria por modalidade.

**Consequência:** Dois documentos do mesmo sistema podem fundamentar decisões opostas sobre a ocupação do mês.

**Correção recomendada:** Formalizar a regra administrativa e manter um único agregador institucional. O teste prova a divergência; não decide se a política correta deve ser o teto atual ou a soma do relatório.

**Regressão a verificar:** Comum e FR no mesmo mês sem sobreposição; meses diferentes; duas quinzenas; vários aquisitivos do mesmo servidor. Conferir total e lista nominal em cada saída.

### A04 — Filtros de situação não removem as linhas esperadas

**Classificação:** Média. **Fonte:** linhas 10625–10640.

**Reprodução:** SOMENTE CRÍTICAS devolveu uma linha sem nenhum mês crítico.

**Causa:** O continue está dentro do switch. Nesse contexto ele não realiza o salto pretendido do foreach externo, e a execução chega a Linhas.Add. O mesmo padrão existe nos outros filtros de situação.

**Consequência:** A tela pode mostrar linhas que não atendem ao filtro escolhido, prejudicando a conferência.

**Correção recomendada:** Calcular uma variável incluir e fazer um único continue fora do switch, ou usar condições explícitas no corpo do foreach.

**Regressão a verificar:** Uma linha que atende e outra que não atende a cada situação; repetir com filtro de mês, busca e sobreposição.

### A05 — Filtro de sobreposição real devolve vazio

**Classificação:** Média. **Fonte:** linhas 9561–9578, linhas 10631–10640.

**Reprodução:** Dois servidores com as mesmas datas apresentaram pico real de 2, mas a opção de mostrar somente sobreposição devolveu zero linhas.

**Causa:** Get-EstadoLinhaPlanejamento retorna sobreposicao=false de forma constante. O filtro consulta esse campo. sem_limite também é constante, apesar da existência dessa opção na interface.

**Consequência:** A ausência de linhas pode ser interpretada como ausência de coincidências, embora elas existam.

**Correção recomendada:** Calcular o estado com os intervalos reais, aproveitando o cache de sobreposição, ou retirar um filtro cuja regra deixou de existir. Não apresentar resultado vazio como conclusão de uma análise não executada.

**Regressão a verificar:** Coincidência real, datas apenas no mesmo mês sem coincidência e fronteira inclusiva no mesmo dia. Definir se o escopo inclui solicitações ou apenas a base de decisão.

### A06 — Último backup pré-reset pode ser um backup mais antigo

**Classificação:** Alta. **Fonte:** linhas 3887–3902.

**Reprodução:** Entre ANTES_RESET_TOTAL_REAL_20261018... e ANTES_RESET_DECISOES_20261020..., a função selecionou o arquivo do dia 18.

**Causa:** Sort-Object Name -Descending ordena primeiro os prefixos diferentes; a data só é extraída depois da seleção. O comentário sobre timestamp confiável não garante a ordem temporal.

**Consequência:** A restauração oferecida como última pode retornar a um estado anterior ao necessário. Existe confirmação com o nome do arquivo e proteção de concorrência, portanto não é uma restauração silenciosa.

**Correção recomendada:** Extrair e validar o timestamp de cada candidato antes de ordenar. Desconsiderar nomes inválidos e oferecer a lista com data, motivo e arquivo.

**Regressão a verificar:** Prefixos diferentes com datas invertidas; timestamps iguais; nome inválido; nenhum backup. Confirmar que o mais recente por data é selecionado.

### A07 — Validação rejeitada deixa configuração alterada em memória

**Classificação:** Média. **Fonte:** linhas 14608–14643.

**Reprodução:** O total foi alterado de 189 para 200 antes de rejeitar janeiro com limite zero. Save-Database não foi chamado, mas Config já continha 200.

**Causa:** O evento modifica o objeto compartilhado antes de concluir a validação de todos os campos.

**Consequência:** Cálculos seguintes podem usar uma configuração não aceita. Uma gravação posterior de outra ação pode persistir esse estado parcial.

**Correção recomendada:** Montar uma configuração candidata, validar tudo e só depois substituir o estado ativo e salvar. Em falha de gravação, manter a política de recuperação consistente.

**Regressão a verificar:** Falha no primeiro e no último mês; cancelar/corrigir a entrada; abrir outra tela e salvar outra alteração. O estado ativo não deve mudar após rejeição.

### A08 — Recuperação de falha da PERF-R5 pode deixar totais vazios

**Classificação:** Média. **Fonte:** linhas 10411–10430, linhas 10772–10787.

**Reprodução:** Após uma faixa já ter sido calculada, Set-PlanejamentoUiFalha limpou suas células. Na tentativa seguinte com a mesma chave, Refresh-LimiteInstitucionalResumo retornou pelo cache sem preencher a faixa.

**Causa:** A rotina de falha limpa a apresentação e o Ready, mas mantém InstitutionalResumoCacheKey válido.

**Consequência:** A grade volta a responder, mas a faixa institucional pode permanecer em branco mesmo após recuperar o cálculo. Esse problema está no tratamento introduzido na PERF-R5.

**Correção recomendada:** Invalidar a chave institucional quando a faixa for limpa. Preferencialmente, relacionar a validade da apresentação à chave do resultado efetivamente renderizado.

**Regressão a verificar:** Renderizar, provocar falha, tentar novamente sem mudar dados nem filtros e conferir as 12 células. O teste anterior com renderização substituída não cobria essa interação.

### A09 — Mapa diário usa a opção comum para escolher a FR

**Classificação:** Média. **Fonte:** linhas 7075–7090, linhas 1240–1288.

**Reprodução:** Com comum aprovada na opção 1 e FR aprovada na opção 2, o caminho do mapa OPÇÃO DEFINIDA escolhe os blocos da opção 1: inclui a FR de junho e omite a FR aprovada em agosto.

**Causa:** Refresh-Dashboard calcula um único índice a partir de opcao_aprovada e chama Get-OptionBlocks, sem aplicar fr_opcao_aprovada independentemente.

**Consequência:** O mapa diário pode divergir da aprovação vigente e apresentar ausência em datas erradas.

**Correção recomendada:** Usar um enumerador de blocos efetivamente aprovados que combine a decisão comum e a decisão FR. Tratar fixas pelo mesmo contrato quando a visão pretende representar todos os compromissos.

**Regressão a verificar:** Comum=1/FR=2; somente FR aprovada; comum sem FR; nenhuma aprovação; fixa com duas parcelas. A reprodução exercitou os blocos do caminho, sem abrir o Dashboard WinForms.

### A10 — Correção do aquisitivo não confere datas fixas existentes

**Classificação:** Média. **Fonte:** linhas 5769–5845.

**Reprodução:** O evento aceitou mudar o fim aquisitivo para 31/12/2027 mantendo uma fixa iniciada em 01/01/2027. As opções estavam vazias.

**Causa:** A validação percorre as opções de escolha, mas não valida a fixa principal e as adicionais contra o novo aquisitivo.

**Consequência:** A correção pode produzir um registro incompatível com a regra de início após o fim aquisitivo aplicada em outros fluxos.

**Correção recomendada:** Conferir todos os compromissos vinculados antes de alterar o aquisitivo. Se existe exceção administrativa válida para fixa, exigir um fluxo explícito de conferência e registrar o motivo, sem apagar o compromisso.

**Regressão a verificar:** Aquisitivo novo que invalida a principal, só a adicional, nenhuma delas e duplicidade com outro aquisitivo.

### A11 — Validação estrutural não garante consistência das decisões

**Classificação:** Defesa adicional. **Fonte:** linhas 301–326, linhas 328–342.

**Reprodução:** Uma base sintética com opcao_aprovada=1 e opcao1 completamente vazia passou em Assert-DatabaseStructure.

**Causa:** A função verifica formato geral, IDs e faixa numérica das decisões, mas não a relação entre uma decisão e suas datas. Trata-se de validação estrutural, não semântica.

**Consequência:** A integridade de JSON e de hash não prova que o conteúdo representa uma aprovação válida. Não foi demonstrado que a interface normal crie esse estado.

**Correção recomendada:** Acrescentar um diagnóstico semântico separado no carregamento/importação/restauração. Não bloquear nem converter automaticamente registros legados sem uma estratégia de migração e relatório de pendências.

**Regressão a verificar:** Decisão sem opção; data inválida; fixa incompleta; identidade incompleta; registros legados permitidos. Distinguir erro estrutural fatal de pendência administrativa.

## Avaliação dos demais aspectos

### Gravação na rede e recuperação

O desenho tem proteções relevantes: arquivo de lock, comparação da revisão/hash carregado com o disco, backup, temporário no mesmo diretório, validação JSON e substituição atômica em vez de truncar a base. A alternativa Windows verifica pré-condições, cópia de segurança e metadados de segurança antes da renomeação. Há tratamento de conflito e preservação de alterações em arquivo de resgate. Isso é melhor sustentado pelo código do que uma simples sobrescrita do JSON.

A validação estrutural tem o limite descrito em A11. Igualdade de hash comprova bytes, não regras administrativas. Nenhuma inspeção estática comprova comportamento de um compartilhamento SMB específico em queda de conexão. O relato de sucesso de aprovar/desaprovar é evidência operacional favorável, mas não equivale a teste de falha simultânea.

Validar no Windows: dois usuários carregam a mesma revisão e salvam em sequência; o segundo deve receber conflito sem apagar o primeiro. Repetir com queda antes/depois da substituição, falta de espaço, arquivo bloqueado, acesso negado e restauração. Inspecionar o JSON efetivamente persistido, o backup e o arquivo de resgate após cada cenário. Não remover o lock nem trocar a gravação por Set-Content direto para ganhar velocidade.

### Performance e processamento em segundo plano

O worker evita executar o cálculo pesado diretamente no evento da interface. Recebe uma cópia dos dados, tem caches próprios e devolve um modelo que é aplicado na thread da interface. A chave é revalidada para rejeitar resultado antigo, os pedidos pendentes são consolidados e a montagem da grade usa AddRange. O preparo antecipado aguarda a sincronização inicial e pode aproveitar o tempo antes da visita à aba. Essas escolhas são coerentes com a melhora observada depois do primeiro acesso.

Ainda existe custo na interface: Get-PlanejamentoSnapshot (10645–10664) serializa todos os registros e a configuração em JSON e calcula SHA256. O snapshot volta a ser solicitado no controle dos resultados. Quanto maior a base, maior o custo potencial; não medi seis segundos nesse computador e não atribuo toda a demora a essa etapa sem medição.

Próxima otimização recomendada: medir separadamente sincronização/leitura de rede, snapshot, criação do runspace, cálculo e renderização; depois guardar uma cópia por versão de dados/configuração e montar uma chave menor de filtros. O contador de versão deve ser incrementado em TODOS os caminhos de alteração, inclusive importações, restaurações e correções. Remover a revalidação sem substituto permitiria apresentar dados antigos.

O recorte de função por IndexOf/Substring para montar o motor privado é frágil para manutenção. Existe erro explícito quando a estrutura esperada muda, o que evita uma falha silenciosa, mas funções de consulta independentes seriam mais seguras. A lista fechada de funções selecionadas reduz dependências; um runspace com InitialSessionState padrão não deve ser descrito como sandbox de segurança.

O encerramento libera timers, pipeline e runspace; Stop é síncrono, portanto o processo pode demorar a terminar durante cálculo pesado. Deve ser medido no Windows. O problema demonstrado de recuperação visual está em A08; o escopo de $script: e as dependências do worker continuam exigindo um cálculo real no Windows PowerShell 5.1.

### Importações, sincronização e histórico

Há prévia antes de importar, cópia para leitura, validações de identidade/período, tratamento de ambiguidades e preservação de decisões/fixas em diversos caminhos. O tratamento seguro de XML evita depender de executar macros do Excel. O histórico distingue ausência de registro de ausência de férias, o que é importante para não criar um desempate injustificado.

O leitor assume layouts e posições específicos, inclusive planilha/linha de cabeçalho e colunas. Não deve ser tratado como importador genérico de qualquer XLSX/XLSM. Validar arquivo com aba reordenada, matrícula com zeros à esquerda, datas em texto/serial, valores de fórmulas sem cache e datas de outro sistema de calendário do Excel. Caso esses formatos não sejam suportados, mostrar rejeição clara na prévia.

A importação e as reversões precisam preservar o conjunto completo de parcelas fixas, conforme A01/A02. O histórico e os textos de importação se concentram em 2024–2026; para decisões de anos posteriores, conferir a janela histórica necessária e os dados disponíveis. Não presumir que a opção de ano 2028 significa histórico completo até 2027.

### Regras e consistência de decisões

As maiores fragilidades são múltiplas representações do mesmo compromisso: opção comum, FR independente, fixa principal, fixas adicionais, projeção e relatório. A01, A03 e A09 resultam de consumidores diferentes desses estados. A correção deve criar consultas comuns para “blocos do compromisso”, “decisão efetiva” e “peso institucional”, com escopo explícito de servidor/aquisitivo/mês.

Também há textos dizendo que setor, turno e chefia são apenas filtros, enquanto rotinas de avaliação/recomendação ainda consideram limites e alertas locais. Isso exige conciliar política administrativa, mensagem e comportamento. Não recomendo remover verificações só para fazer o texto coincidir. Definir primeiro quais alertas são informativos e quais exigem justificativa/bloqueio. Esse ponto é uma divergência de política/documentação observada estaticamente, fora das dez reproduções de defeitos.

A aplicação admite registros legados e exceções. A validação semântica deve gerar pendências compreensíveis, sem converter automaticamente pendência em aprovação, nem apagar férias fixas importadas do RH.

### Interface, escrita e acessibilidade

A organização por abas, Central de aprovação e relatórios de conferência oferece uma estrutura útil. Os relatórios HTML usam SVG, filtros e estilos de impressão, evitando depender de emojis que variam conforme a máquina. As áreas com texto longo e grades devem ser avaliadas em 1366×768, escala 125%/150%, navegação por teclado e com nomes extensos. A leitura estática não valida corte, foco ou posição real no Windows.

Priorizar A04/A05/A08 antes de refinar aparência. Um filtro que devolve resultado incorreto é mais grave do que a escolha de um ícone. Mostrar “Calculando…” com escopo claro e impedir ações sobre resultado desatualizado são boas medidas já presentes em parte do código.

Padronizar termos: “Férias fixas”, “Período aquisitivo”, “FR aprovada”, “Opção aprovada”, “Pendência” e “Restaurar backup de [data]”. Evitar rótulos que prometam ausência de conflito ou integridade total quando só houve validação estrutural. Corrigir concordância como “Nova férias fixa” para “Novo período de férias fixas” e manter acentuação e versões consistentes. Existem identificadores de versão diferentes entre janela principal, Central, comentários e esquema; explicar quais são versões de interface e quais são de dados.

### Segurança e manutenção

O script usa arquivos JSON, backups e relatórios com dados de pessoas. A proteção de acesso depende das permissões do Windows/compartilhamento; identidade visual e nome de usuário não equivalem a autorização por função. A inspeção não demonstrou um sistema de perfis de aprovação independente dessas permissões. Verificar acesso às pastas efetivamente usadas, incluindo Backups, Logs e Relatorios. Não publique bases reais junto com o código.

A leitura não revelou necessidade de executar macros das planilhas nem de enfraquecer políticas de segurança para o fluxo de cálculo. O bloqueio anterior do VBS que iniciava PowerShell é uma questão separada da regra de férias: manter o modo de abertura permitido pelo ambiente e não acrescentar bypass para contorná-lo.

O monólito mistura domínio, persistência, importação, HTML, UI e eventos. As funções e os testes dirigidos ajudam, mas o acoplamento dificulta localizar todos os consumidores de um novo campo, como fixos_adicionais. Recomendo extrair gradualmente motor de regras e persistência, preservando o formato da base e os fluxos de segurança. Não há motivo para reescrever tudo antes de corrigir os achados prioritários.

## Cobertura da leitura por bloco

A tabela indica os fluxos examinados estaticamente. “Sem achado reproduzido” não significa “certificado correto”. Testes dirigidos cobrem somente os cenários descritos em A01–A11.

| Linhas | Bloco avaliado |
|---|---|
| 1–232 | Inicialização, parâmetros, log e identidade visual |
| 233–813 | Persistência, locks, backups, restauração e gravação atômica |
| 814–1356 | Datas, classificação, opções, fixas e regras básicas |
| 1357–2166 | Histórico, identidade, desempate e consultas |
| 2167–2732 | Configuração, vínculos de chefia e validação de controles |
| 2733–3396 | Leitura de planilhas XML/ZIP, prévias e restauração |
| 3397–3933 | Importação de fixas/histórico e resets |
| 3934–5566 | Mapeamento, inconsistências e sincronização da base |
| 5567–6098 | Cadastro manual, aquisição, fixas e lote |
| 6099–7010 | Filtros, exclusão, editor e gravação de opções |
| 7011–7701 | Dashboard, exportação e construção da interface inicial |
| 7702–8377 | Formulários HTML e relatório de coincidências |
| 8378–9438 | Editor visual, prévias, limites e seleção múltipla |
| 9439–10227 | Motor institucional, ocupação e sobreposições |
| 10228–10608 | Avaliação, recomendação, faixa institucional e tooltips |
| 10609–11045 | ViewModel, snapshots, worker, warmup e renderização |
| 11046–11572 | Detalhamento e ajuste protegido de fixas |
| 11573–12981 | Central de aprovação, decisões comuns e FR |
| 12982–13778 | Interface de planejamento, configuração e timers |
| 13779–14604 | Relatórios de aceites e de conferência |
| 14605–15548 | Eventos finais, abertura, sincronização e encerramento |

## Sequência recomendada de correção e aceite

1. Unificar parcelas e equivalências institucionais; corrigir A01/A03 e conferir totais nominais com uma base sintética conhecida.
2. Corrigir resets e ordenação de backups (A02/A06), testando a reversibilidade completa em cópias descartáveis.
3. Corrigir filtros, configuração parcial, recuperação visual e decisões FR/aquisitivo (A04/A05/A07/A08/A09/A10).
4. Acrescentar diagnóstico semântico compatível com legados (A11) e conciliar a política de alertas com os textos.
5. Executar no Windows PowerShell 5.1 os testes de UI, aprovação/desaprovação, troca de filtros durante cálculo, fechamento e concorrência em rede.
6. Medir a primeira abertura e só então otimizar o custo dominante. Comparar dados e decisões antes/depois; rapidez sem igualdade dos resultados não é aceite.

## Arquivos desta avaliação

- `RELATORIO_COMPLETO.md`: parecer e evidências.
- `CODIGO_COMENTADO.html`: fonte inteira numerada, contexto e achados associados; abrir em um navegador após extrair o ZIP.
- `REVISAO_LINHA_A_LINHA.csv`: 15.548 entradas com classificação estrutural, função/bloco e IDs de achados que alcançam o trecho. Não contém uma afirmação automática de correção.
- `MAPA_FUNCOES.csv`: 312 definições, linhas e achados relacionados.
- `reproduzir_achados.ps1`: testes dirigidos com mocks e dados fictícios; carregam definições do AST, não iniciam a aplicação.
- `achados_reproduzidos.json`: resultados observados na fonte avaliada. Os testes confirmam a presença dos problemas; não são testes de uma versão já corrigida.
- `Fonte/FeriasDCE.ps1`: cópia exata da fonte avaliada para permitir reprodução, sem base de dados.
- `metrics.json`, `ACHADOS.json` e `SHA256SUMS.txt`: inventário e integridade dos artefatos.

Para reproduzir, em uma sessão descartável de PowerShell 7.4.6 execute `./reproduzir_achados.ps1` dentro da pasta extraída. O script verifica o hash esperado e simula mensagens/controles, gravação e restauração. Não o execute na mesma sessão interativa que esteja hospedando o sistema real. O teste usa tipos simulados de Windows Forms e foi preparado para o ambiente Linux da auditoria; **não é um teste de interface Windows**. Depois de corrigir o aplicativo, substituir as expectativas dos defeitos por testes do comportamento correto.

A avaliação identifica correções necessárias; nenhum arquivo do aplicativo em uso foi alterado ou declarado corrigido por este relatório.
