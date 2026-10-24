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
(output / 'notes.md').write_text(f"""Onda Música {version_name} — Memória e preferências do DJ

Retomada de filas com músicas locais e downloads, preservando ordem, posição, modo e motivos das escolhas do DJ. O app volta pausado. Ajustar sessão → Evitar esta música no DJ: exclui a faixa das próximas recomendações sem remover o arquivo ou a marcação de favorita. Pode dizer “evite esta música” e criar um atalho em Minhas frases. Reautorizar músicas evitadas permite voltar atrás; vale para novas seleções. As preferências de evitação ficam somente neste celular e não fazem parte do backup de listas. DJ Pessoal com modos Para você, Só favoritas, Redescobrir, Minha viagem e Downloads e redescobertas. Prévia com motivo de cada escolha. Menu Ajustar sessão: mais variedade, mais do artista atual e evitar repetir artistas nas próximas, preservando a música atual e sua posição. Voz: monte minha viagem; mais variedade; mais desse artista; toque minhas favoritas sem repetir artista; por que esta música? Atalhos também em Minhas frases. Aprende com favoritas, escutas e reproduções que chegam naturalmente ao fim após pelo menos 80% de escuta real, a partir desta versão. Seleção e interpretação locais, sem API paga; reconhecimento de fala depende do serviço Android. Sem microfone contínuo nem análise em segundo plano. Mantém a correção das favoritas de downloads. Instale sobre o Onda Música atual, sem desinstalar. Mesmo pacote e certificado: preserva os dados do Onda principal. O Lab é outro aplicativo; para trazer suas listas e frases dele, use Backup e restauração. O backup não inclui os áudios.

Menu → Downloads: links individuais, playlists públicas e Mixes do YouTube; tela de marcação com miniaturas, duração e botão fixo Baixar (quantidade). MP3 real a 192 kbps, M4A e MP4; conversão local sem API paga. Filas de até 100 vídeos, até 50 para Mixes, com MP4 até 720p. Até duas reconexões para quedas transitórias, continuação validada quando aceita pelo servidor, cancelamento preservando os arquivos concluídos e relatório copiável. A disponibilidade dos vídeos depende do YouTube; não há login nem suporte a DRM.

Atualizações continuam pelo menu Atualizações do Onda principal. O manifesto confere pacote, versão e hash; o app confere o certificado antes de abrir o instalador do Android.

Licenças e fontes: esta edição do aplicativo é software livre sob GNU GPL v3 ou posterior, sem garantia, com licença na tela Downloads → Licença e código-fonte e no pacote de fontes Onda-Fontes.zip. Inclui NewPipe Extractor (GPL v3 ou posterior), LAME (GNU Library GPL v2 ou posterior) e LibVLC 3.7.7 © VideoLAN e colaboradores (LGPL 2.1 ou posterior); as dependências conservam suas respectivas licenças. Fontes do aplicativo, NewPipe e LAME estão anexadas a esta release. Fonte do LibVLC: https://code.videolan.org/videolan/libvlcjni .

Pacote: `{package_name}`. Código: {version_code}. APK ARM32 e ARM64 com certificado de teste fixado do projeto.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
