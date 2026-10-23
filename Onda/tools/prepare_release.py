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
(output / 'notes.md').write_text(f'Onda Música {version_name} — Playlists\n\nMenu → Playlists: criar, renomear, escolher músicas por título ou artista, mover faixas e remover. Listas salvas no aparelho, sem cobrança ou sincronização. Ouvir lista toca as músicas disponíveis na ordem exibida. Excluir uma lista preserva os arquivos.\n\nMantidos som, DJ, voz e vídeos. Mesmo pacote e certificado para instalar sobre 0.16.0 sem desinstalar.\n\nVídeos: LibVLC 3.7.7 © VideoLAN e colaboradores, LGPL 2.1 ou posterior. Licença inclusa. Fonte: https://code.videolan.org/videolan/libvlcjni .\n\nPacote: `{package_name}`. Certificado de teste fixado do projeto.\n')

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
