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
(output / 'notes.md').write_text(f"""Onda Música {version_name} — cores, toque leve e foto com música

Quatro interfaces novas: Festival, Algodão, Pôr do Sol e Lagoa, com fundos escuros, cores vivas e ícones em relevo. As quinze interfaces anteriores permanecem disponíveis. Escolha em Menu → Aparências.

Botões de texto, reprodução, favoritos, compartilhar, voz e menu ganham um leve efeito de pressão e retorno ao toque. O tamanho dos controles e a área de toque são preservados. Em Aparências, a opção Botões animados permite desligar o efeito.

Animações finitas de 85/130 ms, somente durante interação: sem repetição, temporizador de animação, camada permanente, rede ou serviço adicional. A economia de bateria e a opção de desligar animações do Android impedem o efeito. Ao ocultar, desativar ou remover o botão, a escala volta ao normal. Não há promessa de consumo zero: a meta é minimizar o trabalho visual. Prévias e fundos permanecem estáticos.

Foto com música do TikTok: além de salvar os originais separados, agora é possível escolher Vídeo MP4 • foto com música. O Onda monta a foto escolhida com o áudio em H.264/AAC, até 720 × 1280 com proporção preservada, somente quando solicitado. Em publicações com várias fotos, cada foto acessível pode ser escolhida para seu próprio vídeo. Não é uma montagem automática de todos os slides. A criação usa dois quadros por segundo para uma imagem estática e o codec nativo do aparelho; AAC compatível é reutilizado e outros áudios mono/estéreo compatíveis são convertidos para AAC. Usa processamento durante a montagem e mantém as opções de arquivos originais.

Contraste das dezenove interfaces verificado. Testes Android verificam toque real, clique, retorno ao repouso, ausência de redesenho ocioso, preferência e cancelamento; a regressão existente confere reprodução e recursos anteriores.

Mantém downloads de foto e áudio do TikTok, MP4, interfaces, reprodução, favoritos, compartilhamento, voz, PDF/OCR e rádios. Mesmo pacote e certificado; instale sobre a anterior. Histórico: https://github.com/{repository}/tree/main/release-notes/onda

Licenças e fontes: esta edição do aplicativo é software livre sob GNU GPL v3 ou posterior, sem garantia, com licença na tela Downloads → Licença e código-fonte e no pacote de fontes Onda-Fontes.zip. Inclui NewPipe Extractor (GPL v3 ou posterior), LAME (GNU Library GPL v2 ou posterior) e LibVLC 3.7.7 © VideoLAN e colaboradores (LGPL 2.1 ou posterior); as dependências conservam suas respectivas licenças. Fontes do aplicativo, NewPipe e LAME estão anexadas a esta release. Fonte do LibVLC: https://code.videolan.org/videolan/libvlcjni .

Pacote: `{package_name}`. Código: {version_code}. APK ARM32 e ARM64 com certificado de teste fixado do projeto.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
