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
assert package_name == 'br.com.onda.player'
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
(output / 'onda-player-update.json').write_text(json.dumps(manifest, indent=2) + '\n')
shutil.copyfile(root / 'tools/recover_legacy_backup.py', output / 'Recuperar-backup-Onda.py')
shutil.copyfile(root / 'tools/RECUPERAR-BACKUP-LEIA-ME.txt', output / 'RECUPERAR-BACKUP-LEIA-ME.txt')
(output / 'notes.md').write_text(f"""Onda Novo {version_name} — Modos de escuta

Em Menu → Estúdio de som, escolha Equilibrado (volume gradual e transição de 1 segundo), Transições suaves (volume gradual e transição de 3 segundos) ou Sem equilíbrio ou transição. Também é possível ajustar a duração manualmente. As escolhas preservam equalizador, graves, realce de áudio baixo e ajustes de fala. Os controles anteriores continuam disponíveis.

O volume desce no fim e sobe na próxima música, sem sobreposição e sem um segundo tocador. O tempo da transição respeita a velocidade de reprodução. Pausar, buscar uma posição ou trocar a velocidade restaura o ganho e recalcula a transição. Trechos de coletâneas, rádios, YouTube, prévias e temporizador por faixas não recebem fade; o equilíbrio gradual continua disponível para áudio compatível no tocador.

Nenhuma varredura, novo modelo, serviço pago ou animação contínua. Processamento aproveita o tocador existente; não há análise de arquivos em segundo plano para escolher esses modos. Isso não representa garantia de consumo zero ou de volume igual em todas as gravações. Não foi incluída análise de humor ou identificação de ritmo.

Exportação de várias faixas em MP3, relatório, compartilhamento e demais recursos da versão anterior preservados. Mesma assinatura e pacote do Onda Novo instalado; atualize sem desinstalar.

Licenças: aplicativo GPLv3+; llama.cpp e Whisper.cpp MIT; NewPipe GPLv3+; LAME GPLv2+; LibVLC LGPL2.1+; PDFBox Android Apache2.0. Fontes acompanham a release; demais avisos no app. Sem garantia. Pacote `{package_name}`, código {version_code}.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
