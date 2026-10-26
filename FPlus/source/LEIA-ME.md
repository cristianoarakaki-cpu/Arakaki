# Projeto Android reconstruído do Folha PDF+

Base nativa adaptada de `Folha/source` e interface recuperada do APK 1.9.3. Este é um projeto reconstruído, não o código Java original recuperado por descompilação. As ferramentas de PDF existentes foram mantidas. Versão de desenvolvimento: 1.9.4 (16).

## Compilação

A Action **Compilar Folha PDF Plus** executa em alterações nesta pasta. Requer JDK 17 e SDK Android plataforma/build-tools 35. Compila diretamente com aapt2, javac, d8, zipalign e apksigner. Não depende de Gradle.

Localmente, a partir da raiz do repositório:

    bash FPlus/source/build.sh verify

As bibliotecas e modelos são extraídos do APK original preservado em `FPlus/distribution`; a compilação não busca modelos nem bibliotecas PDF em CDNs. A configuração inicial das ferramentas de desenvolvimento exige internet. O aplicativo resultante processa PDFs e OCR offline. Internet no app é usada para atualizar; o WebView bloqueia destinos externos.

Sem os secrets da chave original, a Action valida a compilação sem assinar: o artifact `.apk.unsigned` não é instalável. O APK Teste 1.9.4 já publicado continua disponível, mas sua chave temporária não foi preservada. Novas execuções não geram outras chaves descartáveis. Consulte [assinatura permanente](../signing/README.md).

## Habilitar builds e publicações oficiais automáticas

O mantenedor precisa localizar a chave privada que produziu o certificado SHA-256 de `FPlus/signing-certificate.sha256`. Não é possível extraí-la do APK. Não coloque keystore, senhas ou base64 da chave em commits, issues ou comentários.

Cadastre no GitHub, em Settings → Secrets and variables → Actions, os secrets:

- `FPLUS_KEYSTORE_BASE64`: arquivo da chave original codificado em base64.
- `FPLUS_STORE_PASSWORD`: senha do keystore.
- `FPLUS_KEY_PASSWORD`: senha da chave.
- `FPLUS_KEY_ALIAS`: alias da chave.

Com os quatro configurados, o modo `auto` compila e assina para `com.folha.pd2`, verifica o certificado original e publica a nova versão. Sem eles, apenas valida a compilação sem gerar um APK instalável. O modo manual `production` recusa execução se os secrets estiverem incompletos. A chave é materializada apenas em arquivo temporário no runner, removido ao encerrar a etapa; não entra no APK nem nos artifacts.

Antes de cada publicação, aumente `versionCode` e `versionName` em `version.json`, escreva notas e valide as alterações. A publicação exige versionCode maior que o canal atual e não sobrescreve uma tag existente. A automação baixa o APK publicado e verifica sua integridade antes de avançar `FPlus/update.json`. O usuário confirma a instalação no Android.

## Mudanças nativas desta reconstrução

- Pacote de produção `com.folha.pd2` e canal `FPlus/update.json`.
- Nomes de versão derivados do manifesto, sem textos fixos de 1.5.0.
- Provider de compartilhamento usando a autoridade do pacote em execução.
- Recebimento de PDFs por ACTION_VIEW/ACTION_SEND via `content://`, com verificação `%PDF-`, limite de 50 MB e leitura em segundo plano.
- Métodos `takeIncomingBase64` e `getIncomingName` usados pela interface recuperada.
- Entrada por `file://` não é aceita; o seletor de documentos e provedores Android usam `content://`.

A biblioteca continua no armazenamento WebView privado do pacote. Não desinstale a edição de produção para testar. A compatibilidade funcional, a biblioteca, importação, OCR, tarjas e a atualização sobre 1.9.3 precisam ser verificadas em dispositivo antes de distribuição definitiva. Compilação bem-sucedida não substitui teste em aparelho.

## Validação no celular

O proprietário confirmou a instalação e o funcionamento do APK Teste 1.9.4 publicado. Isso não comprova a atualização com a chave original; essa etapa continua pendente de configuração da assinatura.
