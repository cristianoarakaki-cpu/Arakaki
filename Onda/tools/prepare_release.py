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
(output / 'notes.md').write_text(f"""Onda Novo {version_name} — Marcações próprias na Memória Multimídia

No menu do tocador, do vídeo ou do PDF, escolha Marcar na memória. Dê um nome como Solo de guitarra, Refrão ou Explicação sobre juros. Em áudio e vídeo, confira início e fim, com milissegundos; em PDF, a página atual é capturada. Os horários são fixados ao abrir o formulário. O formulário não pausa a música nem solicita foco de áudio.

As marcações ficam nos trechos favoritos da Memória Multimídia e podem ser encontradas pela busca digitada ou por voz. Abrir um resultado usa o arquivo e a posição guardados. Para áudio e vídeo, continua disponível salvar o áudio do trecho em MP3 e compartilhar o MP3 salvo. Texto pode ser copiado ou compartilhado.

Toque numa marcação própria para renomear ou excluir apenas essa marcação. A busca e os favoritos são atualizados juntos. As notas próprias ficam separadas do índice de transcrições, PDFs e legendas: reanalisar o conteúdo não apaga as anotações. Se o arquivo original mudar, novas notas não serão misturadas aos horários antigos; confira e remova as marcações antigas do arquivo antes de criar outras.

Este recurso é manual: não identifica automaticamente solos ou instrumentos. Não baixa modelos, não lê o áudio e não cria um serviço em segundo plano para guardar uma nota. Salva somente metadados no celular, sem alterar os arquivos, a fila do tocador ou as favoritas de músicas. A análise opcional da versão anterior continua disponível separadamente.

Pacote e assinatura permanentes do Onda Novo preservados; atualize sem desinstalar. Recursos anteriores mantidos. Licenças: aplicativo GPLv3+; llama.cpp e Whisper.cpp MIT; NewPipe GPLv3+; LAME GPLv2+; LibVLC LGPL2.1+; PDFBox Android Apache2.0. Fontes acompanham a release; demais avisos no app. Sem garantia. Pacote `{package_name}`, código {version_code}.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
