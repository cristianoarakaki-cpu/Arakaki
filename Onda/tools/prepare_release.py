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
(output / 'notes.md').write_text(f"""Onda Novo {version_name} — Edite a mistura do DJ

Em Menu → DJ Pessoal, segure uma música ou use o menu → Editar seleção. Mova a faixa para cima ou para baixo ou remova da prévia. O menu → Desfazer remoção recupera a última faixa removida, uma vez. Quantidade e duração estimada são atualizadas após cada edição.

As alterações atingem somente a prévia: não apagam arquivos, favoritas ou playlists e não alteram a música ou a fila em execução. Para começar a seleção ajustada, toque em Ouvir seleção ou numa faixa. Para guardar a ordem editada, use Salvar seleção como playlist. O diálogo de salvar mantém a seleção existente no momento em que foi aberto.

Nova mistura ou trocar o modo/duração gera outra seleção e encerra a possibilidade de desfazer a remoção anterior. A prévia é temporária e pode ser recriada se o Android recriar a tela; salve como playlist para guardar seus ajustes. Não há novas varreduras periódicas ou processamento de áudio para editar a lista.

Seleções por duração, modos de escuta, exportação em lote MP3 e demais recursos anteriores preservados. Processamento local, sem novo serviço pago. Mesma assinatura e pacote do Onda Novo; atualize sem desinstalar.

Licenças: aplicativo GPLv3+; llama.cpp e Whisper.cpp MIT; NewPipe GPLv3+; LAME GPLv2+; LibVLC LGPL2.1+; PDFBox Android Apache2.0. Fontes acompanham a release; demais avisos no app. Sem garantia. Pacote `{package_name}`, código {version_code}.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
