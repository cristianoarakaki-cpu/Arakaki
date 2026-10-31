"""Create a public update manifest without including any signing key."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil

root = Path(__file__).resolve().parents[1]
config = (root / 'app/build.gradle').read_text()
version_code = int(re.search(r'versionCode\s+(\d+)', config).group(1))
version_name = re.search(r"versionName\s+'([^']+)'", config).group(1)
package_name = re.search(r"applicationId\s+'([^']+)'", config).group(1)
assert re.fullmatch(r'\d+\.\d+\.\d+', version_name)
assert package_name == 'br.com.onda.musica'
repository = os.environ['GITHUB_REPOSITORY']
assert repository == 'cristianoarakaki-cpu/Arakaki'
source = root / 'distribution/Onda-Musica.apk'
output = root / 'release-out'
output.mkdir(exist_ok=True)
apk = output / 'Onda-Musica.apk'
shutil.copyfile(source, apk)
tag = 'onda-v' + version_name
manifest = {
    'versionCode': version_code,
    'versionName': version_name,
    'packageName': package_name,
    'apkUrl': f'https://github.com/{repository}/releases/download/{tag}/Onda-Musica.apk',
    'sha256': hashlib.sha256(apk.read_bytes()).hexdigest(),
}
(output / 'onda-update.json').write_text(json.dumps(manifest, indent=2) + '\n')
(output / 'notes.md').write_text(f"""Onda Música {version_name} — Favoritos do YouTube e proteção reforçada

YouTube no Onda: botão Favoritar e lista Favoritos com busca local por nome/endereço. Salve vídeos, Shorts, transmissões com ID de vídeo e playlists, edite o nome, remova ou abra de novo no navegador interno. Menu → Salvar playlist desta página também guarda a playlist de um vídeo que contenha list=. O menu de cada favorito permite consultar os formatos no analisador de downloads existente; isso não inicia download automaticamente. Nomes de até 160 caracteres e limite de 200 favoritos, sem miniaturas remotas nem sondagem de links em segundo plano.

Favoritos ficam apenas neste celular, separados dos favoritos de música e da conta Google. Não integram o backup de músicas atual. Não copiam nem baixam o vídeo: abrir e reproduzir depende da internet e da disponibilidade no YouTube. Endereços são normalizados para vídeo ou playlist oficiais, removendo parâmetros de rastreamento e evitando duplicação por links curtos/Shorts. Dados futuros ou inválidos são preservados sem sobrescrever. Não aceita páginas iniciais, buscas, hosts falsos, credenciais ou links de outros sites. Abrir favorito não inicia reprodução automática; voz, formatos, proteção e encerramento do WebView ao sair são mantidos.

Proteção reforçada do YouTube: amplia domínios publicitários dedicados, incluindo criativos 2mdn, IMA e variações regionais do adservice, e bloqueia subsolicitações /api/stats/ads e /pagead/ em hosts oficiais exatos. Estilo local cobre mais cartões móveis/desktop, faixas de anúncio e anúncios acompanhantes. Não bloqueia o documento principal, fluxos googlevideo, capas ytimg, API do player, métricas comuns de reprodução ou controles de pular anúncio. O contador continua medindo solicitações bloqueadas, não quantidade de anúncios removidos. Pode ser desativada no menu; a escolha existente é preservada.

É bloqueio parcial: comerciais inseridos no fluxo do vídeo ainda podem aparecer, e alterações do site podem afetar as regras. Não modifica respostas do player, não pula anúncios automaticamente, não burla verificações, não usa VPN, DNS global, listas baixadas, MutationObserver ou temporizador de varredura. Regras e busca locais, sem API paga; bateria não foi medida em aparelho físico.

Validação inclui links e limites, persistência, renomeação, remoção e separação dos favoritos locais; navegação de volta ao YouTube, rejeição de retornos de página antigos; bloqueio dos novos endpoints, imagens/player preservados e estilos em WebView real sem esconder vídeo ou botão de pular. A suíte anterior, exclusão/cancelamento nos dois Androids e atualização sem desinstalar continuam obrigatórios.

Mantém downloads, conversões MP3 até 320 kbps, reprodução de áudio/vídeo, PDFs/OCR, Bluetooth, voz, temas, Conecta e demais funções existentes. Instale sobre a versão atual, sem desinstalar. O suporte a torrents está em pesquisa separada e não faz parte desta versão.

Recursos anteriores — exclusão de músicas e vídeos com confirmação

Segure uma música ou vídeo na biblioteca → Excluir arquivo do celular. A confirmação mostra o nome real consultado no provedor e o endereço do arquivo; cancelar mantém o arquivo. Exclusão é diferente de ocultação: remove o arquivo do armazenamento e afeta outros aplicativos. O Onda não oferece desfazer. Apenas um arquivo por vez, sem seleção automática, exclusão de pastas ou limpeza em lote.

Android 11 ou mais recente usa a confirmação de exclusão do MediaStore; Android 10 trata a autorização recuperável quando exigida e só repete a operação após aprovação. Android 8/9 pede escrita no armazenamento somente ao excluir um item do MediaStore, com permissão limitada ao SDK 28. Documentos com autorização de escrita usam o provedor do Android (SAF); caso o provedor não permita, o Onda informa a falha. Não solicita acesso a todos os arquivos. Endereços remotos, caminhos file://, PDFs, pastas e provedores arbitrários fora de MediaStore/SAF não são excluídos por esta tela. O arquivo precisa ser reconhecido como áudio/vídeo; nome, tamanho e tipo são conferidos novamente antes do pedido para evitar agir sobre um registro alterado.

Somente após confirmação de exclusão, remove a faixa/URI correspondente da fila e da lista visível, o favorito selecionado e o registro de áudio baixado/último arquivo que teria recolocado o documento na biblioteca. Outros arquivos e favoritos permanecem. Se o item estiver aberto, fica pausado ao entrar na confirmação. Vídeo excluído sai do player e do histórico de posição. Listas salvas, anotações e histórico de downloads mantêm suas referências; podem indicar arquivo indisponível. Cancelamento ou erro não limpa registros. O Android pode pedir uma segunda confirmação.

Validação nativa dedicada em Android 10 e Android 15: cancelamento na tela, cancelamento no sistema quando aplicável, rejeição de endereço remoto, exclusão real de um áudio e um vídeo criados exclusivamente para o teste, preservação de outro arquivo, remoção da faixa/favorito/registro selecionados e atualização das listas. As confirmações do Android são exercitadas pela interface. A suíte anterior e a instalação sobre a versão antiga continuam obrigatórias. Sem varredura em segundo plano, nova API paga ou serviço permanente. Mantém todos os motores, codecs, conversões, OCR, PDFs, voz, YouTube, downloads e demais recursos.

Instale sobre a versão atual, sem desinstalar.

Recursos anteriores — MP3 de alta taxa, mais fontes e listas organizadas

MP3 em 128, 192, 256 ou 320 kbps, com escolha em Conversor local e Downloads → Qualidade MP3. Padrão preservado em 192 kbps; preferência salva no celular e capturada por operação, também em novas conversões de downloads/playlists. Arquivos MP3 originais baixados sem conversão mantêm sua taxa. kbps é a taxa de dados, diferente de Hz. Taxas maiores não recuperam qualidade perdida e geram arquivos maiores. Para fontes abaixo de 32 kHz, LAME reamostra a saída para 44,1 kHz ao escolher 256/320 kbps, pois essas taxas exigem MPEG-1; isso não cria detalhes novos.

Conversão local antes restrita a AAC agora aceita faixas mono/estéreo AAC, MP3, FLAC, Opus, Vorbis e outros formatos quando MediaExtractor e um decoder do Android reconhecem o arquivo. WAV PCM de 16 bits tem caminho direto para LAME. O seletor prefere AAC quando disponível para manter a extração M4A sem recodificação; o botão M4A fica desativado nas demais fontes. MP3 exige mono/estéreo, mas a extração M4A anterior continua preservando AAC multicanal sem exigir um decoder. Sem suporte prometido a todos os codecs ou DRM. O tocador de música passa a permitir tentativa de outro decoder disponível quando a inicialização falha; mantém Media3 e o motor LibVLC existente de vídeo, incluindo fallback de hardware para software. Não adiciona um pacote pesado de codecs, nem muda o motor de reprodução.

Arquivos locais com erro explícito de formato não suportado pelo decoder de áudio são ocultados da biblioteca principal. Outros erros oferecem Ocultar da lista sem classificar automaticamente falhas de acesso como incompatibilidade. Vídeos oferecem ocultação após falha também na tentativa por software, já que o evento genérico do LibVLC não distingue com certeza um codec ausente de arquivo danificado. Nada é apagado, e favoritas/listas/filas existentes são preservadas. Organizar biblioteca → Arquivos ocultos / incompatíveis ou o mesmo item no menu de vídeos permite restaurar todas as referências de cada tipo. Até 200 por tipo; não aplica a busca unificada ou listas salvas. Reabra um arquivo pelo Android ou restaure após substituí-lo/atualizar codecs. Sem varredura de codecs, processamento contínuo ou serviços novos.

Validação nativa dedicada verifica quadros MP3 reais em 256/320 kbps e áudio PCM audível de MP4/AAC, FLAC, WAV16, MP3, Opus, Vorbis, AAC de 22,05 kHz e AAC estéreo de 48 kHz, além de preservação de AAC de seis canais ao extrair M4A; conversão pelo serviço em 320 kbps; estado do seletor e botão M4A; ocultação/restauração nas duas listas, limite e preservação de favoritos. A suíte anterior, a biblioteca de 3.000 músicas e a instalação sobre a versão anterior continuam obrigatórias. Limites de 512 MB e 30 minutos por conversão, cancelamento, originais e pastas existentes mantidos. Economia de bateria não medida em aparelho físico.

Instale sobre o app atual, sem desinstalar. Mantém PDFs/OCR, áudio/vídeo em segundo plano, voz, YouTube, proteção de anúncios, downloads, conversões, Conecta, temas, listas e demais funções anteriores.

Recursos anteriores — biblioteca mais leve e menos trabalho em repouso

Biblioteca principal com lista nativa que reutiliza cartões conforme a rolagem. Mantém todos os registros carregados, a ordem, os grupos de artista/álbum, favoritas, filtro Downloads do Onda, busca por campos, destaque da música atual, toque para reproduzir a seleção completa e toque longo para organizar a fila. Não limita a lista aos itens visíveis.

Busca prepara o termo uma vez por filtragem, reaproveita expressões de normalização e evita normalizar o texto quando a busca está vazia. Ordenação guarda as chaves normalizadas somente durante cada comparação de lista, sem cache global de músicas. Downloads observa mudanças de estado e só mantém atualização periódica enquanto existe uma operação ativa; ao sair da tela, remove a observação e os callbacks.

Validação inclui biblioteca sintética de 3.000 músicas, acesso ao último item, poucos cartões anexados à tela, busca, favoritas, grupos de artista e reprodução de áudio AAC real. Também verifica que Downloads parado não mantém polling, recebe mudanças de estado e atualiza ao voltar à tela. A suíte completa continua conferindo funções anteriores e atualização sobre o app existente.

Mantém motores de áudio/vídeo, formatos, OCR local, PDFs, voz, YouTube, proteção de anúncios, downloads, conversões, Conecta, aparências, listas e dados existentes. Não reduz compatibilidade removendo bibliotecas, modelo de OCR ou arquiteturas ARM. O foco é reduzir trabalho e criação de views durante o uso; não promete redução do tamanho do APK ou percentual de bateria/RAM em aparelho físico. Sem nova permissão, API paga ou serviço permanente. Instale sobre a versão atual, sem desinstalar.

Recursos anteriores — proteção de anúncios no YouTube

YouTube no Onda → Menu → Proteção de anúncios. Proteção local ativada por padrão, com opção de desligar e recarregar se atrapalhar a página. Conta solicitações publicitárias bloqueadas na sessão, não quantidade de anúncios. A preferência fica salva neste celular. Também ignora retornos atrasados da página anterior durante uma nova busca por voz ou texto, preservando a pesquisa solicitada.

Bloqueia subrecursos de seis domínios exclusivos de publicidade e seus subdomínios, respeitando limites de nome; não bloqueia a página principal, youtube.com, youtubei.googleapis.com, googlevideo.com ou ytimg.com. Uma folha de estilo local oculta cartões patrocinados móveis conhecidos. Não altera respostas do player, não pula vídeos, não automatiza botões, não burla verificações e não garante remover anúncios inseridos no próprio fluxo do vídeo. O YouTube pode alterar o site ou restringir reprodução com bloqueadores.

Implementação própria: não incorpora nem é afiliada ao AdGuard. Sem VPN, certificado instalado, DNS global, servidor intermediário, API paga, lista externa, varredura contínua, timer ou observador de DOM. Regras simples por solicitação e estilo uma vez por carregamento de página. Só na aba YouTube; downloads, navegador externo e demais aplicativos não são filtrados. Mantém busca por voz, encerramento do navegador ao sair e funções anteriores. Economia de bateria não foi medida em aparelho físico. Instale sobre a versão atual, sem desinstalar.

Recursos anteriores — busca por voz no YouTube

Downloads → YouTube: novo campo de busca e microfone do Onda. Toque no microfone, diga o nome da música ou artista e veja os resultados do site oficial dentro da própria aba. Pode digitar ou corrigir o texto e buscar pelo botão ou teclado. Não inicia reprodução ou download automaticamente.

Usa o diálogo de reconhecimento de fala do Android em português do Brasil, somente ao tocar. Sem API paga ou nova permissão de gravação para o Onda; disponibilidade e eventual uso da internet dependem do serviço de voz instalado no aparelho. Se não existir serviço compatível, permite digitar ou usar o microfone do teclado. Cancelar não faz pesquisa. Termos limitados a 160 caracteres, com acentos e símbolos codificados no endereço HTTPS oficial.

A pesquisa é mantida ao recriar a tela; o resultado da voz também é aplicado se o navegador tiver sido encerrado durante o diálogo. Preserva encerramento do WebView ao sair, bloqueio de acesso a arquivos e reprodução por gesto do usuário. Sem escuta contínua, serviço novo em segundo plano ou medição de bateria física. Mantém Central organizada, destino automático e funções anteriores. Instale sobre a versão atual, sem desinstalar.

Recursos anteriores — Central de downloads organizada

Central de downloads com busca local por nome, formato ou origem, ignorando acentos e maiúsculas. Filtros de status combinados com áudio/vídeo e ordenação por data, nome ou bytes transferidos, acessíveis no menu sem encher a tela. Busca e filtros são preservados ao recriar a tela. Até 200 registros já existentes; não varre arquivos do celular.

Compartilhar arquivo nos registros concluídos usa o seletor do Android, com acesso temporário somente de leitura ao arquivo escolhido. Verifica acesso antes de compartilhar; arquivos removidos ou com autorização revogada mostram orientação. Não envia links temporários de download nem compartilha pastas inteiras.

A Central escuta mudanças do histórico enquanto visível. A atualização periódica só roda durante uma operação ativa e para ao sair da tela. Sem nova permissão, rede de busca, serviço permanente ou medição de bateria física. Mantém destino automático e demais recursos. Instale sobre a versão atual, sem desinstalar.

Recursos anteriores — destino automático e seleção de áudio

Downloads → Destino → Salvar automaticamente nas pastas do Onda. Com a autorização de pasta guardada, escolher o formato salva direto em Onda/Áudios ou Onda/Vídeos, sem perguntar a pasta ou confirmar novamente. A primeira escolha de pasta para playlists agora também vira o padrão, inclusive se a transferência falhar. Sem configuração, tenta recuperar apenas a autorização associada ao último download concluído; caso não exista, o Android pede uma pasta uma vez.

Outro local no próximo download é opcional e não desativa o padrão. Também pode pedir local sempre ou autorizar/mudar a pasta. Preferência manual anterior é respeitada: ative o automático no botão Destino. Uma pasta já chamada Onda é reutilizada; arquivos anteriores não são movidos ou apagados. Acesso revogado pode exigir nova autorização. Cabeçalho corrigido para Central caber, com introdução menor e destino visível.

MP3/M4A/AAC podem aproveitar um MP4 com som quando não há áudio M4A separado, usando a menor resolução conhecida. Não usa vídeo silencioso nem troca o formato solicitado. Extração depende de AAC compatível e dos limites já existentes. Falhas agora dizem qual formato faltou e quais opções existem; a primeira causa aparece no resumo quando nada conclui. Subpasta da playlist só é criada após encontrar formato utilizável.

Testes de pasta real, autorização lembrada, próximo download sem seletor, recuperação do destino, outro local por uma operação e persistência após falha. Sem nova permissão, serviço de varredura ou API paga. Operações de pasta só durante uso explícito; sem medição de bateria física. Instale sobre a versão existente, sem desinstalar.

Recursos anteriores — YouTube no Onda, páginas públicas e AAC

Downloads → abas Links e YouTube. Navegue pelo site móvel oficial dentro do app e toque Ver formatos para baixar ao escolher vídeo ou playlist. O botão transfere o endereço ao analisador. Atalho em Explorar. Android System WebView necessário. A página é pausada e destruída ao sair da tela para evitar navegador e mídia ocultos; voltar recarrega o último endereço.

Mais links: páginas HTTPS públicas com arquivos MP4, MP3, M4A e AAC declarados em video/audio/source, Open Graph e dados estruturados. Até 1 MB de página, 6 candidatos conferidos e 3 fontes oferecidas, sem executar scripts ou usar cookies de login. Arquivos reais validados antes de salvar. Limites, reconexões, cancelamento, pastas e Central mantidos.

Áudio: MP3 (192 kbps), M4A e novo AAC-LC em ADTS, que preserva os pacotes sem recodificar. AAC também em playlists e na pasta Onda/Áudios. Extrações dependem da faixa e formato disponíveis; conversão não aumenta qualidade. M4A/AAC evitam codificar MP3.

Não baixa de qualquer site: sem DRM, login/verificações, HLS/DASH ou players dinâmicos sem arquivo declarado. YouTube/TikTok podem bloquear a análise por rede/região, mesmo quando o vídeo toca no site. Sem API paga ou nova permissão. Testes de pacotes AAC, download real, análise pública, fluxo da aba e encerramento do navegador no Android. Economia de bateria não foi medida em aparelho físico.

Recursos anteriores — OCR local e conferência de boletos

PDF → Menu → Texto da página usa texto original primeiro e OCR se a página for imagem. OCR da página também lê partes digitalizadas em páginas mistas. Modelo português incluído, sem enviar documentos ou baixar modelo no celular. Texto reconhecido é selecionável/copiável, com identificação de OCR para revisão.

Reconhecer boleto compara linha e barras quando disponíveis; usa OCR quando não encontra linha válida no texto original. Confere dígitos verificadores, mostra a origem e aponta divergências. Nenhum dígito é corrigido por tentativa. Confira o resultado e toque Copiar código. Confirme beneficiário e valor no banco: dígitos consistentes não autenticam o boleto.

Somente a página solicitada, até 2,5 milhões de pixels, motor standard de uma thread, contraste e rotações limitadas. Cancelar leitura e interrupção solicitada ao sair; cache em memória de até duas páginas. Sem varredura contínua ou serviço de OCR. Texto/OCR até 16 MB, leitura visual até 64 MB. Respeita restrições de cópia; nitidez e tamanho das letras limitam a precisão. Sem medição de bateria em aparelho físico. Mantém as funções anteriores e a instalação sobre a versão existente.

Tesseract4Android 4.9.0 e modelo português tessdata_fast, Apache 2.0, com avisos de Leptonica, libpng e IJG na tela de licenças. Fontes e instruções de compilação no pacote anexado.

Recursos anteriores:

Menu → Aparências: lista de cinco interfaces escuras com prévia — Onda Original, Nebulosa, Circuito, Cyber Solar e Grafite. Muda cores, gradientes e cantos dos cartões e controles; mantém organização, funcionalidades e tamanho de fonte do Android. Pode voltar ao Onda Original a qualquer momento. A escolha fica salva somente neste aparelho, permitindo que cada pessoa use sua própria aparência.

A aplicação repinta as telas existentes, sem recriar atividades, reiniciar o tocador ou alterar fila/posição. Os atalhos ficam nos menus de Músicas, Vídeos e Explorar. Prévias estáticas desenhadas no próprio app; não há animação contínua, downloads de temas, nova permissão ou API paga. Leitura de PDF e imagem de vídeo preservam as cores do conteúdo. A preferência de aparência não integra o backup de listas atual.

Mantém conversor local AAC, arquivos do Onda, pastas, favoritas e os demais recursos. A indisponibilidade de downloads do TikTok continua pendente e não é resolvida por esta mudança visual.



Menu → Conversor local: selecione um vídeo ou áudio com faixa AAC, comum em MP4/M4A/AAC. Gere MP3 a 192 kbps ou extraia M4A sem recodificar a faixa AAC. Confere compatibilidade antes de oferecer os botões; esta primeira versão não converte todos os codecs de áudio. Processamento no aparelho, sem API paga. Até 512 MB e 30 minutos por operação, com notificação, cancelamento e resultado na Central. Originais preservados, arquivos temporários removidos e saída incompleta excluída quando o provedor permite. Pode salvar em Onda/Áudios ou escolher outro local. MP3 não melhora a qualidade da fonte.

Menu → Arquivos do Onda: navegue pela pasta configurada e subpastas, busque nomes na pasta atual, ordene por nome/data/tamanho e abra áudio, vídeo e PDF no Onda. Até 1.000 itens por pasta e 30 níveis de navegação. Atalho Converter áudio nos arquivos compatíveis. Não move, renomeia nem exclui arquivos. Se o acesso expirar, configure a pasta novamente pela Central. Provedores de nuvem podem depender da internet.

Menu → Controles de áudio: velocidade de 0,5× a 2× com tom preservado, voltar 10 segundos e avançar 30 segundos. A velocidade é guardada para próximas reproduções de áudio; mudar o ajuste não inicia a reprodução. Vídeos usam velocidade própria no Modo Aprender e ganham os comandos Voltar 10 segundos e Avançar 30 segundos no menu, preservando pausa/reprodução e desativando A–B se o salto sair do trecho. Precisão da busca depende do arquivo.

Mantém pastas, cópia de favoritas, histórico e funções anteriores. O bloqueio externo do TikTok continua pendente; esta atualização não promete resolver HTTP 403.



Biblioteca → menu → Organizar biblioteca → Copiar favoritas para a pasta do Onda. Após confirmar, copia as favoritas locais disponíveis para Onda/Áudios, preservando formato, originais e marcações. A cópia usa serviço em primeiro plano com notificação, progresso, cancelamento e registro na Central; não converte nem move arquivos. Até 1.000 referências por operação e 512 MB por arquivo; evita referências equivalentes quando reconhecidas, mas repetir a operação pode criar novas cópias. A pasta deve estar configurada e ativa. Arquivos indisponíveis são relatados e saídas incompletas são removidas quando o provedor permite.

Central de downloads pelo botão Central em Downloads: histórico local por arquivo, fila da playlist, estado, trecho transferido, conclusão e falha. Filtros Todos, Em andamento, Concluídos e Falhas/interrupções. Abrir arquivos concluídos e Tentar novamente, que preenche o link original para reanalisar os formatos e escolher novo destino. Não guarda URLs temporários dos servidores de mídia. Até 200 registros; limpar histórico não apaga os arquivos. Registros começam nesta versão. Não retoma bytes após encerrar a operação; a recuperação de conexão dentro do download continua disponível.

Central → menu → Escolher pasta do Onda: escolha a pasta base pelo Android uma vez. Cria Onda/Áudios e Onda/Vídeos, com acesso persistente quando o provedor permite. Downloads e conversões do download podem usar essas pastas; playlists criam sua própria subpasta dentro do tipo correspondente. Pode escolher Outro local a cada operação e alternar para pedir destino sempre. Cria arquivos novos, sem substituir existentes; o provedor resolve nomes repetidos. Mudança de pasta não move arquivos anteriores. Acesso revogado, cartão removido e pastas na nuvem podem exigir nova seleção/conexão. Não acrescenta um conversor independente de arquivos nesta versão.

Menu da biblioteca → Organizar biblioteca: título, artista, álbum, duração crescente/decrescente e mais recentes. Ordenação por artista/álbum inclui cabeçalhos de grupos. Filtro Downloads do Onda mostra os áudios registrados pelo app, inclusive abertos/recebidos; mantém busca e favoritas. Duração/data ausentes ficam após valores conhecidos. Preferências locais, sem alterar nomes, metadados ou arquivos. Não inclui busca/exclusão de duplicatas nem nova extração de capas.

A pendência do TikTok permanece: o teste anterior reconheceu o vídeo, mas os arquivos foram recusados com HTTP 403. Esta atualização não promete resolver o bloqueio externo. YouTube e links diretos mantêm os caminhos existentes.


Corrige a consulta ao TikTok: usa a página pública para computador e mantém a identificação de navegador durante o download. A página móvel pode retornar somente uma tela de compartilhamento sem os dados do vídeo. Confere um pequeno trecho do arquivo antes de oferecer os formatos e tenta até quatro endereços de vídeo publicados pela própria página quando um deles é recusado. Não usa login nem resolve verificações.

Downloads aceita links curtos vt.tiktok.com, vm.tiktok.com e tiktok.com/t, links completos de vídeos públicos do TikTok e endereços HTTPS diretos de arquivos MP4, MP3 e M4A. Pode colar também o texto de compartilhamento quando ele contém um único link. YouTube e playlists continuam disponíveis.

TikTok: o Onda tenta ler os arquivos publicados pela página, sem login, API paga, servidores de terceiros, remoção de marcas ou solução de verificações. Vídeos privados, fotos, lives, bloqueios regionais e verificações podem impedir a análise. Quando um vídeo é disponibilizado, oferece MP4 original e extração do áudio completo para MP3/M4A, conforme compatibilidade AAC. Não garante disponibilidade de todos os vídeos.

Links diretos preservam o arquivo original; MP3 já pronto não é convertido novamente. A análise lê apenas um trecho e o download valida as faixas reais antes de salvar. Extração para MP3 depende de áudio AAC. Endereços locais/reservados, páginas disfarçadas de mídia e formatos de streaming HLS não são aceitos. Até 512 MB por arquivo, com cancelamento e recuperação de conexão existentes. Outros sites de redes sociais não estão incluídos nesta versão.

Recursos anteriores:

Menu → Onda Conecta: envie e receba músicas, vídeos e PDFs entre aparelhos Onda na mesma rede Wi-Fi privada IPv4. No receptor, escolha a pasta e gere o QR; no remetente, escolha até 10 arquivos e leia o QR pela câmera, por imagem ou cole o código. O receptor precisa aceitar a lista antes de salvar. Conexão TLS com certificado conferido pelo QR e verificação SHA-256 de cada arquivo. Sem conta nem servidor de transferência.

Até 512 MB por arquivo e 1 GB por envio. Tamanhos precisam ser informados pelo provedor. Mantenha esta tela aberta nos dois celulares; sair cancela. QR de uso único e espera de conexão de até 3 minutos. Recusa não cria arquivos. Em falhas/cancelamento, arquivos confirmados são mantidos e o arquivo incompleto é removido quando o provedor permite. Uma nova tentativa começa de novo; não há retomada de bytes. Recebidos ficam na pasta escolhida e são registrados no Meu espaço, conforme capacidade. A câmera é usada apenas ao abrir o leitor de QR; imagens não são salvas. Redes com isolamento de clientes/convidados podem bloquear a conexão. Ainda não inclui reprodução sincronizada.

Recursos anteriores:

Menu → Busca unificada: encontre músicas por nome, artista e álbum, vídeos locais, PDFs adicionados, coleções e texto das anotações. Filtros por tipo, favoritas de áudio e Continuar. Abra anotações no minuto ou página marcado. PDFs precisam ser abertos ou adicionados; não pesquisa o texto completo das páginas. Adicionar arquivo usa o seletor do Android. Metadados processados fora da interface, sem varredura contínua nem API paga; até 10 mil músicas e 10 mil vídeos na leitura e 200 resultados visíveis.

Comandos de voz: “abra minha coleção Estudo”, “continue o último vídeo”, “continue o último PDF”, “continue a última música”, “continue o último conteúdo” e “busque no Onda Chitãozinho e Xororó”. Pedidos como “abra o PDF Fatura” mostram resultados para escolher. Coleções com nomes iguais exigem escolha. Frases personalizadas existentes têm prioridade na biblioteca. Busca local sem internet; reconhecimento de voz depende do serviço do Android.

Recursos anteriores preservados:

Menu → Aulas e podcasts: equilíbrio de fala com dinâmica e presença suave e opção independente de pular silêncios. Ambas começam desligadas. Processamento local de áudio compatível, sem API paga, microfone ou análise de arquivos em segundo plano. Mantém posições no tempo original do arquivo; não modifica os arquivos. Vale para músicas e áudio online, com compatibilidade dependente do formato/saída. Vídeos usam outro motor. Pausas intencionais também podem ser reduzidas: use com conteúdo falado. Equalização e perfis existentes permanecem disponíveis.

Faixas concluídas naturalmente na fila voltam ao início no histórico; pular uma faixa preserva o ponto de saída.

Menu → Meu espaço: continuar áudio, vídeo e PDF, criar coleções com os três tipos de arquivo e guardar anotações ligadas a um minuto ou página. Toque para retomar; segure para organizar ou anotar. Seleção de arquivos pelo Android, sem copiar ou excluir os originais. Tudo local, sem API paga nem análise contínua. Até 200 referências, 30 coleções, 50 itens por coleção e 10 notas de 1.000 caracteres por arquivo (dados limitados a 1 MB). Notas e coleções são preservadas no celular; não integram o backup de listas atual. Arquivos removidos ou com acesso expirado exigem nova seleção. O registro começa após atualizar, sem reconstruir histórico antigo. Áudio usa pontos nas ações e a cada 15 segundos de reprodução.

Coração de favoritas redesenhado como ícone vetorial, sem depender da fonte do Android e sem recortes nas laterais. Botão com área de toque de 48 × 48 dp, contorno quando não favorito e preenchido quando favorito. Cartão Tocando agora com mais separação entre título, artista e coração, altura adaptável aos textos, barra de posição mais espaçada e tempo mais legível. Mantém as favoritas salvas e os demais recursos.

Tela cheia: controles sobrepostos sem reduzir a área da imagem. Somem após 3,5 segundos durante a reprodução; toque na imagem para mostrar ou ocultar. Pausar mantém os controles visíveis; a busca reinicia o prazo. Mantém exploração por toque acessível, Voltar e janela flutuante. A atualização do progresso da interface para enquanto os controles estão ocultos.

PDF → Menu → Texto da página: seleção nativa de trechos para copiar e botão Copiar texto. Extração local da página atual usando PdfBox-Android 2.0.27.0, Apache License 2.0. Até 16 MB para extrair e 100.000 caracteres por página; leitura visual até 64 MB. Respeita a permissão de cópia do documento. PDFs digitalizados podem ser reconhecidos por OCR local nesta versão. Sem API paga ou envio a servidor. Licença e avisos da biblioteca incluídos em Downloads → Licença e código-fonte. Fonte: https://github.com/TomRoush/PdfBox-Android .

Novidades: o Onda aparece em Abrir com para áudio, vídeo e PDF quando o gerenciador fornece o tipo correto e acesso. Áudio externo abre no tocador, com metadados e favoritos. Menu de vídeos → Reprodução em segundo plano → Continuar áudio mantém o som com tela bloqueada, com notificação e controles. O motor deixa de decodificar a imagem nessa etapa. Há uma breve troca de motor ao sair/retornar. Pausar ao sair permanece disponível. Janela flutuante mantém a imagem sobre outros apps. Não há retomada automática após reiniciar o processo.

PDF → Menu → Reconhecer boleto: linhas digitáveis bancárias de 47 dígitos e de arrecadação de 48, além de código de barras ITF de 44 dígitos, com conversão para linha digitável e verificação dos dígitos de controle. Um código consistente é apresentado para conferência e cópia; vários resultados abrem escolha. Análise local da página atual, sob comando do usuário, usando texto e barras legíveis, inclusive rotação. Sem pagamento automático ou QR Pix. A consistência matemática não autentica o boleto. Leitura de barras por ZXing 3.5.3, Apache 2.0; avisos e licença incluídos. Fonte: https://github.com/zxing/zxing .

Vídeos → Menu → Modo Aprender: velocidades de 0,5× a 2×, repetição A–B sem limite ou por 3, 5 e 10 passagens completas, com pausa ao concluir. Ativar ou alterar velocidade prepara o vídeo pausado; toque em Reproduzir. Velocidade e repetição valem na sessão do vídeo; outro arquivo volta a 1×. Momentos salvos → Anotação: texto local editável de até 1.000 caracteres; renomear preserva a nota. Marcações antigas são mantidas e notas não alteram o vídeo nem integram o backup de listas.

Leitor de PDF nos menus da biblioteca, Explorar e vídeos: seletor de arquivos do Android, anterior/próxima, Ir à página, zoom de 50% a 200% e retomada do último PDF na página lida quando o acesso persiste. Aceita Abrir com Onda para PDFs com permissão de leitura. Leitura nativa local, uma página por vez, com resolução limitada para controlar memória. Até 64 MB e 5.000 páginas; PDFs com senha não suportados. Não é editor; OCR sob comando pelo menu. Sem nova permissão ou serviço pago. Arquivos de nuvem dependem do provedor selecionado. Mantém música de fundo sem solicitar foco de áudio.

Menus da biblioteca, vídeos, Explorar e DJ em um painel com altura e largura limitadas à área útil da tela. Lista rolável, textos longos em mais de uma linha e botão Fechar fixo, sem reduzir a fonte do Android ou remover opções. Corrige opções que ficavam cortadas na parte de baixo em alguns aparelhos.\n\nMenu → Estúdio de som → Perfis automáticos por saída. Perfis separados para alto-falante, fone com fio, Bluetooth, USB, HDMI e outras saídas, com nomes personalizados. Dispositivos Bluetooth compartilham um perfil. A saída é identificada pelo AudioTrack real durante a reprodução, sem varredura Bluetooth nem análise contínua. Sem identificação, mantém som original. Começa desligado; desativar recupera seu ajuste geral. Restaurar som original afeta o perfil em edição. Vale para músicas e áudio online; vídeos usam outro motor. Dados locais, fora do backup de listas. Sem nova permissão ou API paga. A troca física de dispositivos deve ser conferida no celular.\n\nRepetição A–B para vídeos: Menu → Repetir trecho A–B. Configure início e fim em segundos, m:ss ou h:mm:ss, com intervalo mínimo de 2 segundos. Ativar prepara o trecho pausado; toque em Reproduzir para começar. O intervalo fica visível junto ao tempo. Pausar mantém a configuração; Desativar, selecionar outro vídeo, abrir um momento salvo ou buscar fora do intervalo cancela a repetição. A configuração vale somente para a sessão atual do player. Sem serviço pago nem análise contínua; usa eventos de reprodução e limita tentativas quando o arquivo não responde à busca. A precisão e a continuidade dependem do arquivo e do decoder.

Momentos dos vídeos: Menu → Marcar momento guarda o trecho atual com um nome; Momentos salvos permite Reproduzir daqui, Renomear e Excluir. Os diálogos pausam o vídeo; Reproduzir daqui inicia a cena. Até 30 momentos por vídeo e 100 vídeos, sem apagar marcações antigas automaticamente. Dados locais, sem serviço pago; não incluídos no backup de listas. Referências locais reconhecidas da biblioteca e do seletor Android compartilham as marcações no Android 10 ou superior.

Tela de vídeos redesenhada: biblioteca com mais espaço antes de abrir um vídeo, atalho Abrir arquivo, controles por ícones e tempo em uma linha separada. Painel de vídeo com altura adaptável à tela. Botões e busca acomodam fontes maiores do Android. Mantém tela cheia, janela flutuante, legendas, gestos e retomada de posição.

Nova tela Fila de reprodução pelo menu: destaque da faixa atual, próximas músicas, ouvir agora, colocar como próxima, mover para cima/baixo e remover. Segure uma música na biblioteca para adicioná-la como próxima ou no fim sem iniciar o áudio. Alterar a ordem desativa o aleatório. Remover próximas mantém a música atual e desativa a repetição para encerrar depois dela. As alterações são validadas no serviço para evitar comandos desatualizados.

Temporizador: parar ao terminar a música atual ou após 3 ou 5 músicas concluídas, pelo menu. Por voz: “pare ao terminar esta música” e “pare após três músicas”; aceita de 1 a 20. Pular faixas não consome a contagem. Cancelar ou selecionar minutos substitui o temporizador anterior. O temporizador por faixas vale para a sessão atual e não sobrevive ao encerramento do processo. Se a fila terminar antes da contagem, a reprodução termina normalmente.

Retomada de filas com músicas locais e downloads, preservando ordem, posição, modo e motivos das escolhas do DJ. O app volta pausado. Ajustar sessão → Evitar esta música no DJ: exclui a faixa das próximas recomendações sem remover o arquivo ou a marcação de favorita. Pode dizer “evite esta música” e criar um atalho em Minhas frases. Reautorizar músicas evitadas permite voltar atrás; vale para novas seleções. As preferências de evitação ficam somente neste celular e não fazem parte do backup de listas. DJ Pessoal com modos Para você, Só favoritas, Redescobrir, Minha viagem e Downloads e redescobertas. Prévia com motivo de cada escolha. Menu Ajustar sessão: mais variedade, mais do artista atual e evitar repetir artistas nas próximas, preservando a música atual e sua posição. Voz: monte minha viagem; mais variedade; mais desse artista; toque minhas favoritas sem repetir artista; por que esta música? Atalhos também em Minhas frases. Aprende com favoritas, escutas e reproduções que chegam naturalmente ao fim após pelo menos 80% de escuta real, a partir desta versão. Seleção e interpretação locais, sem API paga; reconhecimento de fala depende do serviço Android. Sem microfone contínuo nem análise em segundo plano. Mantém a correção das favoritas de downloads. Instale sobre o Onda Música atual, sem desinstalar. Mesmo pacote e certificado: preserva os dados do Onda principal. O Lab é outro aplicativo; para trazer suas listas e frases dele, use Backup e restauração. O backup não inclui os áudios.

Menu → Downloads: links individuais, playlists públicas e Mixes do YouTube; tela de marcação com miniaturas, duração e botão fixo Baixar (quantidade). MP3 real a 192 kbps, M4A e MP4; conversão local sem API paga. Filas de até 100 vídeos, até 50 para Mixes, com MP4 até 720p. Até duas reconexões para quedas transitórias, continuação validada quando aceita pelo servidor, cancelamento preservando os arquivos concluídos e relatório copiável. A disponibilidade dos vídeos depende do YouTube; não há login nem suporte a DRM.

Atualizações continuam pelo menu Atualizações do Onda principal. O manifesto confere pacote, versão e hash; o app confere o certificado antes de abrir o instalador do Android.

Licenças e fontes: esta edição do aplicativo é software livre sob GNU GPL v3 ou posterior, sem garantia, com licença na tela Downloads → Licença e código-fonte e no pacote de fontes Onda-Fontes.zip. Inclui NewPipe Extractor (GPL v3 ou posterior), LAME (GNU Library GPL v2 ou posterior) e LibVLC 3.7.7 © VideoLAN e colaboradores (LGPL 2.1 ou posterior); as dependências conservam suas respectivas licenças. Fontes do aplicativo, NewPipe e LAME estão anexadas a esta release. Fonte do LibVLC: https://code.videolan.org/videolan/libvlcjni .

Pacote: `{package_name}`. Código: {version_code}. APK ARM32 e ARM64 com certificado de teste fixado do projeto.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
