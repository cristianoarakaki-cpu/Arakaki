# Validação — Código Livre IA 0.2.0

- `assembleRelease lintRelease`: BUILD SUCCESSFUL; Java 17, Gradle 8.11.1, AGP 8.9.1, SDK 35, NDK 27.2.12479018.
- 65 testes passaram: 15 de código/ZIP, 30 de CSV/XLSX e 20 de SQLite.
- CSV: separador, aspas, quebras dentro de campos, faixas, contagens e limites.
- XLSX: nomes/relações de abas, textos compartilhados/inline, fórmulas/cache/erros, faixas, omissões, limites e XML inválido.
- SQLite: consultas reais em banco fictício Linux/JDBC aberto somente leitura, esquema, contagens, NULL/BLOB, PK composta, ordenação numérica, filtro de nomes e verificação estrutural rápida. Hash do arquivo preservado após consultas. Cabeçalhos WAL recusados.
- Dependências JDBC/SLF4J existem somente nos testes, sem inclusão no APK.
- APK assinado, alinhamento ZIP de 16 KiB verificado; sem permissões solicitadas, incluindo INTERNET.
- Pacote `br.com.arakaki.codigolivre`, versionCode 2, versionName 0.2.0, somente ARM64.
- Certificado idêntico ao APK 0.1.0 entregue: e9d415e56660a45d50878385ead9168c04bde518b1426c757d157ee4a063db64.
- Lint: 0 erros; avisos: ChromeOsAbiSupport=1, UsableSpace=1, SetTextI18n=9. Interface em português, foco ARM64 e controle conservador de espaço livre.

## Limites reais

Não executamos a interface, o seletor de arquivos, o adaptador SQLite Android nem inferência com pesos 1,5B/3B/7B no POCO. Os testes de SQLite são do núcleo compartilhado de consultas usando JDBC Linux, não do runtime Android. Compilação e lint verificam a integração estática Android. A atualização sem perda de dados tem compatibilidade de pacote, versão e assinatura verificada; o fluxo físico ainda precisa ser confirmado.

Modelos maiores foram disponibilizados como opções, sem alegação de melhoria de qualidade medida ou garantia de memória/velocidade. O uso com 12 GB requer avaliação no aparelho. O modelo já importado permanece aceito.

As prévias têm limites explícitos e não equivalem à análise completa de uma planilha ou banco. Macros, fórmulas recalculadas, datas formatadas, gráficos e ACCDB não são analisados diretamente. Leia LEIA-ME.md.
