# Tradução do canto ao vivo — 0.75.0 experimental

Abra Letra da música → Ao vivo com uma música ou rádio tocando. Escolha o idioma cantado e o destino. Ative explicitamente; o primeiro uso baixa o reconhecimento (60 ou 190 MB) e os idiomas do Google ML Kit. Nenhuma API paga e nenhum microfone. O processamento posterior é local. Modelos são opcionais e têm tamanho e SHA-256 fixados.

Captura somente PCM do tocador Media3, após os ajustes de som, sem modificar seus bytes. Não captura vídeos em WebView ou LibVLC. A opção anterior de traduzir letras escritas continua disponível. O reconhecimento não depende de LRCLIB nem do campo de artista.

Trabalha com janelas de oito segundos, dois de sobreposição, no máximo duas threads e uma janela esperando processamento. Em aparelhos lentos descarta janelas antigas da análise, nunca da reprodução. Descarta resultados anteriores após mudança de arquivo, busca ou pausa. Ao sair da tela, cancela, desanexa o receptor e libera os motores sem parar a música. Desativado: apenas uma leitura de referência nula no processador existente, sem cópia PCM ou carregamento do motor.

É experimental: apresenta atraso e erros, principalmente com instrumentos fortes, coros, ruído ou gravações antigas. Pilotos reais de canto compararam modelos quantizados: o modelo pequeno mais preciso custou mais processamento, e a gravação histórica não foi reconhecida. Não se promete transcrição de qualquer música nem consumo de bateria equivalente ao modo desativado. Medições de computador/emulador não equivalem a medições de bateria de um telefone.

Testes automatizados verificam reamostragem e sobreposição, saída PCM inalterada mesmo com falha do receptor, abertura sem captura automática e o caminho real de reprodução de canto → Whisper → tradução em português sem letra de catálogo. As amostras são gravações cantadas em domínio público/CC0, com origem e hashes fixados no CI. Modelos não entram no APK. Fontes e licenças MIT acompanham a distribuição.
