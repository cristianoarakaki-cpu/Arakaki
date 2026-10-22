# HIST-R7: 20 rodadas automatizadas

Resultado: 20/20 aprovadas; 7247 verificações, sem falhas.

SHA-256 do PS1: `acd759e3209e3ec0a05b75d046776f4b57f837a027acfe738ce18b92e568797e`.

Cada rodada executou Rodada.ps1 com leitura da cópia original recebida, Identidade.ps1, Access.ps1 e ListaServidores.ps1. Foram usados cinco culturas, seeds 7001 a 7020 e 40 cenários aleatórios por rodada. O PS1 não mudou durante as rodadas. Os testes gravam em arquivos temporários.

A lista da cópia original foi conferida por openpyxl: 178 matrículas únicas, todas exportadas como texto, com duas colunas na aba principal e três pendências por nomes divergentes na mesma matrícula. Nenhuma lista com dados pessoais foi adicionada ao repositório. A validação sintética independente confirmou zeros iniciais, identificadores longos e nomes tratados como texto literal.

Limites: testes em PowerShell 7.4.6 no Linux. A interface WinForms e a execução completa em Windows PowerShell 5.1 precisam de validação no Windows. Estas rodadas não representam 20 auditorias manuais independentes do projeto.

| Rodada | Seed | Cultura | Verificações | Resultado |
|---|---|---|---|---|
| 1 | 7001 | pt-BR | 360 | Aprovada |
| 2 | 7002 | en-US | 362 | Aprovada |
| 3 | 7003 | de-DE | 365 | Aprovada |
| 4 | 7004 | fr-FR | 363 | Aprovada |
| 5 | 7005 | es-ES | 360 | Aprovada |
| 6 | 7006 | pt-BR | 362 | Aprovada |
| 7 | 7007 | en-US | 361 | Aprovada |
| 8 | 7008 | de-DE | 358 | Aprovada |
| 9 | 7009 | fr-FR | 367 | Aprovada |
| 10 | 7010 | es-ES | 364 | Aprovada |
| 11 | 7011 | pt-BR | 365 | Aprovada |
| 12 | 7012 | en-US | 364 | Aprovada |
| 13 | 7013 | de-DE | 361 | Aprovada |
| 14 | 7014 | fr-FR | 367 | Aprovada |
| 15 | 7015 | es-ES | 364 | Aprovada |
| 16 | 7016 | pt-BR | 362 | Aprovada |
| 17 | 7017 | en-US | 356 | Aprovada |
| 18 | 7018 | de-DE | 360 | Aprovada |
| 19 | 7019 | fr-FR | 361 | Aprovada |
| 20 | 7020 | es-ES | 365 | Aprovada |
