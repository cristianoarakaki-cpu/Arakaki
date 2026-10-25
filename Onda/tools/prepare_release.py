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
(output / 'notes.md').write_text(f"""Onda Música {version_name} — Interface, tela cheia e boletos

Coração de favoritas redesenhado como ícone vetorial, sem depender da fonte do Android e sem recortes nas laterais. Botão com área de toque de 48 × 48 dp, contorno quando não favorito e preenchido quando favorito. Cartão Tocando agora com mais separação entre título, artista e coração, altura adaptável aos textos, barra de posição mais espaçada e tempo mais legível. Mantém as favoritas salvas e os demais recursos.

Tela cheia: controles sobrepostos sem reduzir a área da imagem. Somem após 3,5 segundos durante a reprodução; toque na imagem para mostrar ou ocultar. Pausar mantém os controles visíveis; a busca reinicia o prazo. Mantém exploração por toque acessível, Voltar e janela flutuante. A atualização do progresso da interface para enquanto os controles estão ocultos.

PDF → Menu → Texto da página: seleção nativa de trechos para copiar e botão Copiar texto. Extração local da página atual usando PdfBox-Android 2.0.27.0, Apache License 2.0. Até 16 MB para extrair e 100.000 caracteres por página; leitura visual até 64 MB. Respeita a permissão de cópia do documento. PDFs digitalizados podem não conter texto; não há OCR. Sem API paga ou envio a servidor. Licença e avisos da biblioteca incluídos em Downloads → Licença e código-fonte. Fonte: https://github.com/TomRoush/PdfBox-Android .

PDF → Menu → Reconhecer boleto: linhas digitáveis bancárias de 47 dígitos e de arrecadação de 48, além de código de barras ITF de 44 dígitos, com conversão para linha digitável e verificação dos dígitos de controle. Um código consistente é copiado automaticamente e exibido; vários resultados abrem escolha. Análise local da página atual, sob comando do usuário, usando texto e barras legíveis, inclusive rotação. Sem pagamento automático, QR Pix ou OCR geral. A consistência matemática não autentica o boleto. Leitura de barras por ZXing 3.5.3, Apache 2.0; avisos e licença incluídos. Fonte: https://github.com/zxing/zxing .

Vídeos → Menu → Modo Aprender: velocidades de 0,5× a 2×, repetição A–B sem limite ou por 3, 5 e 10 passagens completas, com pausa ao concluir. Ativar ou alterar velocidade prepara o vídeo pausado; toque em Reproduzir. Velocidade e repetição valem na sessão do vídeo; outro arquivo volta a 1×. Momentos salvos → Anotação: texto local editável de até 1.000 caracteres; renomear preserva a nota. Marcações antigas são mantidas e notas não alteram o vídeo nem integram o backup de listas.

Leitor de PDF nos menus da biblioteca, Explorar e vídeos: seletor de arquivos do Android, anterior/próxima, Ir à página, zoom de 50% a 200% e retomada do último PDF na página lida quando o acesso persiste. Aceita Abrir com Onda para PDFs com permissão de leitura. Leitura nativa local, uma página por vez, com resolução limitada para controlar memória. Até 64 MB e 5.000 páginas; PDFs com senha não suportados. Não é editor nem OCR. Sem nova permissão ou serviço pago. Arquivos de nuvem dependem do provedor selecionado. Mantém música de fundo sem solicitar foco de áudio.

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
