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
(output / 'notes.md').write_text(f"""Onda Novo {version_name} — Coletâneas editáveis

Abra Faixas no tocador. A análise por pausas continua disponível; agora é possível adicionar divisões manualmente e usar ⋮ em cada faixa para editar nome, início e fim, remover uma divisão ou salvar apenas aquele trecho em MP3 de 128, 192, 256 ou 320 kbps. Não identifica nomes de músicas automaticamente. Divisões por pausas são aproximadas e precisam ser conferidas.

Os limites são compartilhados entre faixas vizinhas, sem sobreposição nem lacunas. O início da primeira e o fim da última permanecem fixos. As marcações anteriores continuam compatíveis. Editar ou reanalisar libera a seleção e a repetição do trecho anterior, mantendo a posição; selecione novamente a faixa depois. Arquivo inteiro libera o trecho sem reiniciar a coletânea nem mudar uma pausa. O botão de repetição do tocador continua repetindo a faixa escolhida.

A exportação cria um novo MP3 no destino escolhido pelo Android e permite compartilhar o arquivo pronto. Decodifica somente o trecho necessário, com memória limitada, sem cópia WAV da coletânea inteira e sem serviços pagos. O arquivo original não é alterado. Mantenha a tela de exportação aberta; sair cancela e remove o destino incompleto quando o provedor permite. A compatibilidade depende dos codecs Android e da leitura direta do arquivo local.

Mesma assinatura e pacote do Onda Novo 0.79.0, preservando os dados numa atualização normal. Música, vídeo, downloads, rádio, PDF, IA local e demais recursos existentes preservados. Nenhum serviço contínuo ou modelo obrigatório acrescentado.

Licenças: aplicativo GPLv3+; llama.cpp e Whisper.cpp MIT; NewPipe GPLv3+; LAME GPLv2+; LibVLC LGPL2.1+; PDFBox Android Apache2.0. Fontes acompanham a release; demais avisos no app. Sem garantia. Pacote `{package_name}`, código {version_code}.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
