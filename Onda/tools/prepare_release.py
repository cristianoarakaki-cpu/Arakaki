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
(output / 'notes.md').write_text(f"""Onda Música {version_name} — controles claros, atalhos e ajuda

O tocador mostra por escrito se a repetição está desligada, repetindo uma música, um áudio do YouTube ou a fila. Ao tocar no mesmo botão de repetição, um aviso confirma a escolha. Avisos anteriores são cancelados ao alternar novamente.

Ao repetir uma faixa da coletânea, o nome aparece no tocador e os horários de início e fim ficam visíveis sob o nome, no espaço de metadados. São os limites da divisão selecionada, aproximados conforme a análise por pausas. A reprodução, os três modos das músicas comuns e o recorte nativo das faixas mantêm o comportamento anterior; o áudio original não é alterado.

Novo botão Atalhos na biblioteca: abre diretamente as telas escolhidas, sem acrescentar itens ao menu principal. Escolher atalhos permite marcar as telas e salvar; Cancelar mantém a seleção anterior. Essa preferência é independente dos favoritos de músicas, vídeos e rádios. As opções iniciais são YouTube, Imagens e mensagens e Rádios online.

Atalhos → Ajuda rápida explica onde ficam os controles e dá exemplos dos comandos de voz. Segurar o botão de repetição também abre essa ajuda. Nenhuma tela adicional nem serviço pago. Os textos acompanham os eventos existentes do player, sem novos temporizadores, varreduras ou microfone aberto em segundo plano.

Mantém a preferência por pt-BR quando disponível, nivelamento opcional de volume, economia de processamento com efeitos desligados, retomada, downloads, conversões, favoritos, músicas/vídeos/PDF, rádios, voz, OCR, aparências e demais recursos existentes.

Mesmo pacote e certificado; instalar sobre a versão anterior. Histórico: https://github.com/{repository}/tree/main/release-notes/onda

Licenças e fontes: esta edição do aplicativo é software livre sob GNU GPL v3 ou posterior, sem garantia, com licença na tela Downloads → Licença e código-fonte e no pacote de fontes Onda-Fontes.zip. Inclui NewPipe Extractor (GPL v3 ou posterior), LAME (GNU Library GPL v2 ou posterior) e LibVLC 3.7.7 © VideoLAN e colaboradores (LGPL 2.1 ou posterior); as dependências conservam suas respectivas licenças. Fontes do aplicativo, NewPipe e LAME estão anexadas a esta release. Fonte do LibVLC: https://code.videolan.org/videolan/libvlcjni .

Pacote: `{package_name}`. Código: {version_code}. APK ARM32 e ARM64 com certificado de teste fixado do projeto.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
