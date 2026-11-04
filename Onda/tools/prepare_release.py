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
(output / 'notes.md').write_text(f"""Onda Música {version_name} — continuidade, som e eficiência

Estúdio de som → Equilibrar volume entre faixas: ajuste opcional e gradual durante a reprodução de áudio compatível, com ganho limitado, canais ligados e proteção de picos. Não analisa arquivos inteiros nem usa serviços pagos. Começa desligado para preservar o som original. Pode suavizar a dinâmica e tornar ruídos da gravação mais perceptíveis. Aplica-se ao tocador de músicas e ao modo de áudio do YouTube; vídeos e o player da página usam tocadores separados.

O modo de áudio do YouTube prioriza português do Brasil antes da qualidade ou formato. Depois busca português sem região e outras variantes; se não houver português, prefere a faixa original quando identificada. A tela informa o idioma declarado ou a ausência dessa informação. Solicita localização pt-BR ao extrator, sem traduzir nem criar faixas inexistentes. A preferência só atua nas faixas acessíveis disponibilizadas pelo YouTube.

No modo de áudio do YouTube, o fim da reprodução volta ao início com um toque; marcadores antigos próximos ao fim são corrigidos durante a retomada. O estado diferencia carregamento, pausa, conclusão e áudio efetivamente tocando. Falhas de leitura aparecem na tela e continuam no relatório, sem iniciar a música anterior. A disponibilidade dos streams depende do YouTube.

Com os ajustes de áudio desligados, o processamento de PCM também usa cópia em bloco para buffers fragmentados, mantendo os bytes originais. Eventos repetidos do tocador deixam de regravar o mesmo progresso na prateleira em menos de um segundo. Mantém a frequência existente de salvamento e a reprodução com tela desligada; não adiciona análise contínua em segundo plano nem aplicativos pagos. Não é uma medição de autonomia do aparelho.

Mantém downloads, conversões, favoritos, retomada de músicas/vídeos/PDF, rádios, voz, OCR, aparências, faixas da coletânea e demais recursos existentes.

Mesmo pacote e certificado; instalar sobre a versão anterior. Histórico: https://github.com/{repository}/tree/main/release-notes/onda

Licenças e fontes: esta edição do aplicativo é software livre sob GNU GPL v3 ou posterior, sem garantia, com licença na tela Downloads → Licença e código-fonte e no pacote de fontes Onda-Fontes.zip. Inclui NewPipe Extractor (GPL v3 ou posterior), LAME (GNU Library GPL v2 ou posterior) e LibVLC 3.7.7 © VideoLAN e colaboradores (LGPL 2.1 ou posterior); as dependências conservam suas respectivas licenças. Fontes do aplicativo, NewPipe e LAME estão anexadas a esta release. Fonte do LibVLC: https://code.videolan.org/videolan/libvlcjni .

Pacote: `{package_name}`. Código: {version_code}. APK ARM32 e ARM64 com certificado de teste fixado do projeto.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
