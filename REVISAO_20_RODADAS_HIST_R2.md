# Revisão de 20 rodadas — HIST-R2

Versão: **V1.0.136-R2 | HIST-R2**. Data da revisão: 21/10/2026.

## Resultado

**20/20 rodadas aprovadas; 6281 verificações; zero falhas na versão corrigida.** As rodadas variaram sementes de dados e formatos regionais, em processos independentes. Não se trata de 20 execuções da interface WinForms nem de prova de ausência de todos os defeitos.

## Falha adicional encontrada e corrigida

A proteção de simulação comum/FR da revisão R1 ainda podia ser contornada pelas próprias chamadas da Central:

- Ao avaliar uma aprovação comum, a Central criava uma cópia do registro e apagava todas as datas FR. A avaliação perdia a referência a uma FR já aprovada. O cenário reproduzido retornou um alerta institucional quando eram esperados dois.
- Ao avaliar uma FR na mesma opção que contém férias comuns aprovadas, a Central substituía essa opção inteira por uma opção somente FR. A simulação perdia o compromisso comum e podia omitir um conflito simultâneo do setor.

Os dois cenários falharam contra HIST-R1 e passaram contra HIST-R2. Os registros de baseline preservam essas reproduções separadamente dos resultados das 20 rodadas corrigidas.

A avaliação agora recebe a candidata em um parâmetro separado, conservando o registro original com as decisões independentes. Não altera automaticamente opções, aprovações ou dados já salvos. A mudança funcional está limitada à avaliação da Central; as demais chamadas mantêm o comportamento padrão.

## O que foi verificado em cada rodada

- Suíte anterior: sintaxe, histórico, importações, cores, calendários Excel 1900/1904, conflitos, cobertura, recuperação seletiva, gravação, lock, rejeição de JSON inválido, conflito entre clientes e restauração.
- Chamadas reais de avaliação da Central extraídas por AST, sem iniciar as janelas, incluindo os dois cenários novos de comum/FR.
- Quarenta conjuntos variados de intervalos históricos e períodos de férias por rodada. A contagem esperada foi calculada pela enumeração dos dias, independentemente do algoritmo do programa.
- Contagem de dias únicos, mínimo de 15 dias, invariância à ordem das entradas e pesos mensais de períodos de 15, 20 e 30 dias, incluindo travessias de meses e anos.
- Consulta somente leitura à cópia da base enviada, com 237 registros; preparação de recuperação dos 413 históricos e equivalência dos 12 totais mensais entre cálculo síncrono e worker real.

Foram usados pt-BR, en-US, de-DE, fr-FR e es-ES, com sementes 1001 a 1020. São 800 cenários variados adicionais, além dos testes fixos. A quantidade de asserções por rodada varia conforme os meses atravessados pelos períodos gerados.

## Resultado por rodada

| Rodada | Semente | Formato regional | Verificações | Resultado |
|---|---|---|---:|---|
| 01 | 1001 | pt-BR | 317 | Aprovada |
| 02 | 1002 | en-US | 310 | Aprovada |
| 03 | 1003 | de-DE | 316 | Aprovada |
| 04 | 1004 | fr-FR | 315 | Aprovada |
| 05 | 1005 | es-ES | 311 | Aprovada |
| 06 | 1006 | pt-BR | 315 | Aprovada |
| 07 | 1007 | en-US | 313 | Aprovada |
| 08 | 1008 | de-DE | 313 | Aprovada |
| 09 | 1009 | fr-FR | 316 | Aprovada |
| 10 | 1010 | es-ES | 313 | Aprovada |
| 11 | 1011 | pt-BR | 312 | Aprovada |
| 12 | 1012 | en-US | 314 | Aprovada |
| 13 | 1013 | de-DE | 314 | Aprovada |
| 14 | 1014 | fr-FR | 309 | Aprovada |
| 15 | 1015 | es-ES | 313 | Aprovada |
| 16 | 1016 | pt-BR | 320 | Aprovada |
| 17 | 1017 | en-US | 314 | Aprovada |
| 18 | 1018 | de-DE | 314 | Aprovada |
| 19 | 1019 | fr-FR | 315 | Aprovada |
| 20 | 1020 | es-ES | 317 | Aprovada |

Total: **6281 verificações**. Tempo registrado pelo executor: 143.6 segundos.

## Integridade e limites

SHA-256 do PS1 testado:

`7c1be2002f6a6434ad78ece6f405e78f379b8629bf7273b4aa7e591862494a44`

Nenhum arquivo de Dados ou Backups de produção foi alterado. As operações de gravação ocorreram somente em pastas temporárias de teste. A base enviada foi consultada para leitura.

Ambiente: PowerShell 7.4.6 sobre Linux. A revisão estrutural do PS1 encontrou 324 definições de função, zero erros sintáticos e nenhuma construção identificada como exclusiva de PowerShell 7. Get-Acl é específico do ambiente Windows e não foi exercitado aqui.

A interface WinForms completa, Windows PowerShell Desktop 5.1, impressão física e compartilhamento SMB real continuam exigindo validação no Windows. O usuário confirmou a abertura da revisão anterior após desbloquear o download; isso não equivale a testar todas as telas da revisão R2.

## Atualizar

Feche o sistema e guarde o PS1 anterior. Substitua somente FeriasDCE.ps1. Preserve Dados, Backups, launcher e BATs. O título deve mostrar **V1.0.136-R2 | HIST-R2**. Se o Windows marcar o novo download como bloqueado, use o mesmo procedimento de Propriedades > Desbloquear que funcionou anteriormente.

## Reproduzir

Os testes portáteis ficam em `validacao-ferias/`. Execute em um processo novo de PowerShell:

```powershell
pwsh -NoProfile -File ./validacao-ferias/Rodada.ps1 -Seed 1001 -Culture pt-BR
```

Sem `-RealData`, são usados apenas dados sintéticos. O parâmetro opcional aponta para uma cópia da base e habilita os testes específicos do conjunto enviado. Os resultados relacionados a 413 históricos e ao nome do backup pertencem ao ZIP analisado, não são uma regra universal de qualquer instalação.
