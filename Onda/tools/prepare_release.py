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
(output / 'notes.md').write_text(f"""Onda Música {version_name} — revisão de interface para telas estreitas

Revisão das 28 telas principais com fonte de 130% em duas larguras. A checagem mede altura e largura dos textos, rótulos truncados em botões/seletores e controles fora da janela. Nomes longos de músicas e arquivos continuam usando reticências intencionais.

Biblioteca em telas estreitas: o filtro fica junto da busca, sem perder o microfone. O cabeçalho ocupa menos espaço, o título não fica cortado e a lista mantém área utilizável. Os controles de reprodução e a navegação continuam acessíveis.

Explorar: atalhos, busca, filtros e resultados agora compartilham uma área rolável; o tocador e a navegação inferior ficam separados. Os nomes das fontes e filtros podem ocupar mais de uma linha. Não muda as fontes de busca nem a reprodução. No DJ Pessoal, os seletores também mostram os nomes completos em mais de uma linha.

Mantém repetição de músicas, trechos e áudio do YouTube, preferência por pt-BR quando disponível, atalhos personalizáveis, downloads, conversões, favoritos, vídeos, PDF/OCR, rádios, voz, aparências e demais recursos existentes. Sem novas dependências, serviços, temporizadores ou análise contínua de layout no aplicativo.

Mesmo pacote e certificado; instalar sobre a versão anterior. Histórico: https://github.com/{repository}/tree/main/release-notes/onda

Licenças e fontes: esta edição do aplicativo é software livre sob GNU GPL v3 ou posterior, sem garantia, com licença na tela Downloads → Licença e código-fonte e no pacote de fontes Onda-Fontes.zip. Inclui NewPipe Extractor (GPL v3 ou posterior), LAME (GNU Library GPL v2 ou posterior) e LibVLC 3.7.7 © VideoLAN e colaboradores (LGPL 2.1 ou posterior); as dependências conservam suas respectivas licenças. Fontes do aplicativo, NewPipe e LAME estão anexadas a esta release. Fonte do LibVLC: https://code.videolan.org/videolan/libvlcjni .

Pacote: `{package_name}`. Código: {version_code}. APK ARM32 e ARM64 com certificado de teste fixado do projeto.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
