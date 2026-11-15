# Validação — Código Livre IA 0.5.0

- `assembleRelease lintRelease`: BUILD SUCCESSFUL; Java 17, Gradle 8.11.1, AGP 8.9.1, SDK 35, NDK 27.2.12479018.
- 139 verificações passaram: 15 de código/ZIP, 30 de CSV/XLSX, 20 de SQLite e 53 do fluxo de análise em partes com motor simulado e 21 de regras de atualização/modos.
- Análise em partes: entradas acima de 30 mil caracteres, Unicode, cobertura sem lacunas, tokenização de alta densidade simulada, interrupção no preparo/geração, falhas e preservação dos relatórios.
- O bloqueio de 30 mil caracteres foi removido. O tamanho de cada etapa é validado pela API de contagem que usa o mesmo template/tokenizador da geração. Não houve teste com pesos reais neste ambiente.
- Contexto até 8192 tokens por etapa e resposta Automática até fim do modelo/contexto. Isso não torna memória, janela de contexto ou duração ilimitadas.
- Barra persistente: percentual por partes concluídas, indicador de atividade e tempo decorrido. Falha e interrupção não exibem 100% indevidamente nos testes do coordenador.
- Serviço Android foreground dataSync, com notificação, ação de interromper, CPU ativa e checkpoint atômico periódico. A tela deixa de cancelar a execução ao ser destruída e reassocia ao estado do serviço ao retornar.
- Modo de assuntos gerais: prompt próprio, perguntas sem anexos e opções Qwen2.5 Instruct gerais/Coder. As respostas dependem do modelo; nenhum teste de qualidade com pesos reais foi feito.
- Atualizador opcional: verificação ao abrir, canal HTTPS autorizado, tamanho/SHA256/pacote/versão/assinatura e instalador do Android. Políticas de versão, digest, origem e signatários verificadas em JVM.
- CSV: separador, aspas, quebras dentro de campos, faixas, contagens e limites.
- XLSX: nomes/relações de abas, textos compartilhados/inline, fórmulas/cache/erros, faixas, omissões, limites e XML inválido.
- SQLite: consultas reais em banco fictício Linux/JDBC aberto somente leitura, esquema, contagens, NULL/BLOB, PK composta, ordenação numérica, filtro de nomes e verificação estrutural rápida. Hash do arquivo preservado após consultas. Cabeçalhos WAL recusados.
- Dependências JDBC/SLF4J existem somente nos testes, sem inclusão no APK.
- APK assinado, alinhamento ZIP de 16 KiB verificado; com INTERNET e REQUEST_INSTALL_PACKAGES para o atualizador opcional, além de foreground service/dataSync, WAKE_LOCK e POST_NOTIFICATIONS para processamento local. Nenhum conteúdo do usuário é enviado pelo atualizador.
- Pacote `br.com.arakaki.codigolivre`, versionCode 5, versionName 0.5.0, somente ARM64.
- Certificado idêntico ao APK 0.1.0 entregue: e9d415e56660a45d50878385ead9168c04bde518b1426c757d157ee4a063db64.
- Lint: 0 erros; avisos: ChromeOsAbiSupport=1, UsableSpace=1, SetTextI18n=13. Interface em português, foco ARM64 e controle conservador de espaço livre.

## Limites reais

Não executamos o fluxo de download/instalação Android, seu diálogo de origem de APK, a interface ou notificações, troca de aplicativos, bloqueio de tela, retomada da tela ou restrições HyperOS em aparelho físico. Também não executamos o seletor de arquivos, o adaptador SQLite Android nem inferência com pesos 1,5B/3B/7B no POCO. Os testes de SQLite são do núcleo compartilhado de consultas usando JDBC Linux, não do runtime Android. Compilação e lint verificam a integração estática Android. A validação do serviço, checkpoint e integração de tela foi estática e de compilação/lint; não houve teste de ciclo de vida Android em dispositivo/emulador. Encerramento do processo não retoma o cálculo automaticamente; pode recuperar o último checkpoint válido. Os testes do coordenador usam motor simulado; a integração JNI/tokenização real precisa de teste no aparelho. A atualização sem perda de dados tem compatibilidade de pacote, versão e assinatura verificada; o fluxo físico ainda precisa ser confirmado.

Modelos gerais e Coder foram disponibilizados como opções, sem alegação de melhoria de qualidade medida ou garantia de memória/velocidade. O uso com 12 GB requer avaliação no aparelho. O modelo já importado permanece aceito.

As prévias têm limites explícitos e não equivalem à análise completa de uma planilha ou banco. Macros, fórmulas recalculadas, datas formatadas, gráficos e ACCDB não são analisados diretamente. Leia LEIA-ME.md.
