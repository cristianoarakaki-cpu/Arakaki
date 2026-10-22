# Abertura sem console e sem VBS — HIST-R11

Copie INICIAR_FERIAS_DCE.exe para a mesma pasta de FeriasDCE.ps1 e abra o EXE. Para usar um atalho na área de trabalho, crie o atalho apontando diretamente para esse EXE. Pare de usar o antigo BAT/CMD para a abertura normal: ele cria a janela de console antes de iniciar o PowerShell.

O EXE é um aplicativo gráfico .NET Framework, compilado com subsistema Windows GUI, AnyCPU, sem janela própria. Abre o Windows PowerShell em STA usando CreateNoWindow, UseShellExecute=false e WindowStyle=Hidden. Não executa CMD nem VBS, não altera a política de execução e não usa Bypass. A janela e o ícone normais do sistema de férias continuam aparecendo; o console não é criado.

O inicializador espera pelo término do aplicativo e grava saída/erros em Logs/INICIALIZADOR_GRAFICO_*.log. Se a pasta compartilhada não permitir gravar o log, usa TEMP/FeriasDCELogs. Falhas de abertura ou saída com erro geram mensagem gráfica com o caminho do log. Não grava JSON nem exige atualização de Dados/Backups. Caminhos de rede UNC e espaços são passados diretamente ao processo, sem o problema de pasta atual do CMD.

Código-fonte: inicializador/FeriasDCE_Iniciar.cs. Para recompilar no Windows, use inicializador/Compilar_Inicializador.ps1; não é necessário compilar para utilizar o EXE fornecido. O binário foi compilado contra referências do .NET Framework 4.8, e o cabeçalho PE foi verificado como Windows GUI/CLR 4. Os testes automatizados cobrem argumentos, janela, caminhos, logs e fallback. A execução gráfica e a ausência visual de console precisam ser confirmadas no Windows.
