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
(output / 'notes.md').write_text(f"""Onda Música {version_name} — Selecionar vários para excluir

Selecione várias músicas, áudios ou vídeos e confirme a exclusão em conjunto. Acesso em Menu → Selecionar vários para excluir, ou segure um arquivo e escolha Selecionar vários para excluir. Usa a lista filtrada atual, com caixas de seleção, quantidade selecionada e selecionar/desmarcar todos. Só os arquivos marcados são processados.

Confirmação com quantidade e nomes dos arquivos antes de excluir. A exclusão é permanente, sem opção de desfazer no Onda. O Android ou provedor poderá pedir autorização adicional por arquivo. Ao cancelar uma autorização, o processo para e mantém os arquivos restantes. Arquivos já excluídos são contabilizados e as listas, filas e favoritas são atualizadas. Nenhuma pasta é percorrida para exclusão.

Lixeiras individuais, compartilhamento, bateria, temas e recursos anteriores mantidos. Processamento apenas durante a ação solicitada, sem serviço novo, consulta contínua ou acesso a todos os arquivos.

Mesmo pacote e assinatura: instale sobre a versão atual sem desinstalar, mantendo seus dados. O atualizador a partir da 0.74.0 aceita este tamanho de APK; versões anteriores precisam do link direto desta release.

Licenças e fontes: aplicativo GNU GPL v3 ou posterior, sem garantia; Whisper.cpp e modelos Whisper MIT, NewPipe Extractor GPL v3 ou posterior, LAME GNU Library GPL v2 ou posterior e LibVLC 3.7.7 LGPL 2.1 ou posterior. Fontes do aplicativo e dos componentes Whisper.cpp, NewPipe e LAME acompanham a release. Fontes do LibVLC: https://code.videolan.org/videolan/libvlcjni . Avisos no app em Downloads → Opções de download → Licença e código-fonte. Dependências conservam suas licenças.

Pacote: `{package_name}`. Código: {version_code}. APK ARM32 e ARM64 com o certificado fixado do projeto. Modelos opcionais não são incluídos no APK.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
