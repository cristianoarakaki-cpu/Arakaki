# Validação — Código Livre IA 0.1.0

- Compilação Android `assembleRelease lintRelease`: BUILD SUCCESSFUL.
- Java 17, AGP 8.9.1, Gradle 8.11.1, NDK 27.2.12479018, SDK 35.
- Motor llama.cpp fixado em 74d4f5b041ad837153b0e90fc864b8290e01d8d5.
- 15 testes de importação, limites, ZIPs e exportação: passaram (TESTES.txt).
- Assinatura APK verificada com apksigner; alinhamento ZIP de 16 KiB verificado com zipalign.
- Manifesto final sem permissões solicitadas, incluindo INTERNET.
- APK ARM64 contém libcodigolivre.so, libc++_shared.so e licenças do motor/runtime.
- ELF libcodigolivre.so: segmentos LOAD com alinhamento 0x4000 (16 KiB).
- Lint: sem erros; avisos: ChromeOsAbiSupport: 1, UsableSpace: 1, SetTextI18n: 7. A interface é exclusivamente em português; esta versão destina-se a ARM64, não ChromeOS. O controle de espaço usa espaço livre físico e não tenta liberar caches de outros apps.

## Limite da validação

Não foram executados o aplicativo Android, uma inferência com modelo real ou medições de RAM/velocidade no POCO F7 Pro. O teste em modo avião, importação de pesos, interrupção, exportação pelo seletor Android e reabertura da sessão precisam ser confirmados no aparelho. A compilação e as verificações acima não comprovam esses fluxos de execução.

O APK usa assinatura de depuração para teste. Recompilar em outra máquina pode gerar uma assinatura diferente, exigindo desinstalar a versão anterior (o que apaga modelo e sessão). Não é uma publicação na Play Store.
