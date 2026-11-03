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
(output / 'notes.md').write_text(f"""Onda Música {version_name} — YouTube flutuante e faixas da coletânea

YouTube: a janela flutuante ganha ações explícitas de reproduzir/pausar o vídeo e uma sessão de mídia própria. A música anterior recebe pausa explícita, preservando fila e posição, para não retomar quando o foco de áudio mudar. Botões do PiP e comandos de mídia passam a controlar o vídeo. Android 12 ou superior usa transição automática para PiP ao sair da tela cheia; aparelhos anteriores mantêm a entrada manual. A continuidade também depende do player oficial do YouTube e da permissão PiP; não acrescenta reprodução oculta ou com tela bloqueada.

Músicas → botão Faixas, ou Menu → Faixas da coletânea: análise local por pausas para criar uma lista de posições dentro do arquivo original. Toque numa faixa para buscar a posição no mesmo áudio; segure para renomear ou remover uma divisão incorreta. São divisões aproximadas, sem reconhecimento dos nomes: mixes contínuos e trechos curtos podem não ser separados. Não exporta arquivos individuais nem converte o áudio.

A análise só roda quando solicitada, pausa a reprodução, mostra progresso e é cancelada ao sair. Usa blocos pequenos de áudio, sem cópia integral ou serviço em segundo plano; os marcadores concluídos são salvos e reutilizados. Cancelamento mantém marcações anteriores e o arquivo original. Mantém relatórios de erro, downloads, PDF/OCR, favoritos, rádios, voz, aparências e demais funções.

Mesmo pacote e certificado; instalar sobre a versão anterior. Histórico: https://github.com/{repository}/tree/main/release-notes/onda

Licenças e fontes: esta edição do aplicativo é software livre sob GNU GPL v3 ou posterior, sem garantia, com licença na tela Downloads → Licença e código-fonte e no pacote de fontes Onda-Fontes.zip. Inclui NewPipe Extractor (GPL v3 ou posterior), LAME (GNU Library GPL v2 ou posterior) e LibVLC 3.7.7 © VideoLAN e colaboradores (LGPL 2.1 ou posterior); as dependências conservam suas respectivas licenças. Fontes do aplicativo, NewPipe e LAME estão anexadas a esta release. Fonte do LibVLC: https://code.videolan.org/videolan/libvlcjni .

Pacote: `{package_name}`. Código: {version_code}. APK ARM32 e ARM64 com certificado de teste fixado do projeto.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
