# Validação HIST-R11

20 de 20 rodadas aprovadas, 9577 verificações do aplicativo, em cinco culturas e seeds 11001–11020. As suítes anteriores foram executadas com os novos testes de conferência: 44 verificações por rodada cobrem o trecho real de cálculo do callback e o motor compartilhado de conflitos.

O inicializador C# passou por outras 20 rodadas, com 360 verificações de argumentos, STA, ausência de criação de console, caminhos com espaços/UNC, captura de saída/erros, logs únicos e fallback. Total: 9937 verificações.

PS1 SHA-256: `b71b46afdcfa4ec285c364b33e0de0f82e805353febe05376d0475f49b96789b`.
EXE SHA-256: `6f4e6fb22ab836720d5ce5568dd24517e75df33898563fb59f8def63712a4a86`.
EXE: Windows GUI (subsistema PE 2), CLR v4.0.30319, AnyCPU, 7168 bytes. Compilado com Roslyn contra as referências .NET Framework 4.8. O arquivo C# foi compilado também em memória para executar os testes de seus métodos, sem invocar o ponto de entrada nativo.

Foram verificados períodos comuns e FR aprovados independentemente, fixas, pesos de 15 dias, deduplicação, saldo sem pendentes, filtros sem inflar o saldo institucional, conflitos inclusivos, virada do ano, mudanças de participantes e compatibilidade das opções de comparação por setor/entre setores/mesmo turno do relatório existente. O trecho de cálculo da interface é extraído por AST e executado com controles simulados.

Limitações: Linux/PowerShell 7. A interface WinForms, Windows PowerShell 5.1, a abertura visual do EXE e a impressão precisam de validação no Windows. Não foi utilizado VBS, não houve alteração de política de execução e nenhuma base pessoal é incluída na entrega pública.
