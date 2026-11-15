# Código Livre IA — Android offline (0.1.0 experimental)

Assistente de programação em português, com inferência local via llama.cpp. Não exige conta, chave de API ou mensalidade. O aplicativo não declara a permissão INTERNET. O download do APK e dos pesos do modelo precisa ser feito previamente pelo navegador ou transferido por USB.

## Instalar e começar no POCO F7 Pro

1. Instale `CodigoLivre-0.1.0-arm64.apk`. É uma versão experimental com assinatura de depuração; o Android solicitará autorização para instalar o APK a partir do navegador/gerenciador de arquivos escolhido.
2. Baixe o modelo **Qwen2.5-Coder-1.5B-Instruct-GGUF**, arquivo **Q4_K_M**, do repositório oficial: https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/tree/main . O arquivo ocupa aproximadamente 1,1 GB. Confira o nome e a licença na página do modelo. Não baixe um arquivo `.safetensors` para este app.
3. Reserve pelo menos 3 GB livres para o download, a cópia privada do modelo e a sessão. Toque em **Importar modelo GGUF** e selecione o arquivo. A importação pode demorar. Depois de conferir que carregou, a cópia em Downloads pode ser removida para liberar espaço; o app mantém sua própria cópia.
4. Ative o modo avião. Descreva um pedido pequeno, por exemplo: “Crie uma função Python que valide uma data no formato dd/mm/aaaa”. Selecione **Criar programa** e toque em **Processar no aparelho**.
5. Para revisar um código, cole o texto ou abra um arquivo/ZIP, selecione Analisar, Corrigir ou Explicar e descreva o problema. A resposta aparece gradualmente. Mantenha o app aberto durante o cálculo.
6. Use **Salvar resposta e códigos em ZIP** e escolha uma pasta no seletor do Android. O ZIP inclui a resposta completa e os blocos Markdown de código numerados por linguagem.

O POCO F7 Pro possui hardware adequado para experimentar modelos pequenos. A velocidade, a qualidade das respostas, o aquecimento e a RAM efetivamente disponível ainda precisam ser medidos no aparelho. O modelo de 1,5B é o ponto de partida, não garantia de desempenho ou qualidade para projetos complexos. Um modelo 3B Q4 pode ser experimentado depois, com maior uso de memória; não foi validado nesta entrega.

## Funcionalidades desta versão

- Interface nativa Android com quatro tarefas: análise, correção, criação e explicação.
- Motor CPU ARM64 integrado; não usa servidor, Ollama ou serviços externos.
- Importação de arquivos-fonte, incluindo BAS/CLS do Access e PowerShell, em UTF-8 ou Windows-1252.
- Importação de ZIP sem extrair os arquivos no armazenamento. Exibe os nomes junto ao conteúdo.
- Resposta incremental, botão de interrupção e escolha entre 512, 1024 e 1536 tokens de saída.
- Exportação em ZIP pelo seletor de documentos do Android.
- Recuperação da **última sessão**: pedido, código, resposta e opções ficam no armazenamento privado do app. Limpar sessão apaga esses dados, preservando o modelo. Desinstalar apaga ambos. O backup Android está desativado.

## Limites e cuidados de uso

- Nenhuma IA domina todas as linguagens ou garante ausência de erros. As sugestões precisam de revisão e testes no ambiente correto.
- Esta versão não executa, compila, instala nem testa automaticamente os programas produzidos. Ela gera código-fonte; não transforma projetos em APK/EXE.
- Não abre diretamente bancos ACCDB, executáveis ou PDFs. Exporte os módulos BAS/CLS ou cole o código.
- Contexto total de **4096 tokens**, incluindo instruções, arquivos, pedido e resposta. Se o conteúdo não couber, a geração é recusada com uma mensagem; nenhum trecho é silenciosamente omitido. Reduza o pedido ou divida o projeto. Não existe análise automática de projetos grandes em partes nesta versão.
- ZIP: no máximo 200 entradas e 256 KiB descompactados no conjunto (inclusive arquivos ignorados). Arquivos individuais: 256 KiB. Há também limite de 30 mil caracteres na solicitação antes da tokenização.
- O app envia uma solicitação independente a cada processamento. A resposta anterior é preservada na sessão, mas não é acrescentada automaticamente como histórico de conversa ao modelo.
- Uma resposta cortada pelo limite ou pelo botão Interromper recebe um aviso de que pode estar incompleta. Não use um código incompleto sem revisão.
- Não modifica os arquivos importados. Modelos de IA ainda podem seguir instruções indesejadas contidas em comentários; a revisão do usuário permanece necessária.
- O modelo copiado não é criptografado pelo app. Código e última resposta ficam privados por isolamento do Android, sem criptografia adicional específica do aplicativo.
- Somente ARM64 com instruções ARMv8.2-A + dotprod, adequadas ao POCO F7 Pro. Android 9 ou posterior. Não é um APK universal para qualquer telefone.

## Compilar a partir do código

Pré-requisitos: JDK 17, Gradle 8.11.1, SDK Android 35, Build Tools 35.0.0, NDK 27.2.12479018 e CMake 3.22.1. A compilação exige internet para baixar ferramentas e o motor; o aplicativo instalado funciona offline.

```sh
bash tools/prepare-engine.sh
# Configure o SDK em local.properties: sdk.dir=/caminho/para/android-sdk
gradle assembleRelease lintRelease
```

O motor fica fixado pela revisão em `ENGINE_REVISION` (tag upstream b5046). A pasta `third_party` é baixada durante o preparo e não deve conter modelos. O APK fica em `app/build/outputs/apk/release/app-release.apk`.

Testes de arquivos, sem Android:

```sh
mkdir -p build/core-tests
javac -d build/core-tests app/src/main/java/br/com/arakaki/codigolivre/CodeFiles.java tests/CodeFilesTest.java
java -cp build/core-tests br.com.arakaki.codigolivre.CodeFilesTest
```

## Privacidade e licenças

Não há anúncios, telemetria, contas ou chamadas de rede no app. O seletor de arquivos dá acesso apenas aos documentos escolhidos pelo usuário. A interface e o código desta pasta são disponibilizados sob a licença MIT em `LICENSE`. O motor llama.cpp é MIT; sua licença está incluída em `THIRD_PARTY_NOTICES.txt`. Os pesos de IA não estão incluídos no APK e têm sua própria licença indicada pelo fornecedor.

Esta entrega precisa de validação funcional no POCO: carregar modelo real, gerar e interromper resposta, testar modo avião, exportar ZIP e reabrir a última sessão. Compilar o APK e passar nos testes estáticos não substitui esse teste físico.
