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
(output / 'notes.md').write_text(f'Onda Música {version_name} — Música e vídeo\n\nBiblioteca de vídeos do celular com busca por nome, seletor de arquivos, reprodução interna, tela cheia e controles de posição. Motor LibVLC 3.7.7 para ampla compatibilidade de contêineres e codecs, incluindo MP4, MKV, AVI, MOV, WebM, FLV, WMV e MPEG/TS. A compatibilidade depende do codec e do arquivo; conteúdo com DRM não é suportado. Aceleração de hardware com tentativa por software em caso de falha.\n\nO vídeo pausa ao sair da tela; a música continua com suporte à tela desligada. Permissões de música e vídeo são separadas em Android 13 ou superior; Abrir arquivo funciona sem liberar toda a biblioteca. O APK é maior por incluir codecs nativos para diferentes processadores.\n\nAtualize sem remover a versão anterior. Pacote: `{package_name}`. Mesmo certificado de teste fixado do projeto.\n\nLibVLC © VideoLAN e colaboradores, LGPL 2.1 ou posterior. Licença inclusa no app. Código-fonte do motor: https://code.videolan.org/videolan/libvlcjni . Código e instruções do Onda neste repositório.\n')
with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
