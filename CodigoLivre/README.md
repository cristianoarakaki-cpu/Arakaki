# Código Livre IA — Android offline (0.5.0 experimental)

Assistente em português para programação, planilhas e dados, com inferência local via llama.cpp. Sem conta, chave de API ou mensalidade. A IA continua offline. A partir da 0.5.0, o APK possui permissão INTERNET exclusivamente para consultar e baixar atualizações opcionais do GitHub; perguntas, arquivos e respostas não são enviados por esse recurso. Pesos do modelo e APK são baixados previamente pelo navegador ou transferidos por USB. Os botões de download de modelos apenas abrem o navegador externo após um toque do usuário.

## Instalar ou atualizar no POCO F7 Pro com 12 GB de RAM

1. Instale `CodigoLivre-0.5.0-arm64.apk`. Esta entrega usa o mesmo pacote e a mesma assinatura das versões anteriores desta entrega disponibilizada neste repositório; instale por cima, sem desinstalar, para preservar modelo e última sessão. Faça uma cópia dos códigos importantes antes de atualizar. É uma versão experimental com assinatura de depuração, não uma publicação na Play Store.
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

## Perguntas de assuntos gerais (novo na 0.5.0)

Selecione **Conversar / assuntos gerais**, digite a pergunta e toque em Processar. Não é obrigatório anexar código ou arquivo. O modo ajuda com estudos, textos, planejamento, ciências, história, tecnologia e dúvidas cotidianas. Cada pedido é independente; a sessão anterior fica salva, mas não é automaticamente enviada como histórico ao modelo.

O menu de modelos oferece **Geral 3B / Geral 7B** (Qwen2.5 Instruct), além dos Coder. Os modelos gerais são mais versáteis para perguntas variadas. Coder prioriza programação; o arquivo já importado continua aceito. A importação troca o único modelo local ativo, preservando os demais dados. A qualidade depende do modelo e precisa ser avaliada no aparelho; nenhum modelo garante respostas corretas para qualquer pergunta. Sem navegação na IA, não há notícias, preços, pesquisa online ou confirmação de fatos em tempo real.

## Atualizações no aplicativo (novo na 0.5.0)

1. Instale a **0.5.0 manualmente uma vez**, por cima da anterior. As versões anteriores ainda não têm atualizador.
2. Abra **Atualizações do aplicativo** e use **Verificar agora**. Se quiser, ative **Verificar ao abrir**: a consulta ocorre ao iniciar/retornar ao app, no máximo uma tentativa automática por dia. A opção vem desativada. Não há verificação agendada com o app fechado.
3. Quando houver uma versão superior no canal público, toque em **Baixar**. Há uma barra própria de download. O app valida tamanho, SHA256, pacote, versão e assinatura do APK. O endereço deve ser HTTPS no repositório autorizado. Redirecionamentos não são seguidos pelo atualizador.
4. Toque em **Instalar**. O Android pode pedir para autorizar instalações a partir do Código Livre IA e depois solicitar confirmação. Não existe instalação silenciosa. O instalador substitui o pacote, preservando modelo e dados quando assinatura e pacote correspondem. A instalação fica bloqueada enquanto houver operação em andamento.
5. O APK baixado/verificado fica privado até instalar ou ser substituído. **Instalar baixada** aparece no menu se houver atualização disponível já obtida. Se sair da tela e o Android destruir a atividade durante o download, ele pode ser interrompido; nesse caso, tente baixar novamente.

A rede é usada somente para GET do índice público e do APK no GitHub; não há conta, chave de API ou envio de conteúdo do usuário. Desativar a verificação automática e não usar Verificar agora mantém a IA funcionando sem precisar de rede. A permissão INTERNET, por ser normal no Android, não apresenta diálogo próprio. REQUEST_INSTALL_PACKAGES não dispensa a autorização de origem nem a confirmação do instalador. Isso não atualiza os pesos GGUF automaticamente.

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

No modo **Automático**, cada resposta pode ocupar todo o contexto restante da etapa; a geração encerra quando o modelo indica fim, quando esse espaço acaba ou quando o usuário interrompe. No modo **Econômico**, cada resposta usa até 1024 tokens. Não existe saída infinita. A reserva de planejamento deixa pelo menos 2048 tokens para a resposta por etapa. A ampliação de 4K para até 8K pode consumir mais memória, especialmente no modelo 7B.

Para textos extensos, o relatório preserva as respostas por parte, mostra os intervalos de caracteres e informa a quantidade concluída. Não faz fusão automática de correções nem garante que relações entre trechos foram revisadas. Um trecho pode começar ou terminar no meio de uma função. Pedidos grandes também podem ser distribuídos; o objetivo curto é repetido nos cabeçalhos, mas instruções extensas podem estar em partes diferentes. Falhas ou interrupções deixam a cobertura marcada como incompleta. Arquivos grandes podem exigir muitos minutos ou horas de processamento local. O botão **Interromper geração**, ou **Interromper** na notificação, também cancela o planejamento.


Apenas a **última sessão** é preservada no armazenamento privado: pedido, código/prévia, resposta e opções de seleção. A resposta anterior não é automaticamente adicionada ao contexto de uma nova solicitação. Limpar sessão apaga o histórico local, preservando o modelo. Não há anúncios, telemetria ou criptografia adicional específica do app. Backup Android e transferência automática estão desabilitados. As cópias temporárias de SQLite são apagadas ao finalizar a leitura; uma interrupção abrupta do processo pode deixar uma cópia no cache privado, que pode ser removido nas configurações do Android.

## Compilar e testar

JDK 17, Gradle 8.11.1, SDK Android 35, Build Tools 35.0.0, NDK 27.2.12479018 e CMake 3.22.1. As ferramentas e os testes exigem internet durante a preparação. A inferência continua offline; o atualizador é o único componente de rede do app.

```sh
bash tools/prepare-engine.sh
# local.properties: sdk.dir=/caminho/para/android-sdk
bash tools/test-core.sh
gradle assembleRelease lintRelease
```

Motor fixado em `ENGINE_REVISION` (upstream b5046). Testes de CSV/XLSX são JVM; testes de SQLite usam JDBC nativo Linux e as mesmas consultas do resumo. JDBC e SLF4J são dependências exclusivamente dos testes e **não entram no APK**. O adaptador SQLite Android, o fluxo de arquivos e a inferência real precisam de validação física. Os testes da análise em partes usam um motor simulado para verificar cobertura, cancelamento e limites; não são uma medição de inferência real. O APK fica em `app/build/outputs/apk/release/app-release.apk`.

Somente ARM64 com ARMv8.2-A + dotprod, adequado ao POCO F7 Pro, Android 9 ou posterior. Código sob MIT; licenças do llama.cpp e runtime LLVM incluídas em `assets/licenses`. Pesos de IA têm licença própria do fornecedor.
