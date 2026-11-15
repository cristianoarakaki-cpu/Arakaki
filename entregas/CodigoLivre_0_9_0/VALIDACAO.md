# Validação — Código Livre IA 0.9.0

- `assembleRelease lintRelease`: BUILD SUCCESSFUL; Java 17, Gradle 8.11.1, AGP 8.9.1, SDK 35, NDK 27.2.12479018.
- 247 verificações passaram: 15 de código/ZIP, 30 de CSV/XLSX, 20 de SQLite e 53 do fluxo de análise em partes com motor simulado e 21 de regras de atualização/modos e 15 dos perfis de velocidade e 29 de consulta online/kit e 43 de páginas/calendários e 21 de último jogo/relevância, com fontes simuladas.
- Análise em partes: entradas acima de 30 mil caracteres, Unicode, cobertura sem lacunas, tokenização de alta densidade simulada, interrupção no preparo/geração, falhas e preservação dos relatórios.
- O bloqueio de 30 mil caracteres foi removido. O tamanho de cada etapa é validado pela API de contagem que usa o mesmo template/tokenizador da geração. Não houve teste com pesos reais neste ambiente. Não há comprovação de ganho de velocidade, qualidade ou estabilidade de reuso em aparelho físico; 7B continua exigente em CPU.
- Perfis Rápido (3072/768), Equilibrado (4096/1536) e Longo (8192/saída disponível): cobertura/reserva validadas com motor simulado. O primeiro número é o contexto e o segundo, o limite de saída por etapa. Rápido é o novo padrão.
- JNI: contexto reutilizado entre partes com KV limpo, liberado no fim da análise, prefill com até 6 threads, microbatch 256 e batch 512. O3 confirmado no comando real de compilação de ggml-cpu. Nenhum benchmark de inferência foi realizado.
- Progresso nativo: leitura X/Y tokens e geração com taxas medidas; métricas por etapa no texto. Estas métricas ainda precisam de validação com pesos no aparelho.
- Barra persistente: percentual por partes concluídas, indicador de atividade e tempo decorrido. Falha e interrupção não exibem 100% indevidamente nos testes do coordenador.
- Serviço Android foreground dataSync, com notificação, ação de interromper, CPU ativa e checkpoint atômico periódico. A tela deixa de cancelar a execução ao ser destruída e reassocia ao estado do serviço ao retornar.
- Modo de assuntos gerais: prompt próprio, perguntas sem anexos e opções Qwen2.5 Instruct gerais/Coder. As respostas dependem do modelo; nenhum teste de qualidade com pesos reais foi feito.
- Atualizador opcional: verificação ao abrir, canal HTTPS autorizado, tamanho/SHA256/pacote/versão/assinatura e instalador do Android. Políticas de versão, digest, origem e signatários verificadas em JVM.
- Consulta online opcional: notícias via Google News RSS, busca via Bing RSS e calendários ESPN do Flamengo. Anexos não são enviados. Manchetes e calendários são formatados diretamente; outras fontes podem apoiar a geração local.
- Rede real para Google News/ESPN bloqueada pelo proxy deste ambiente (CONNECT 403). Não foi feita validação ao vivo dos provedores. Testes injetam RSS/JSON fictícios, incluindo indisponibilidade, time incorreto, partidas passadas/adiadas e limites das fontes.
- Kit Android embarcado: scripts Termux, Java/aapt2/D8/assinatura e aplicativo Java de exemplo. Compilação, DEX, alinhamento, assinatura e apksigner verify do exemplo passaram em Linux com JDK 17/SDK 35. Não foram instaladas ferramentas no smartphone nem executados os scripts no Termux. Escopo limitado, sem Gradle/Kotlin/NDK.
- 0.9.0: reprodução do descarte de ISO sem segundos e verificação da correção; leitura HTML/JSON-LD/estado ESPN; conteúdo de páginas gerais e fallback do calendário.
- Segurança: HTTPS, endereços públicos, rejeição de destinos internos, DNS validado pelo cliente; NAT64 público permitido para redes móveis. Páginas restritas e JSON excessivamente profundo recusados.
- Velocidade: páginas em paralelo e orçamento de coleta de 20 segundos. Testes com orçamento reduzido verificaram encerramento de fonte simulada travada; teste de barreira verificou paralelismo real das tarefas. Isso não é um benchmark de internet no POCO.
- Novo modo rápido devolve passagem extrativa da fonte sem geração local; síntese com IA continua opcional e pode demorar com 7B.
- 0.9.0: regressão da pergunta exata último jogo do Flamengo e da página Dicio. Último seleciona evento encerrado mais recente no passado; próximo seleciona evento futuro não encerrado. Consulta de resultados usa fixture=false.
- Placar preservado (objetos/string), placar ausente explícito, jogos em andamento/cancelados excluídos. HTML embutido preserva o estado final e placar ao transportar eventos.
- Filtro lexical de assunto rejeita a coincidência temporal último/próximo como prova de relevância, exige tópicos nomeados e prefere a fonte aceita mais relacionada. Não é garantia semântica ou de veracidade.
- CSV: separador, aspas, quebras dentro de campos, faixas, contagens e limites.
- XLSX: nomes/relações de abas, textos compartilhados/inline, fórmulas/cache/erros, faixas, omissões, limites e XML inválido.
- SQLite: consultas reais em banco fictício Linux/JDBC aberto somente leitura, esquema, contagens, NULL/BLOB, PK composta, ordenação numérica, filtro de nomes e verificação estrutural rápida. Hash do arquivo preservado após consultas. Cabeçalhos WAL recusados.
- Dependências JDBC/SLF4J existem somente nos testes, sem inclusão no APK.
- APK assinado, alinhamento ZIP de 16 KiB verificado; com INTERNET para consulta online/atualizador e REQUEST_INSTALL_PACKAGES para instalação confirmada de atualizações, além de foreground service/dataSync, WAKE_LOCK e POST_NOTIFICATIONS para processamento local. Nenhum conteúdo do usuário é enviado pelo atualizador.
- Pacote `br.com.arakaki.codigolivre`, versionCode 9, versionName 0.9.0, somente ARM64.
- Certificado idêntico ao APK 0.1.0 entregue: e9d415e56660a45d50878385ead9168c04bde518b1426c757d157ee4a063db64.
- Lint: 0 erros; avisos: ChromeOsAbiSupport=1, UsableSpace=1, SetTextI18n=15. Interface em português, foco ARM64 e controle conservador de espaço livre.

## Limites reais

Não executamos consultas ao vivo, instalação/preparo/compilação no Termux do POCO, o fluxo de download/instalação Android, seu diálogo de origem de APK, a interface ou notificações, troca de aplicativos, bloqueio de tela, retomada da tela ou restrições HyperOS em aparelho físico. Também não executamos o seletor de arquivos, o adaptador SQLite Android nem inferência com pesos 1,5B/3B/7B no POCO. Os testes de SQLite são do núcleo compartilhado de consultas usando JDBC Linux, não do runtime Android. Compilação e lint verificam a integração estática Android. A validação do serviço, callbacks JNI, reuso de contexto, checkpoint e integração de tela foi estática e de compilação/lint; não houve teste de ciclo de vida Android em dispositivo/emulador. Encerramento do processo não retoma o cálculo automaticamente; pode recuperar o último checkpoint válido. Os testes do coordenador usam motor simulado; a integração JNI/tokenização real precisa de teste no aparelho. A atualização sem perda de dados tem compatibilidade de pacote, versão e assinatura verificada; o fluxo físico ainda precisa ser confirmado.

Modelos gerais e Coder, incluindo opções leves de 1,5B, foram disponibilizados como opções, sem alegação de melhoria de qualidade medida ou garantia de memória/velocidade. O uso com 12 GB requer avaliação no aparelho. O modelo já importado permanece aceito.

As prévias têm limites explícitos e não equivalem à análise completa de uma planilha ou banco. Macros, fórmulas recalculadas, datas formatadas, gráficos e ACCDB não são analisados diretamente. Leia LEIA-ME.md.
