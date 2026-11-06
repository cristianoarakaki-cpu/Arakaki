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
(output / 'notes.md').write_text(f"""Onda Música {version_name} — fotos do TikTok com áudio

Reconhece links curtos que levam a publicações de fotos do TikTok. O link enviado pelo usuário contém uma foto com música, não um vídeo MP4: agora o Onda oferece as imagens e o áudio acessível separadamente, sem informar incorretamente que o link expirou e sem inventar um MP4.

Cada imagem pública é conferida pelo conteúdo e salva sem recodificar em Onda/Imagens, criada automaticamente dentro da pasta já autorizada. Áudio original reconhecido é preservado em Onda/Áudios. Abrir último arquivo e compartilhar continuam usando as opções existentes do Android. Não inclui criação de vídeo a partir da foto.

Confere a publicação exata, ignora recomendações, rejeita posts privados/restritos e páginas HTML disfarçadas de arquivos. A disponibilidade depende do que o TikTok libera em cada consulta; não resolve login ou verificações. Vídeos MP4 e conversões existentes permanecem disponíveis.

Mantém a correção de Atalhos, todos os recursos anteriores e a mesma assinatura. Nenhum serviço contínuo, SDK ou dependência adicionado. Testes de parser, conteúdo real, preservação da imagem e fluxo Android, além da regressão existente.

Mesmo pacote e certificado; instalar sobre a versão anterior. Histórico: https://github.com/{repository}/tree/main/release-notes/onda

Licenças e fontes: esta edição do aplicativo é software livre sob GNU GPL v3 ou posterior, sem garantia, com licença na tela Downloads → Licença e código-fonte e no pacote de fontes Onda-Fontes.zip. Inclui NewPipe Extractor (GPL v3 ou posterior), LAME (GNU Library GPL v2 ou posterior) e LibVLC 3.7.7 © VideoLAN e colaboradores (LGPL 2.1 ou posterior); as dependências conservam suas respectivas licenças. Fontes do aplicativo, NewPipe e LAME estão anexadas a esta release. Fonte do LibVLC: https://code.videolan.org/videolan/libvlcjni .

Pacote: `{package_name}`. Código: {version_code}. APK ARM32 e ARM64 com certificado de teste fixado do projeto.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
