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
(output / 'notes.md').write_text(f"""Onda Música {version_name} — YouTube com áudio no tocador

Na aba YouTube, abra um vídeo e toque em Ouvir com tela desligada. O Onda consulta um áudio separado acessível e o reproduz no mesmo serviço nativo das músicas, com controles e notificação do vídeo escolhido. Aguarde a preparação antes de bloquear a tela. Não mantém WebView oculto em execução. A disponibilidade depende do YouTube; alguns vídeos e transmissões não oferecem áudio compatível ou exigem verificação. A falha aparece e é salva no relatório, sem iniciar a música anterior.

Removida a entrada automática do YouTube em janela flutuante. Tela cheia da página continua disponível; a janela flutuante dos vídeos locais permanece. A fila local é guardada enquanto o áudio do YouTube está ativo: Menu do YouTube → Voltar à fila de músicas restaura a fila pausada. Links temporários de áudio não são persistidos; ao reabrir após expiração, toque em Reproduzir para consultar novamente.

Mantém faixas da coletânea, rádios por cidade, downloads, conversões, PDF/OCR, favoritos, compartilhamento, voz, som, aparências e demais funções. Testes usam áudio real determinístico para verificar serviço, tela desligada, controles e falhas; não garantem disponibilidade de todos os vídeos do provedor.

Mesmo pacote e certificado; instalar sobre a versão anterior. Histórico: https://github.com/{repository}/tree/main/release-notes/onda

Licenças e fontes: esta edição do aplicativo é software livre sob GNU GPL v3 ou posterior, sem garantia, com licença na tela Downloads → Licença e código-fonte e no pacote de fontes Onda-Fontes.zip. Inclui NewPipe Extractor (GPL v3 ou posterior), LAME (GNU Library GPL v2 ou posterior) e LibVLC 3.7.7 © VideoLAN e colaboradores (LGPL 2.1 ou posterior); as dependências conservam suas respectivas licenças. Fontes do aplicativo, NewPipe e LAME estão anexadas a esta release. Fonte do LibVLC: https://code.videolan.org/videolan/libvlcjni .

Pacote: `{package_name}`. Código: {version_code}. APK ARM32 e ARM64 com certificado de teste fixado do projeto.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
