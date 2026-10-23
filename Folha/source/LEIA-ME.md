# Folha PDF para Android — versão 1.2.0

Requer Android 8.0 ou mais recente e Android System WebView atualizado. Instale o APK no celular; o aplicativo tem ícone e janela próprios e não abre o navegador. Internet é usada somente para verificar e baixar atualizações pelo GitHub, e o instalador pede autorização do Android. Não é solicitado acesso geral ao armazenamento: use o seletor do Android para abrir documentos e escolher onde salvar.

Recursos: OCR em português, inglês e espanhol; imagens JPG/PNG para PDF; junção; extração de páginas; texto de PDFs para TXT; rotação de páginas; PDF para JPG; nome personalizado e compartilhamento. OCR e bibliotecas incluídos no APK. Limite de seleção de 50 MB por arquivo; em celulares, prefira documentos pequenos. Fechar o app descarta resultados ainda não salvos.

Instalação: copie ou baixe Folha-PDF-1.2.0.apk no celular, abra o arquivo e permita instalação por essa fonte se o Android solicitar. Esta é uma distribuição direta, fora da Play Store, assinada com uma chave de teste local. Não está publicada na Play Store. Atualizações devem usar a mesma chave. Não use essa chave de teste para uma distribuição comercial.

OCR preserva uma imagem de cada página e adiciona uma camada de texto invisível; pode errar palavras e não preserva links, formulários ou vetores do PDF original. PDF protegido por senha deve ser desbloqueado antes. Não há conversão Word/Excel nesta versão.

Compilação: ./build.sh com Android SDK plataforma 35, build-tools 35.0.0 (pasta android-15), ECJ 3.40 e Java 21. Defina FOLHA_ANDROID_SDK caso o SDK esteja fora de /workspace/android-sdk. O script usa assinatura de teste para instalação direta. build/ contém a chave local; não a inclua em compartilhamentos públicos.

Bibliotecas incorporadas: pdf-lib 1.17.1 (MIT), PDF.js 3.11.174 (Apache-2.0), Tesseract.js 5.1.1 (Apache-2.0), tesseract.js-core 5.1.1 (Apache-2.0), modelos @tesseract.js-data por/eng/spa 1.0.0 (Apache-2.0). Avisos de licença preservados nos scripts distribuídos quando presentes.

Atualizações: menu Atualizações verifica a versão no canal público cristianoarakaki-cpu/Arakaki/Folha/update.json. A verificação automática ocorre ao abrir, a cada seis horas, e pode ser desativada. Você escolhe baixar e confirma a instalação no Android; não há instalação silenciosa. SHA-256, pacote, versão e assinatura são conferidos. Instale sobre a versão anterior sem desinstalar.

Tema: seletor no topo com Claro, Escuro e Seguir o sistema (padrão). A escolha é salva no celular e não altera a aparência dos PDFs gerados.
