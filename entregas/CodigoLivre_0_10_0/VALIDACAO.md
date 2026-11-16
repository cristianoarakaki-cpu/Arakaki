# Validação — Código Livre IA 0.10.0 experimental

- assembleRelease e lintRelease passaram; nenhum erro/fatal de lint.
- Suíte anterior (247 verificações) e 17 novas verificações simuladas de protocolo/alternância passaram.
- Novos testes: Retry-After em segundos/data, modelos gratuitos/recusa de pagos OpenRouter, saída truncada, exclusão de pensamento interno Gemini, excesso de entrada explícito, failover 429, cooldown, retorno após espera, cancelamento, falha de todos sem loop e erros sem chave.
- Chaves: AES/GCM com Android Keystore, armazenamento privado excluído de backup; sem envio em URL, histórico ou exportação. Inspeção estática, não teste do Keystore em dispositivo.
- Consultas autenticadas apenas nos hosts HTTPS fixos de cada API, sem redirecionamento; DNS público validado. Cancelamento encaminhado ao Call HTTP. Limite de 30s por tentativa, uma tentativa por provedor em cada pergunta.
- Catálogo dinâmico; Gemini Flash e Groq compatíveis dependem da conta. Gratuidade/cotas atuais não verificadas: sites oficiais bloqueados pelo proxy CONNECT 403. OpenRouter filtra preço zero e identificação :free. Não existe promessa de disponibilidade/uso ilimitado.
- Código/prévia anexada online exige opção explícita, desativada por padrão; caso contrário pedido com anexos é bloqueado com orientação. A pergunta vai aos provedores configurados quando modo online ativado.
- APK ARM64, versionCode 10, assinatura igual à 0.1.0; zipalign de 16KiB passou.

Não houve chamadas reais autenticadas, teste de qualidade/velocidade, teste de interface/Keystore/ciclo de vida/instalação em Android físico ou emulador. As chamadas de protocolo são simuladas. Não há chave de fornecedor embutida. Configure suas próprias chaves no app. O modelo local precisa estar carregado para fallback; abertura com IA online ativada evita carregar automaticamente os pesos. O sistema pode encerrar um serviço apesar das medidas de continuidade; checkpoint recupera texto parcial, sem retomar chamadas automaticamente. A IA pode produzir erros, mesmo com fontes. A fonte completa acompanha a entrega para revisão.
