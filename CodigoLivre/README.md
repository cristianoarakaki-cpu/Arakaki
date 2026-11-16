# Código Livre IA — Android offline (0.10.0 experimental)

Assistente em português para programação, planilhas e dados. Pode usar um modelo GGUF local sem conta ou APIs online com suas próprias chaves. IA online vem desativada; quando ativada envia a pergunta aos provedores configurados. Código e prévias anexadas só são enviados após autorização separada. Chaves ficam cifradas com Android Keystore e não entram nos históricos/exportações. Não há garantia de uso gratuito ilimitado; confira as condições e mantenha cobrança desabilitada nas contas que usar.

## IAs online e alternância (0.10.0)

1. Abra **Configurar IAs online e alternância**. Para cada provedor desejado, toque em **Criar chave**, obtenha a chave no site oficial e cole somente no aplicativo.
2. Toque **Buscar modelos**, escolha um modelo e repita para outros provedores. O catálogo é consultado dinamicamente; a listagem não comprova cota ou gratuidade na sua conta.
3. Ative **Usar IAs online com alternância automática** e toque **Salvar**. Com código/prévia anexada, autorize o envio no mesmo menu ou use apenas o modo local.
4. O app tenta o provedor configurado há mais tempo sem uso. Cada provedor é tentado uma vez por pergunta; após HTTP 429 respeita Retry-After, ou aguarda 60 segundos se ausente. Nova pergunta tenta novamente quando a espera termina; não há repetição automática de perguntas em segundo plano.
5. Gemini e Groq dependem das condições da conta/projeto: use sem faturamento/créditos pagos e confira os termos. OpenRouter aceita apenas modelos `:free`/`openrouter/free` com preço de entrada e saída zero no catálogo. As cotas não são removidas.
6. A pergunta e anexos autorizados vão ao provedor que responder e podem ir aos seguintes se houver falha. Não envie dados sensíveis sem avaliar as políticas desses serviços. A consulta web separada envia termos de pesquisa conforme descrito abaixo.
7. Consulta de fontes pode levar até o orçamento de 20 segundos; cada tentativa de IA tem limite de 30 segundos. Tempos reais variam. Não houve benchmark de velocidade/qualidade no celular.
8. O modo rápido extrativo não substitui a IA quando o modo online está ativado. Para notícias e jogos a IA recebe as fontes obtidas; sem evidências deve informar a limitação. Ainda pode errar: confira fontes e datas.
9. Se todos falharem, o app pode usar o modelo local **já carregado**, conforme a opção. Ao abrir com IA online ativada, não carrega automaticamente os pesos locais, para evitar espera e RAM desnecessárias. Para operar offline, desative IA online e reinicie o app com o modelo importado.

A chamada online aceita até 200 mil caracteres por pedido e recusa excesso explicitamente. Não oferece contexto ilimitado, histórico automático ou ferramenta de navegação autônoma. Saída cortada por limite do provedor é identificada. Consulte os links oficiais no menu para criar suas próprias chaves; nunca envie chaves por conversa.

## Instalar ou atualizar no POCO F7 Pro com 12 GB de RAM

1. Instale `CodigoLivre-0.10.0-arm64.apk`. Esta entrega usa o mesmo pacote e a mesma assinatura das versões anteriores desta entrega disponibilizada neste repositório; instale por cima, sem desinstalar, para preservar modelo e última sessão. Faça uma cópia dos códigos importantes antes de atualizar. É uma versão experimental com assinatura de depuração, não uma publicação na Play Store.
2. O modelo **1,5B já importado continua funcionando**. Para melhorar a capacidade, experimente **Qwen2.5-Coder 3B Instruct GGUF Q4_K_M** (~2,1 GB). O **7B Q4_K_M** (~4,7 GB) é uma opção de maior capacidade para experimentar no aparelho de 12 GB, com maior consumo de RAM, espaço e tempo. Não foi medido no POCO nesta entrega. Feche outros aplicativos e o serviço mantém a análise ativa ao trocar de tela. A RAM física inclui a memória usada pelo Android; não confunda RAM expandida com memória física.
3. Reserve espaço para o arquivo baixado e a cópia privada. Durante a troca de modelo, o anterior também fica no disco até a importação terminar. O botão **Modelos de IA para 12 GB de RAM** mostra a memória disponível e abre os downloads oficiais. Depois, toque em **Importar modelo GGUF**. Desinstalar apaga modelo e sessão.
4. Ative o modo avião após importar o modelo. Selecione uma tarefa, descreva o pedido e importe ou cole um código. Autorize as notificações para acompanhar a análise ao trocar de aplicativo ou bloquear a tela.
5. Para dados, preencha **nome exato da aba/tabela**, **linha/registro inicial** e **quantidade de linhas** antes de abrir o arquivo. O nome vazio seleciona até 3 primeiras abas/tabelas. CSV não usa o filtro por nome. Confira a prévia e seus limites, escreva o que precisa avaliar e toque em **Processar no aparelho**.
6. **Salvar resposta e códigos em ZIP** salva a resposta completa e blocos de código. Os arquivos importados permanecem inalterados. Esta versão não grava correções diretamente nas planilhas ou bancos nem compila APK/EXE.

Há exemplos fictícios de XLSX, CSV e SQLite na pasta `examples` e no ZIP de exemplos da entrega. Descompacte antes de importar cada arquivo individualmente.

Downloads oficiais (internet apenas para obter os pesos):

- [3B Instruct Q4_K_M — recomendado inicialmente](https://huggingface.co/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/qwen2.5-coder-3b-instruct-q4_k_m.gguf?download=true)
- [7B Instruct Q4_K_M — maior capacidade e consumo](https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/resolve/main/qwen2.5-coder-7b-instruct-q4_k_m.gguf?download=true)

Não é necessário baixar os dois. Um modelo maior pode produzir melhores respostas em tarefas difíceis, mas quantidade de parâmetros não garante acerto. A escolha 3B inicial equilibra recursos e capacidade; o resultado real exige avaliação no celular. Esta versão não inclui o modelo no APK e não afirma ser a IA mais avançada disponível.

## Corrigir último jogo e resultados sem relação (novo na 0.9.0)

A pergunta **“último jogo do Flamengo”** não entrava na consulta esportiva anterior: o classificador reconhecia “joga” e referências ao próximo, mas não o caso literal “jogo” sem outra palavra reconhecida. A resposta rápida também aceitava qualquer passagem com alguma coincidência, mesmo sendo uma palavra temporal genérica. A imagem do Dicio reproduz essa falha de seleção.

- **Último jogo/última partida/placar/resultado**: consulta resultados do Flamengo, exige estado de encerramento, seleciona a data passada mais recente e mostra o placar disponível junto de adversário, competição, data e fonte.
- **Próximo jogo**: permanece separado, selecionando somente partidas futuras não encerradas. Jogos em andamento, adiados, cancelados ou abandonados não viram último resultado encerrado.
- Placar ausente recebe aviso, sem preencher números presumidos. Datas sem segundos continuam aceitas. As fontes continuam limitadas a competições/temporada consultadas e futebol masculino do time ESPN 819; não há garantia de cobertura de todos os campeonatos/categorias.
- Páginas genéricas passam por filtro de assunto. Palavras como último, próximo e hoje não bastam para tornar uma página relevante; nomes/tecnologias presentes na pergunta precisam aparecer na fonte. Entre as páginas aceitas, a de maior coincidência é preferida. Isso é um filtro lexical conservador, não validação semântica ou de veracidade: pode recusar páginas úteis e não garante eliminar toda irrelevância.
- Sem partida encerrada confirmada, informa a falta de confirmação. O calendário sem dados estruturados suficientes não é apresentado como resposta esportiva por meio de um trecho genérico.
- Testes reproduzem a pergunta exata e a rejeição da página sobre acento de último, incluindo uma consulta genérica sobre outro clube; também verificam placar, passado/futuro, jogo em andamento/cancelado e fonte sem placar. Não houve acesso ao vivo às fontes neste ambiente.

## Ler páginas e reduzir a espera (novo na 0.8.0)

- A consulta tenta **abrir até duas páginas públicas** dos resultados e extrair até 2400 caracteres do conteúdo principal de cada uma. Faz isso em paralelo, removendo navegação/scripts. Não executa JavaScript, não faz login e não tenta contornar HTTP 403, captcha ou acesso pago. A página pode estar incompleta, depender de JavaScript ou não ser legível.
- Novo padrão **Resposta online rápida · trecho da fonte, sem IA**: quando apropriado, devolve uma passagem do texto efetivamente lido, com origem, sem aguardar o Qwen 7B redigir uma síntese. É uma resposta extrativa, não uma interpretação garantida nem cobertura de todos os detalhes. Desative essa opção para gerar uma resposta mais elaborada com o modelo. Criação/correção de programas e análise de anexos continuam usando IA.
- O orçamento de coleta online é de aproximadamente **20 segundos**, com limite de aproximadamente 8 segundos por leitura HTTP/encadeamento de redirecionamentos. Ao esgotar a coleta, o app usa fontes parciais ou informa indisponibilidade. Esse orçamento **não limita o tempo de geração local da IA**, nem inclui carregamento do modelo ou instalação de ferramentas. Não houve medição no POCO para prometer um prazo exato.
- Corrigido o descarte de datas ISO válidas sem segundos (por exemplo, `2099-11-20T23:30Z`). O formato anterior aceitava apenas algumas representações, podendo eliminar partidas retornadas pela API. O teste reproduz a falha antiga e verifica o novo parser.
- O calendário pede jogos futuros (`fixture=true`) e distingue resposta sem lista de eventos de calendário válido vazio. Se a API não confirmar partida, abre o calendário HTML e tenta ler dados SportsEvent, microdados e estado JSON embutido (`__NEXT_DATA__`/`__espnfitt__`) sem executar scripts. Quando há partida futura confirmada, formata adversário, competição, data e horário diretamente.
- Se só houver texto legível do calendário, ele pode ser enviado ao modelo para interpretação; no modo rápido, pode devolver um trecho literal. Sem confirmação, não inventa o próximo jogo. Competições/temporadas não cobertas continuam sendo uma limitação.
- O leitor público valida HTTPS e DNS, recusa endereços locais/reservados e preserva conexões NAT64 para destinos públicos em redes móveis IPv6. Isso protege a rede local do aparelho, mas não certifica que uma fonte pública é verdadeira. Confira os links.

A foto enviada mostrou 3/4 fontes disponíveis, mas não contém o payload da API. O erro de datas é comprovado por regressão; **não é possível afirmar que ele era a única causa do problema no aparelho**. Os testes desta versão usam HTML/JSON/RSS simulados. O ambiente continua sem acesso aos provedores para validação ao vivo; a integração real ainda precisa ser confirmada no POCO.

## Notícias, jogos e programação com fontes online (novo na 0.7.0)

A opção **Consultar fontes online para melhorar a resposta** vem ativada nesta entrega, conforme solicitado. Pode ser desativada para usar apenas o modelo local. Na busca pública os anexos não são enviados; o envio à IA online depende da autorização separada. Para buscar fontes o app usa termos derivados do campo da pergunta, com até 240 caracteres. Pedidos que parecem conter código, ou são muito extensos, viram uma busca genérica por documentação/linguagens detectadas, em vez de enviar esse código como consulta literal. Isso é uma heurística, não um filtro garantido de dados pessoais digitados na pergunta.

- **“Últimas notícias no Brasil e no mundo”**: consulta feeds públicos do Google News por Brasil e Mundo, exibindo até 6 manchetes de cada, veículo, data retornada e link. A resposta é direta, sem esperar o modelo 7B resumir. A ordem editorial do agregador não garante que sejam as publicações mais recentes de toda a imprensa. Pode haver leitura parcial de até duas páginas públicas, sem garantia de acesso à matéria completa.
- **“Quando será o próximo jogo do Flamengo?”**: consulta os calendários públicos ESPN para Brasileirão, Copa do Brasil, Libertadores e Sul-Americana, na temporada do ano informado pelo relógio do aparelho. Filtra o time 819, partidas futuras e não adiadas/canceladas, escolhendo a menor data entre os resultados disponíveis. O texto diz **próximo jogo encontrado nas fontes consultadas**, informa as competições cobertas, o fuso de Brasília e um link para conferir. Não cobre necessariamente amistosos, Supercopa, Mundial, outras competições ou o ano seguinte. Se não conseguir confirmar, não inventa uma data.
- **Dúvidas de programação e outras perguntas**: usa resultados/trechos públicos da busca RSS do Bing como evidências para o modelo local, acrescentando os links à resposta. São lidos trechos de até duas páginas públicas; não é navegação integral em toda a documentação nem execução dos exemplos. Páginas podem estar desatualizadas e a IA ainda pode interpretar mal um trecho; confira as fontes e a versão da tecnologia.
- Notícias e calendário podem ser apresentados sem modelo carregado. Para sintetizar respostas e criar código, é necessário um modelo local; sem ele, a busca exibe apenas as fontes encontradas.
- Falhas de rede ou informações ausentes são mostradas no texto. Perguntas de informação atual sem confirmação não são respondidas como se o conhecimento antigo do modelo fosse atual. Consultas comuns podem usar o modelo local com aviso de indisponibilidade das fontes.
- Feeds/buscas usam Google News, Bing e ESPN, sem chave paga. A 0.8.0 também tenta abrir páginas HTTPS públicas dos resultados. Destinos internos/privados, portas alternativas e URLs com credenciais são recusados; o cliente conecta apenas aos IPs públicos validados. Redirecionamentos passam pela mesma validação. Os provedores podem alterar os endpoints, bloquear requisições ou não retornar dados. Cancelamento de uma requisição em leitura pode aguardar o timeout de rede.

**Validação limitada:** este ambiente bloqueou conexões aos provedores externos pelo proxy (HTTP CONNECT 403). Os testes dos leitores de RSS, seleção de partidas, termos de busca, falhas e cancelamento usam fontes simuladas. Não houve confirmação de funcionamento ao vivo desses endpoints nesta entrega; será necessário testar no smartphone. O app mostra indisponibilidade em vez de preencher dados não confirmados.

## Preparar ferramentas e gerar um APK no smartphone (novo na 0.7.0)

O botão **Preparar criação de APK no celular** abre os links oficiais do Termux e exporta `CodigoLivre-Android-Kit.zip`. Ele contém `preparar.sh`, `compilar.sh`, LEIA-ME e um projeto Java de exemplo. O Android exige confirmação para instalar Termux e APKs: o Código Livre não instala esses programas silenciosamente nem acessa seu aparelho remotamente.

1. Instale o Termux oficial pelo link do assistente e exporte o kit em Downloads.
2. No Termux, siga LEIA-ME: instale unzip, execute `termux-setup-storage` e conceda o acesso solicitado pelo Android.
3. O botão **Copiar preparação**, após exportar, facilita colar os comandos no Termux. O preparador instala OpenJDK 21, aapt/aapt2, D8, apksigner e utilitários pelos repositórios do Termux. Antes do SDK, pede aceitação dos termos oficiais do Google e valida o download da plataforma Android 35 por SHA256. Reserve pelo menos 2 GB livres e internet para os downloads iniciais.
4. Execute `compilar.sh` para gerar `projeto/saida/MeuApp.apk` e use `termux-open` para pedir a instalação. A chave de assinatura é gerada e preservada no armazenamento privado do Termux; não é a chave do assistente. Guarde backup seguro dessa chave e senha se quiser atualizar seus próprios apps.

**Escopo do kit:** apps Java simples com recursos Android; sem Gradle, Kotlin/Compose, bibliotecas externas ou NDK/C++. Não compila qualquer projeto Android nem o próprio Código Livre IA. O código deve usar APIs disponíveis na versão Android de destino; não use APIs de Java desktop. A IA pode ajudar a editar o exemplo, mas esta versão não converte automaticamente uma conversa em um projeto completo compilável.

O script do exemplo foi testado em Linux com JDK 17 e ferramentas SDK 35: compilação Java, recursos, DEX, alinhamento, assinatura e verificação concluíram com sucesso. Os pacotes oficiais Termux foram conferidos no repositório de origem, mas a instalação e a execução ARM64 no POCO ainda não foram testadas. Nenhuma ferramenta foi instalada no seu celular por esta entrega.

## Desempenho no POCO F7 Pro (novo na 0.6.0)

A imagem relatada pelo usuário mostrava um modelo 7B e quase sete minutos na primeira parte, antes de aparecer texto gerado. A versão anterior não mostrava o andamento do processamento inicial, apenas o número de partes concluídas. Isso não permite afirmar se todo o tempo era cálculo, memória ou outro gargalo no aparelho.

- Novo padrão **Rápido**, com trechos menores e respostas objetivas. **Longo** permanece disponível para maior detalhamento.
- O rodapé/notificação agora informa **leitura X/Y tokens** e a velocidade aproximada medida. Durante a resposta, mostra tokens gerados e tokens/s. O percentual geral continua contando partes concluídas, sem simular uma previsão de tempo restante.
- Reutilização do contexto alocado entre partes da mesma análise, com limpeza do KV antes de cada nova parte. Ao terminar/interromper, a memória do contexto é liberada; os pesos do modelo ficam disponíveis como antes.
- Prefill com batch de 512, microbatch de 256 e até 6 threads; geração usa até 4 threads. Compilação nativa RelWithDebInfo com `-O3`, mantendo ARMv8.2-A + dotprod, sem ativar instruções adicionais que possam faltar em outros aparelhos.
- O relatório de cada etapa termina com estatísticas medidas de leitura e geração. A taxa de geração considera as transições após o primeiro token; isso é diagnóstico local aproximado, não benchmark comparável entre aparelhos.
- Para velocidade, experimente **1,5B**; para equilibrar recursos e capacidade, **3B**. O **7B continua pesado para CPU de celular**, especialmente com arquivos extensos, e pode continuar lento nesta versão. Feche outros aplicativos e evite aquecimento. Esta entrega continua usando CPU, sem aceleração GPU/Vulkan.
- Modelos leves Geral/Coder de 1,5B (~1,1 GB) foram incluídos no menu. É necessário baixar/importar outro GGUF para trocar de modelo; escolher Rápido não transforma o 7B em um modelo menor.

Não medimos tempo/velocidade no POCO. Os testes cobrem políticas de divisão e compilação; o reuso de contexto e os callbacks JNI precisam de validação real com os pesos no aparelho. Não há promessa de redução por um fator específico nem de respostas instantâneas.

## Perguntas de assuntos gerais (novo na 0.5.0)

Selecione **Conversar / assuntos gerais**, digite a pergunta e toque em Processar. Não é obrigatório anexar código ou arquivo. O modo ajuda com estudos, textos, planejamento, ciências, história, tecnologia e dúvidas cotidianas. Cada pedido é independente; a sessão anterior fica salva, mas não é automaticamente enviada como histórico ao modelo.

O menu de modelos oferece **Geral 1,5B / Geral 3B / Geral 7B** (Qwen2.5 Instruct), além dos Coder. Os modelos gerais são mais versáteis para perguntas variadas. Coder prioriza programação; o arquivo já importado continua aceito. A importação troca o único modelo local ativo, preservando os demais dados. A qualidade depende do modelo e precisa ser avaliada no aparelho; nenhum modelo garante respostas corretas para qualquer pergunta. O modelo isolado não tem dados atuais. A opção online acrescenta fontes às respostas, sem garantir que todos os assuntos tenham cobertura ou confirmação.

## Atualizações no aplicativo (novo na 0.5.0)

1. Instale uma versão **0.5.0 ou superior manualmente uma vez**, por cima da anterior. As versões anteriores ainda não têm atualizador.
2. Abra **Atualizações do aplicativo** e use **Verificar agora**. Se quiser, ative **Verificar ao abrir**: a consulta ocorre ao iniciar/retornar ao app, no máximo uma tentativa automática por dia. A opção vem desativada. Não há verificação agendada com o app fechado.
3. Quando houver uma versão superior no canal público, toque em **Baixar**. Há uma barra própria de download. O app valida tamanho, SHA256, pacote, versão e assinatura do APK. O endereço deve ser HTTPS no repositório autorizado. Redirecionamentos não são seguidos pelo atualizador.
4. Toque em **Instalar**. O Android pode pedir para autorizar instalações a partir do Código Livre IA e depois solicitar confirmação. Não existe instalação silenciosa. O instalador substitui o pacote, preservando modelo e dados quando assinatura e pacote correspondem. A instalação fica bloqueada enquanto houver operação em andamento.
5. O APK baixado/verificado fica privado até instalar ou ser substituído. **Instalar baixada** aparece no menu se houver atualização disponível já obtida. Se sair da tela e o Android destruir a atividade durante o download, ele pode ser interrompido; nesse caso, tente baixar novamente.

O atualizador usa GET do índice público e do APK no GitHub; não envia perguntas ou arquivos. A consulta online, separadamente, envia termos da pergunta ao buscador. Para ficar inteiramente offline, desative Consultar fontes online e a verificação automática de versões e não use Verificar agora. A permissão INTERNET, por ser normal no Android, não apresenta diálogo próprio. REQUEST_INSTALL_PACKAGES não dispensa a autorização de origem nem a confirmação do instalador. Isso não atualiza os pesos GGUF automaticamente.

Para publicar versões futuras, copie o APK assinado para `entregas/`, mantenha a mesma chave, incremente versionCode/versionName e execute `python tools/write-update-index.py /caminho/do/APK`. Confira `update.json` e publique índice e APK no mesmo commit do canal `entrega/codigo-livre-android-offline`. O índice precisa ser mantido nas próximas entregas. Não publique a chave privada de assinatura. Esta versão experimental ainda usa a assinatura de teste já utilizada anteriormente.

## Progresso e segundo plano (novo na 0.4.0)

- Barra fixa no rodapé, indicador de atividade e tempo decorrido. Durante leitura, preparo ou uma resposta única, aparece uma animação. Em trabalhos divididos, o percentual corresponde às **partes finalizadas**, não ao tempo restante. Uma única parte pode ficar em 0% até terminar; o indicador de atividade continua animado.
- Ao sair da tela, a análise continua em um serviço Android de primeiro plano com notificação. A notificação mostra a etapa, a cobertura e o botão **Interromper**. Tocar nela retorna à tela com a resposta em andamento, em vez de iniciar nova análise.
- Permita **Notificações** quando solicitado. Se forem negadas, o serviço ainda pode executar, mas a notificação não será mostrada normalmente na gaveta. O Android pode mostrá-lo apenas nos aplicativos ativos.
- No POCO/HyperOS, se o sistema ainda suspender a execução, procure **Configurações → Aplicativos → Código Livre IA → Bateria → Sem restrições** (o nome/caminho pode variar). Isso não impede encerramento forçado pelo usuário ou por falta de memória.
- Acordar CPU enquanto o serviço está ativo evita suspensão durante inferência. Isso consome bateria e pode aquecer o aparelho; o botão Interromper continua disponível.
- Resultado parcial é salvo no armazenamento privado aproximadamente a cada 3 segundos durante as atualizações, e ao terminar. Ao reabrir a tela, o app recupera a análise ativa ou o último resultado salvo.
- Se o processo for encerrado pelo Android, pelo usuário, por reinício ou por falta de memória, não há retomada automática do cálculo. O último checkpoint disponível é recuperado com aviso de análise incompleta. A estrutura do serviço não garante execução ilimitada: no Android 15, serviços `dataSync` estão sujeitos à cota de tempo do sistema (até 6 horas em uma janela de 24 horas enquanto em segundo plano). Ao receber timeout, o app solicita interrupção e salva o resultado disponível.
- As permissões de serviço de primeiro plano/dataSync, CPU ativa (`WAKE_LOCK`) e notificações permitem o processamento local em segundo plano. A 0.5.0 acrescenta INTERNET e REQUEST_INSTALL_PACKAGES para o atualizador opcional. Nenhuma permissão de acesso amplo aos arquivos foi adicionada.

## Formatos e escopo real

| Formato | Conteúdo disponibilizado à IA | Limites |
| --- | --- | --- |
| BAS/CLS, PS1, Python, Java, JS, SQL e demais textos aceitos | Código-fonte selecionado | 8 MiB por arquivo; não executa nem compila |
| ZIP de código | Arquivos-fonte com seus nomes | Até 200 entradas e 8 MiB descompactados no conjunto; não processa planilhas/bancos binários dentro do ZIP |
| CSV/TSV | Faixa de registros lógicos; contagens e quantidade de campos por registro | Até 2 MiB; aspas, quebras dentro de campos e Windows-1252 aceitos; não presume cabeçalho |
| XLSX/XLSM | Nomes de abas, contagens de linhas/células/fórmulas e amostra por aba | Até 3 abas; nome exato seleciona outra; colunas A a L; fórmulas e valores salvos, sem recálculo |
| SQLite `.db`, `.sqlite`, `.sqlite3` | Verificação estrutural rápida, DDL, colunas/tipos/restrições, contagem e amostras | Cópia independente de até 32 MiB; até 200 tabelas no banco, 3 por importação, 12 colunas por amostra; aberto somente leitura |
| Access ACCDB/MDB | Não aberto diretamente | Exporte tabelas em CSV, esquema em SQL e módulos em BAS/CLS |
| XLS antigo, PDF, imagens, bancos criptografados | Não abertos diretamente | Salve XLS como XLSX; envie os outros conteúdos em formatos suportados |

### Como interpretar a prévia

- Padrão: 8 linhas por aba/tabela; ajustável entre 1 e 30, início entre 1 e 100000. Em XLSX o número é a linha do Excel; em CSV é o registro lógico; no SQLite é a posição após a ordenação informada.
- Cada valor é abreviado a 160 caracteres, com aviso. A prévia completa fica limitada a 5000 caracteres, com aviso explícito quando houver informações não incluídas. Revise a seleção ou importe outra faixa para aprofundar a análise. As prévias de planilhas/bancos continuam amostrais. A análise em partes se aplica ao texto efetivamente importado/colado, não lê automaticamente linhas de dados que ficaram fora da prévia.
- No XLSX, contagens são feitas nas células XML das abas selecionadas, incluindo células vazias/formatadas presentes no arquivo. Fórmulas compartilhadas sem expressão local recebem aviso e não são expandidas. Datas numéricas permanecem seriais; os estilos não são interpretados. Macros VBA, imagens, gráficos, conexões e regras de formatação não são analisados. Partes ZIP são limitadas a 8 MiB cada, 64 MiB descompactados no total e 1000 entradas; XML deve ser UTF-8 e não conter DTD/entidades.
- No SQLite, `quick_check(1)=ok` indica apenas a verificação estrutural rápida. Não verifica chaves estrangeiras, regras de negócio ou completude da exportação. DDL é abreviado a 1000 caracteres. A prévia ordena pela chave primária, ou por até 12 colunas quando não houver PK. Views, gatilhos, índices e tabelas fora da seleção não são analisados. BLOBs são omitidos.
- **Não copie apenas o `.db` de um SQLite em uso.** Gere uma exportação independente com a ferramenta de origem. Bancos marcados como WAL são recusados, mesmo se aparentarem estar completos, porque o app não recebe os arquivos auxiliares. Em uma cópia consistente, encerre conexões e use `PRAGMA journal_mode=DELETE` pela ferramenta apropriada antes de importar. O app não executa essa mudança no arquivo recebido.

## IA e dados locais

A IA recebe somente o texto visível importado e o pedido. O prompt a orienta a separar evidências, hipóteses e limites, mas isso não garante que ela siga todas as orientações. Nenhuma IA garante ausência de erros. Revise códigos e cálculos no ambiente apropriado antes de usar as sugestões.

O bloqueio de **30 mil caracteres foi removido**. O aplicativo conta os tokens com o tokenizador do modelo e distribui pedidos extensos em etapas de até **8192 tokens**, respeitando a capacidade declarada pelo modelo. Não há uma cota total de tokens por análise definida pelo aplicativo. A memória, o tempo, a janela de contexto por etapa e os limites de importação continuam finitos.

Na 0.6.0, o padrão passa a ser o perfil **Rápido**. Não é um limite total de tamanho da análise: o texto continua sendo dividido com cobertura informada. Os perfis controlam o trabalho e a resposta de cada etapa:

| Perfil | Contexto por etapa | Saída por etapa | Reserva de planejamento |
| --- | --- | --- | --- |
| Rápido | até 3072 tokens | até 768 tokens | 768 tokens |
| Equilibrado | até 4096 tokens | até 1536 tokens | 1536 tokens |
| Longo | até 8192 tokens | até o espaço restante | 2048 tokens |

O perfil Longo mantém a opção de resposta automática extensa anterior. Respostas cortadas recebem aviso. O Rápido reduz o volume antes da primeira resposta e usa menos contexto, mas pode aumentar o número de partes e repetir mais cabeçalhos; **não há garantia de redução do tempo total**. A qualidade/detalhamento também dependem do perfil. A janela do modelo e a RAM continuam finitas.


Para textos extensos, o relatório preserva as respostas por parte, mostra os intervalos de caracteres e informa a quantidade concluída. Não faz fusão automática de correções nem garante que relações entre trechos foram revisadas. Um trecho pode começar ou terminar no meio de uma função. Pedidos grandes também podem ser distribuídos; o objetivo curto é repetido nos cabeçalhos, mas instruções extensas podem estar em partes diferentes. Falhas ou interrupções deixam a cobertura marcada como incompleta. Arquivos grandes podem exigir muitos minutos ou horas de processamento local. O botão **Interromper geração**, ou **Interromper** na notificação, também cancela o planejamento.


Apenas a **última sessão** é preservada no armazenamento privado: pedido, código/prévia, resposta e opções de seleção. A resposta anterior não é automaticamente adicionada ao contexto de uma nova solicitação. Limpar sessão apaga o histórico local, preservando o modelo. Não há anúncios, telemetria ou criptografia adicional específica do app. Backup Android e transferência automática estão desabilitados. As cópias temporárias de SQLite são apagadas ao finalizar a leitura; uma interrupção abrupta do processo pode deixar uma cópia no cache privado, que pode ser removido nas configurações do Android.

## Compilar e testar

JDK 17, Gradle 8.11.1, SDK Android 35, Build Tools 35.0.0, NDK 27.2.12479018 e CMake 3.22.1. As ferramentas e os testes exigem internet durante a preparação. A inferência pode ser local ou online; atualizador e consultas usam a rede conforme as opções escolhidas.

```sh
bash tools/prepare-engine.sh
# local.properties: sdk.dir=/caminho/para/android-sdk
bash tools/test-core.sh
gradle assembleRelease lintRelease
```

O leitor usa jsoup (MIT), OkHttp/Okio e Kotlin (Apache-2.0); licenças e aviso da Public Suffix List (MPL-2.0) estão incluídos em assets/licenses.

Motor fixado em `ENGINE_REVISION` (upstream b5046). Testes de CSV/XLSX são JVM; testes de SQLite usam JDBC nativo Linux e as mesmas consultas do resumo. JDBC e SLF4J são dependências exclusivamente dos testes e **não entram no APK**. O adaptador SQLite Android, o fluxo de arquivos e a inferência real precisam de validação física. Os testes da análise em partes usam um motor simulado para verificar cobertura, cancelamento e limites; não são uma medição de inferência real. O APK fica em `app/build/outputs/apk/release/app-release.apk`.

Somente ARM64 com ARMv8.2-A + dotprod, adequado ao POCO F7 Pro, Android 9 ou posterior. Código sob MIT; licenças do llama.cpp e runtime LLVM incluídas em `assets/licenses`. Pesos de IA têm licença própria do fornecedor.
