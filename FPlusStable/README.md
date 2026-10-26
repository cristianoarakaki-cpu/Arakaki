# Folha PDF+ Definitivo — nova identidade permanente

Edição nova, pacote `com.folha.pd2.stable`, com canal próprio `FPlusStable/update.json`. Instala separadamente do Plus antigo e da edição de teste. O proprietário informou que os PDFs são de teste; não foi implementada uma migração de documentos. Não precisa recuperar as chaves antigas.

## Ativar pelo celular — uma única vez

1. Abra [os secrets do repositório](https://github.com/cristianoarakaki-cpu/Arakaki/settings/secrets/actions/new), conectado à conta proprietária.
2. Em **Name**, coloque `FOLHA_STABLE_SIGNING_PASSWORD`.
3. Em **Secret**, escolha uma senha forte e exclusiva com pelo menos 24 caracteres ASCII (letras, números e símbolos comuns). Guarde uma cópia privada em seu gerenciador de senhas. Não envie essa senha no chat. Toque **Add secret**.
4. Abra [Folha PDF Definitivo em Actions](https://github.com/cristianoarakaki-cpu/Arakaki/actions/workflows/folha-stable.yml), toque **Run workflow**, mantenha a branch `main` e execute. Se o botão estiver oculto no celular, use “Versão para computador” no navegador.
5. Depois da execução bem-sucedida, o APK ficará na [lista de releases](https://github.com/cristianoarakaki-cpu/Arakaki/releases), como **Folha PDF+ Definitivo 2.0.0**, arquivo `Folha-PDF-Stable.apk`.

Sem o secret, o workflow apenas testa a criptografia e valida uma compilação não assinada; não produz APK instalável e não anuncia uma publicação inexistente.

## Continuidade da assinatura

A primeira execução com o secret cria uma chave RSA permanente e a persiste como `signing/key.enc.json`, criptografada com AES-256-GCM e chave derivada da senha por scrypt. O certificado público fica em `signing/certificate.sha256`. O APK só é compilado para publicação depois que esse backup foi salvo no GitHub. A chave privada aberta existe apenas em arquivo temporário restrito no runner e é removida ao final.

Nas próximas execuções, a chave é recuperada do arquivo criptografado. Uma senha incorreta, backup incompleto ou certificado divergente interrompe o fluxo; não é criada uma chave substituta. **Não troque o valor do secret e não apague a pasta signing** depois da primeira publicação. Guarde também uma cópia privada do arquivo criptografado e da senha, pois os dois são necessários para recuperar a chave. O arquivo criptografado pode ser versionado; a senha e a chave aberta nunca devem ser publicadas.

As próximas alterações em `FPlus/source` ou `FPlusStable/version.json` acionam a compilação. Aumente a versão antes de publicar outra edição. A Action confere pacote, versão, certificado e download publicado antes de atualizar o canal definitivo. O Android pede confirmação para instalar. Consultas de atualização precisam de internet; PDFs e OCR continuam locais.

## Limites de verificação

Os testes cobrem criptografia, senha incorreta, alteração do arquivo e recusa de recriação da chave em caso de erro. O código nativo e os assets vêm da base 1.9.4 validada pelo proprietário. A instalação da edição definitiva e uma atualização sobre ela ainda precisam ser testadas em Android depois da primeira publicação.
