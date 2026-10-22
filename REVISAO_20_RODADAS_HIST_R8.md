# HIST-R8: validação em 20 rodadas

Resultado: 20/20 rodadas aprovadas; 7889 verificações, nenhuma falha.

SHA-256 do PS1: `fea554a3cc744991332b398d3ecf9dbd25f212fa2540339dfe053fd03db53d88`.

Cada rodada executou Rodada.ps1 com a cópia original recebida em leitura, Identidade.ps1, Access.ps1, ListaServidores.ps1 e CadastroCP.ps1. Foram usados seeds 8001–8020, cinco culturas e 40 cenários aleatórios por rodada. CadastroCP.ps1 tem 32 verificações específicas, incluindo os dois caminhos reais de salvamento com controles simulados, criação de servidor, herança do CP, cadastro em lote, obrigatoriedade, unicidade por matrícula e prioridade do cadastro sobre o CP histórico. As gravações dos testes são temporárias. O PS1 permaneceu idêntico durante estas 20 rodadas finais.

A validação final foi executada após simplificar a pesquisa de CPs duplicados para uma passagem na base atual e uma no histórico. A série anterior de 20 rodadas, anterior a essa simplificação, não foi somada aos números aqui apresentados.

Limites: execução em PowerShell 7.4.6 no Linux. Não substitui validação visual da interface WinForms ou execução integral no Windows PowerShell 5.1. As rodadas são regressões automatizadas e não 20 auditorias manuais independentes do projeto.

| Rodada | Seed | Cultura | Verificações | Resultado |
|---|---|---|---|---|
| 1 | 8001 | pt-BR | 391 | Aprovada |
| 2 | 8002 | en-US | 400 | Aprovada |
| 3 | 8003 | de-DE | 393 | Aprovada |
| 4 | 8004 | fr-FR | 392 | Aprovada |
| 5 | 8005 | es-ES | 396 | Aprovada |
| 6 | 8006 | pt-BR | 398 | Aprovada |
| 7 | 8007 | en-US | 397 | Aprovada |
| 8 | 8008 | de-DE | 395 | Aprovada |
| 9 | 8009 | fr-FR | 396 | Aprovada |
| 10 | 8010 | es-ES | 394 | Aprovada |
| 11 | 8011 | pt-BR | 392 | Aprovada |
| 12 | 8012 | en-US | 396 | Aprovada |
| 13 | 8013 | de-DE | 395 | Aprovada |
| 14 | 8014 | fr-FR | 398 | Aprovada |
| 15 | 8015 | es-ES | 390 | Aprovada |
| 16 | 8016 | pt-BR | 395 | Aprovada |
| 17 | 8017 | en-US | 392 | Aprovada |
| 18 | 8018 | de-DE | 396 | Aprovada |
| 19 | 8019 | fr-FR | 389 | Aprovada |
| 20 | 8020 | es-ES | 394 | Aprovada |
