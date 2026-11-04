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
(output / 'notes.md').write_text(f"""Onda Música {version_name} — repetição de faixas e atalhos por voz

O botão de repetição do tocador também controla o áudio extraído pelo modo “Ouvir com tela desligada”. Toque para ativar “↻ 1” e repetir o mesmo áudio do YouTube; toque novamente para desligar. A escolha é separada da fila local e preservada ao consultar novamente o mesmo vídeo. Outra origem começa sem repetição. Streams continuam sujeitos à disponibilidade e expiração do provedor.

Em Faixas da coletânea, escolha uma faixa e volte ao tocador. Ative “↻ 1” para repetir apenas o intervalo selecionado. O player usa os limites nativos de reprodução, sem cortar ou converter o arquivo. Ao desligar, a reprodução continua no arquivo inteiro, na posição correspondente. As divisões por pausas continuam aproximadas; confira as marcações antes de usá-las. Os nomes editáveis não são reconhecimento automático de músicas.

A retomada guarda a posição absoluta e valida o arquivo e as divisões antes de restaurar a seleção. Se as divisões ou o arquivo mudarem, o recorte não é reutilizado. A fila e o arquivo original são preservados. Músicas comuns mantêm os três modos de repetição; rádios ao vivo continuam sem repetição.

Atalhos por voz: “abra YouTube”, “abra imagens”, “abra atualizações”, “abra rádios”, “abra vídeos”, “abra downloads”, “abra PDF”, “abra estúdio de som”, “abra conversor”, “abra playlists”, “abra fila”, “abra aparências”, “abra arquivos”, “abra músicas”, “abra faixas da coletânea” e “abra minhas frases”. Também aceita pedidos explícitos como “ir para a aba imagens”. Busca e reprodução por nome mantêm seu significado. Minhas frases permite associar expressões próprias a essas telas; atalhos antigos são preservados. “Repita esta faixa” usa a seleção da coletânea quando houver.

Usa o player, os eventos e o reconhecimento de voz já existentes. Não mantém microfone aberto, não adiciona serviços pagos, varredura periódica ou nova extração de áudio a cada repetição. A disponibilidade do reconhecimento depende do serviço do aparelho.

Mantém preferência por pt-BR quando disponível, nivelamento opcional de volume, melhorias de processamento, downloads, conversões, favoritos, músicas/vídeos/PDF, rádios, voz, OCR, aparências e demais recursos existentes.

Mesmo pacote e certificado; instalar sobre a versão anterior. Histórico: https://github.com/{repository}/tree/main/release-notes/onda

Licenças e fontes: esta edição do aplicativo é software livre sob GNU GPL v3 ou posterior, sem garantia, com licença na tela Downloads → Licença e código-fonte e no pacote de fontes Onda-Fontes.zip. Inclui NewPipe Extractor (GPL v3 ou posterior), LAME (GNU Library GPL v2 ou posterior) e LibVLC 3.7.7 © VideoLAN e colaboradores (LGPL 2.1 ou posterior); as dependências conservam suas respectivas licenças. Fontes do aplicativo, NewPipe e LAME estão anexadas a esta release. Fonte do LibVLC: https://code.videolan.org/videolan/libvlcjni .

Pacote: `{package_name}`. Código: {version_code}. APK ARM32 e ARM64 com certificado de teste fixado do projeto.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
