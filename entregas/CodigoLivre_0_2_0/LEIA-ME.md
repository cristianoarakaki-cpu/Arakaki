# Código Livre IA — Android offline (0.2.0 experimental)

Assistente em português para programação, planilhas e dados, com inferência local via llama.cpp. Sem conta, chave de API ou mensalidade. O APK não solicita a permissão INTERNET. Pesos do modelo e APK são baixados previamente pelo navegador ou transferidos por USB. Os botões de download de modelos apenas abrem o navegador externo após um toque do usuário.

## Instalar ou atualizar no POCO F7 Pro com 12 GB de RAM

1. Instale `CodigoLivre-0.2.0-arm64.apk`. Esta entrega usa o mesmo pacote e a mesma assinatura da 0.1.0 disponibilizada neste repositório; instale por cima, sem desinstalar, para preservar modelo e última sessão. Faça uma cópia dos códigos importantes antes de atualizar. É uma versão experimental com assinatura de depuração, não uma publicação na Play Store.
2. O modelo **1,5B já importado continua funcionando**. Para melhorar a capacidade, experimente **Qwen2.5-Coder 3B Instruct GGUF Q4_K_M** (~2,1 GB). O **7B Q4_K_M** (~4,7 GB) é uma opção de maior capacidade para experimentar no aparelho de 12 GB, com maior consumo de RAM, espaço e tempo. Não foi medido no POCO nesta entrega. Feche outros aplicativos e mantenha o app em primeiro plano. A RAM física inclui a memória usada pelo Android; não confunda RAM expandida com memória física.
3. Reserve espaço para o arquivo baixado e a cópia privada. Durante a troca de modelo, o anterior também fica no disco até a importação terminar. O botão **Modelos de IA para 12 GB de RAM** mostra a memória disponível e abre os downloads oficiais. Depois, toque em **Importar modelo GGUF**. Desinstalar apaga modelo e sessão.
4. Ative o modo avião após importar o modelo. Selecione uma tarefa, descreva o pedido e importe ou cole um código. Mantenha a tela do app aberta durante a geração.
5. Para dados, preencha **nome exato da aba/tabela**, **linha/registro inicial** e **quantidade de linhas** antes de abrir o arquivo. O nome vazio seleciona até 3 primeiras abas/tabelas. CSV não usa o filtro por nome. Confira a prévia e seus limites, escreva o que precisa avaliar e toque em **Processar no aparelho**.
6. **Salvar resposta e códigos em ZIP** salva a resposta completa e blocos de código. Os arquivos importados permanecem inalterados. Esta versão não grava correções diretamente nas planilhas ou bancos nem compila APK/EXE.

Há exemplos fictícios de XLSX, CSV e SQLite na pasta `examples` e no ZIP de exemplos da entrega. Descompacte antes de importar cada arquivo individualmente.

Downloads oficiais (internet apenas para obter os pesos):

- [3B Instruct Q4_K_M — recomendado inicialmente](https://huggingface.co/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/qwen2.5-coder-3b-instruct-q4_k_m.gguf?download=true)
- [7B Instruct Q4_K_M — maior capacidade e consumo](https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/resolve/main/qwen2.5-coder-7b-instruct-q4_k_m.gguf?download=true)

Não é necessário baixar os dois. Um modelo maior pode produzir melhores respostas em tarefas difíceis, mas quantidade de parâmetros não garante acerto. A escolha 3B inicial equilibra recursos e capacidade; o resultado real exige avaliação no celular. Esta versão não inclui o modelo no APK e não afirma ser a IA mais avançada disponível.

## Formatos e escopo real

| Formato | Conteúdo disponibilizado à IA | Limites |
| --- | --- | --- |
| BAS/CLS, PS1, Python, Java, JS, SQL e demais textos aceitos | Código-fonte selecionado | 256 KiB por arquivo; não executa nem compila |
| ZIP de código | Arquivos-fonte com seus nomes | Até 200 entradas e 256 KiB descompactados no conjunto; não processa planilhas/bancos binários dentro do ZIP |
| CSV/TSV | Faixa de registros lógicos; contagens e quantidade de campos por registro | Até 2 MiB; aspas, quebras dentro de campos e Windows-1252 aceitos; não presume cabeçalho |
| XLSX/XLSM | Nomes de abas, contagens de linhas/células/fórmulas e amostra por aba | Até 3 abas; nome exato seleciona outra; colunas A a L; fórmulas e valores salvos, sem recálculo |
| SQLite `.db`, `.sqlite`, `.sqlite3` | Verificação estrutural rápida, DDL, colunas/tipos/restrições, contagem e amostras | Cópia independente de até 32 MiB; até 200 tabelas no banco, 3 por importação, 12 colunas por amostra; aberto somente leitura |
| Access ACCDB/MDB | Não aberto diretamente | Exporte tabelas em CSV, esquema em SQL e módulos em BAS/CLS |
| XLS antigo, PDF, imagens, bancos criptografados | Não abertos diretamente | Salve XLS como XLSX; envie os outros conteúdos em formatos suportados |

### Como interpretar a prévia

- Padrão: 8 linhas por aba/tabela; ajustável entre 1 e 30, início entre 1 e 100000. Em XLSX o número é a linha do Excel; em CSV é o registro lógico; no SQLite é a posição após a ordenação informada.
- Cada valor é abreviado a 160 caracteres, com aviso. A prévia completa fica limitada a 5000 caracteres, com aviso explícito quando houver informações não incluídas. Revise a seleção ou importe outra faixa para aprofundar a análise. Não existe varredura automática em partes por IA nesta versão.
- No XLSX, contagens são feitas nas células XML das abas selecionadas, incluindo células vazias/formatadas presentes no arquivo. Fórmulas compartilhadas sem expressão local recebem aviso e não são expandidas. Datas numéricas permanecem seriais; os estilos não são interpretados. Macros VBA, imagens, gráficos, conexões e regras de formatação não são analisados. Partes ZIP são limitadas a 8 MiB cada, 64 MiB descompactados no total e 1000 entradas; XML deve ser UTF-8 e não conter DTD/entidades.
- No SQLite, `quick_check(1)=ok` indica apenas a verificação estrutural rápida. Não verifica chaves estrangeiras, regras de negócio ou completude da exportação. DDL é abreviado a 1000 caracteres. A prévia ordena pela chave primária, ou por até 12 colunas quando não houver PK. Views, gatilhos, índices e tabelas fora da seleção não são analisados. BLOBs são omitidos.
- **Não copie apenas o `.db` de um SQLite em uso.** Gere uma exportação independente com a ferramenta de origem. Bancos marcados como WAL são recusados, mesmo se aparentarem estar completos, porque o app não recebe os arquivos auxiliares. Em uma cópia consistente, encerre conexões e use `PRAGMA journal_mode=DELETE` pela ferramenta apropriada antes de importar. O app não executa essa mudança no arquivo recebido.

## IA e dados locais

A IA recebe somente o texto visível importado e o pedido. O prompt a orienta a separar evidências, hipóteses e limites, mas isso não garante que ela siga todas as orientações. Nenhuma IA garante ausência de erros. Revise códigos e cálculos no ambiente apropriado antes de usar as sugestões.

O contexto total é de **4096 tokens**, incluindo instruções, prévia/código, pedido e resposta (512, 1024 ou 1536 tokens). Conteúdo que não couber é recusado; reduza a faixa ou envie uma função menor. O limite preliminar da solicitação é 30 mil caracteres. Respostas interrompidas/cortadas recebem aviso.

Apenas a **última sessão** é preservada no armazenamento privado: pedido, código/prévia, resposta e opções de seleção. A resposta anterior não é automaticamente adicionada ao contexto de uma nova solicitação. Limpar sessão apaga o histórico local, preservando o modelo. Não há anúncios, telemetria ou criptografia adicional específica do app. Backup Android e transferência automática estão desabilitados. As cópias temporárias de SQLite são apagadas ao finalizar a leitura; uma interrupção abrupta do processo pode deixar uma cópia no cache privado, que pode ser removido nas configurações do Android.

## Compilar e testar

JDK 17, Gradle 8.11.1, SDK Android 35, Build Tools 35.0.0, NDK 27.2.12479018 e CMake 3.22.1. As ferramentas e os testes exigem internet durante a preparação. O APK continua offline.

```sh
bash tools/prepare-engine.sh
# local.properties: sdk.dir=/caminho/para/android-sdk
bash tools/test-core.sh
gradle assembleRelease lintRelease
```

Motor fixado em `ENGINE_REVISION` (upstream b5046). Testes de CSV/XLSX são JVM; testes de SQLite usam JDBC nativo Linux e as mesmas consultas do resumo. JDBC e SLF4J são dependências exclusivamente dos testes e **não entram no APK**. O adaptador SQLite Android, o fluxo de arquivos e a inferência real precisam de validação física. O APK fica em `app/build/outputs/apk/release/app-release.apk`.

Somente ARM64 com ARMv8.2-A + dotprod, adequado ao POCO F7 Pro, Android 9 ou posterior. Código sob MIT; licenças do llama.cpp e runtime LLVM incluídas em `assets/licenses`. Pesos de IA têm licença própria do fornecedor.
