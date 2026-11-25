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
(output / 'notes.md').write_text(f"""Onda Novo {version_name} — DJ por duração e playlists

Em Menu → DJ Pessoal, escolha o modo e uma quantidade de músicas ou até 15, 30, 60 ou 90 minutos. O DJ monta uma prévia com faixas inteiras usando a duração informada pelos arquivos. A estimativa vale em velocidade 1×; não é um temporizador e pode ficar abaixo do tempo escolhido. Velocidade, transições, dados incorretos e pausas alteram o tempo real.

As seleções por duração excluem arquivos sem duração conhecida ou maiores que o tempo escolhido. Favoritas, preferências de músicas evitadas, histórico e filtragem de cópias continuam sendo respeitados pelo planejador existente. As opções por quantidade mantêm o comportamento anterior, incluindo downloads sem duração. A montagem não altera a música ou a fila em execução; Ouvir seleção ou tocar uma linha inicia a nova fila, como antes.

No menu do DJ, use Salvar seleção como playlist, digite um nome e confirme. A ordem exibida no momento de abrir o diálogo é preservada, mesmo se uma nova mistura for montada depois. Nomes vazios ou repetidos são recusados. Cancelar não grava nada. A playlist fica no aparelho e usa os arquivos originais, sem copiá-los. Arquivos removidos ou sem permissão podem aparecer como indisponíveis nas playlists existentes.

Cálculo local sob demanda no trabalhador do DJ, sem ler o áudio, novos modelos ou serviço pago. Não há varredura periódica nem análise de humor. Modos de escuta, exportação em lote para MP3, relatórios e demais recursos anteriores preservados. Mesma assinatura e pacote do Onda Novo; atualize sem desinstalar.

Licenças: aplicativo GPLv3+; llama.cpp e Whisper.cpp MIT; NewPipe GPLv3+; LAME GPLv2+; LibVLC LGPL2.1+; PDFBox Android Apache2.0. Fontes acompanham a release; demais avisos no app. Sem garantia. Pacote `{package_name}`, código {version_code}.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
