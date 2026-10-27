# Prisma PDF — Android, offline primeiro

Novo aplicativo, interface e implementação próprias. Pacote `com.arakaki.prismapdf`, sem substituir Folha PDF, Plus ou suas edições de teste. Bibliotecas de terceiros são empacotadas localmente; lógica e interface anteriores não são reutilizadas.

## Ferramentas locais

- Leitor PDF com navegação e pesquisa de texto.
- OCR para PDF pesquisável em português, inglês e espanhol; imagens também aceitas.
- Leitura de boletos por texto, barras ITF horizontais e OCR, com verificação de dígitos.
- Juntar PDFs, extrair páginas, girar páginas e otimizar a estrutura.
- JPG/PNG para PDF, PDF para PNG e PDF para TXT.
- Salvar pelo seletor Android, compartilhar e guardar PDFs numa biblioteca local opcional.

As entradas não são guardadas automaticamente. O botão Guardar salva uma cópia local; desinstalar ou limpar dados apaga a biblioteca. Não há conta, telemetria, CDN em tempo de uso ou upload de documentos.

## Online quando necessário

O controle Permitir ações online começa desligado. Quando ativado pelo usuário, permite importar PDFs por links HTTPS públicos e verificar/baixar novas versões no GitHub. O WebView não carrega sites externos. As ferramentas de PDF continuam locais. Não há processamento remoto nem conversão Word/Excel nesta versão.

## Gerar o APK instalável

Uma configuração única pelo proprietário é necessária para a assinatura permanente:

1. Abra [GitHub Secrets](https://github.com/cristianoarakaki-cpu/Arakaki/settings/secrets/actions/new).
2. Crie `PRISMA_SIGNING_PASSWORD` com senha forte, exclusiva, de pelo menos 24 caracteres ASCII. Guarde a senha em local privado; não envie no chat.
3. Abra [Prisma PDF Android em Actions](https://github.com/cristianoarakaki-cpu/Arakaki/actions/workflows/prisma-pdf.yml) e toque Run workflow na branch main.
4. Ao concluir, o arquivo `Prisma-PDF.apk` ficará na release `prisma-v1.0.0`, com download externo ao chat.

A primeira execução com o secret cria uma chave RSA e salva backup criptografado com AES-256-GCM e scrypt em `signing/key.enc.json`, junto do certificado público. As execuções seguintes recuperam a mesma chave. Senha incorreta ou backup incompleto interrompem o fluxo; não criam outra chave. Não altere o secret nem apague o backup depois da primeira instalação. Guarde cópia privada do arquivo criptografado e da senha. O APK só é publicado depois de conferir assinatura, pacote, versão e o download final.

Sem o secret, a automação executa os testes e a compilação, mas produz somente `.apk.unsigned`, que não é instalável. Não é gerada chave descartável. A conexão do atendimento não dispõe de operação para cadastrar secrets na conta.

## Desenvolvimento

JDK 17, Android SDK plataforma/build-tools 35, Python 3 e Node.js. Da raiz do repositório: `bash PrismaPDF/build.sh verify`. `tools/vendor.py` reconstitui as dependências versionadas e verifica todos os hashes, sem acessar a internet. `build.sh signed` exige a chave preparada pela Action.

Cada publicação precisa aumentar versionCode e versionName em `version.json`. O canal é `PrismaPDF/update.json`. A instalação de atualizações é confirmada pelo Android, após verificação de SHA-256, pacote e assinatura. Não existe instalação silenciosa.

## Dependências

PDF-lib 1.17.1 (MIT), PDF.js 3.11.174, Tesseract.js/core 5.1.1 e modelos @tesseract.js-data por/eng/spa 1.0.0 (Apache-2.0). Os avisos de licença acompanham os arquivos empacotados. PDF.js é sempre configurado com `isEvalSupported: false`. A automação usa cryptography 46.0.3 para proteger o backup da assinatura; essa biblioteca não entra no app.

## Limites e validação

Android 8+ com WebView atualizado. Até 25 MB por arquivo, 20 entradas e 60 MB no total; OCR/boletos até 12 páginas, PNG até 20 páginas por operação. Documentos com senha precisam ser desbloqueados antes. OCR rasteriza as páginas e pode errar texto e números; revise os resultados. Regravar arquivos invalida assinaturas digitais e pode perder recursos interativos no caso de OCR. Otimizar não garante redução de tamanho.

A leitura de boleto não verifica autenticidade ou beneficiário. PDFs não devem ser pagos apenas com base na saída do aplicativo. O modelo de barras horizontais pode falhar em baixa resolução ou orientação incorreta.

Testes: regras de boletos e intervalos, código ITF sintético, criptografia e recuperação da mesma chave, teste de interface em navegador móvel com bloqueio de solicitações externas, operações de PDF, biblioteca, busca, OCR português e compilação Android. A ponte Android, a importação HTTPS real e a instalação precisam de teste em aparelho após a publicação. Teste de navegador não substitui esse passo.
