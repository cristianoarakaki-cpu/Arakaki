# Assinatura permanente e continuidade

O APK original 1.9.3 e o APK Teste 1.9.4 têm pacotes e assinaturas diferentes. Instalar e testar o app não recupera suas chaves privadas.

| Instalação | Pacote | Situação da chave |
|---|---|---|
| Plus original 1.9.3 | `com.folha.pd2` | Precisa localizar o keystore original |
| Plus Teste 1.9.4 | `com.folha.pd2.dev` | Chave temporária da compilação anterior não foi preservada |

A chave da edição de teste não está no artifact nem no APK. Não prometemos uma atualização sobre essa edição com uma chave diferente. Não desinstale o aplicativo nem limpe seus dados para tentar corrigir assinatura. Exporte os PDFs importantes da biblioteca antes de qualquer migração futura.

## Se tiver a chave original

No seu computador de confiança, com Python 3, um JDK e GitHub CLI instalados:

    gh auth login
    python3 FPlus/signing/configure.py --keystore CAMINHO_DO_ARQUIVO.jks --alias ALIAS_DA_CHAVE --check-only

A opção `--check-only` valida o certificado sem escrever no GitHub. Ao executar sem essa opção, o programa gravará os secrets na sua conta GitHub. As senhas são solicitadas com entrada oculta. O programa confere o certificado, testa o acesso à chave privada e confirma a conta antes de escrever os quatro secrets `FPLUS_*` no repositório correto. Se houver erro parcial de gravação, execute novamente.

Não envie senhas no chat e não publique keystores, arquivos de senha ou base64 da chave no repositório. Guarde um backup privado da chave e das senhas: GitHub Secrets não permite recuperar esses valores pela interface depois.

## Se não tiver a chave original

Uma chave nova não atualiza o pacote original preservando a assinatura. Precisamos planejar uma migração para outra instalação e transferir os documentos. O app atual permanece utilizável. Não foi criada ou publicada uma nova identidade de produção sem resolver essa migração.

## Compilações daqui em diante

Sem os quatro secrets de assinatura original configurados, a Action valida o código e produz apenas um arquivo **não assinado, não instalável** (`.apk.unsigned`). Não gera outra chave descartável nem substitui o download do teste validado no celular. Com os quatro secrets, a Action pode compilar, verificar a assinatura original e publicar a versão oficial com aumento de versão.

O helper precisa ser executado pelo proprietário: a conexão GitHub deste atendimento não fornece operação para cadastrar secrets do repositório. O fluxo de assinatura e publicação já está preparado; a ativação real depende do keystore e das senhas corretos.
