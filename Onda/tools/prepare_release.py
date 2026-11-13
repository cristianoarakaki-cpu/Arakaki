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
(output / 'notes.md').write_text(f"""Onda Música {version_name} — Central inteligente e cores futuristas

Nova Central inteligente em Menu → Assistente com IA ou Atalhos → Central inteligente. Digite ou dite uma rotina, confira o plano e toque em Executar. Combina favoritas, reprodução, aleatório, repetição e temporizador; permite salvar pedidos no celular. Prepara buscas do YouTube e de imagens com o tema preenchido, além de abrir as telas do Onda. Exemplos: “toque minhas favoritas em ordem aleatória e pare em 30 minutos”, “pesquise Chitãozinho e Xororó no YouTube”, “imagens de boa noite”.

Interpretação local sem API paga, modelo pesado, microfone aberto ou tarefas permanentes. Reconhecimento de voz depende do Android e pode precisar de internet; conteúdo online exige conexão. Não automatiza ações desconhecidas ou confirmações do Android. Rotinas com músicas ausentes não alteram o tocador.

Economia de dados das rádios ativada por padrão: prioriza bitrates baixos na lista, mostra estimativa de MB por hora e escolhe a faixa mais leve em transmissões HLS adaptativas, com preferência até 64 kbps. Rádios de bitrate fixo continuam usando o fluxo da emissora; não é possível economizar dados comprimindo depois de receber. Pode voltar à qualidade original em Rádios → Economia de dados. Pausar continua encerrando a conexão, sem baixar áudio em segundo plano.

Controles com bordas multicoloridas e relevo estático em todas as interfaces. Aparências → Cores futuristas desliga esse acabamento. Mantém os dezenove temas, fontes, leão dourado, efeito de toque com economia de bateria e os recursos anteriores, incluindo PDF com voz, OCR, downloads, conversões, reprodução, favoritos, compartilhamento e rádios. Mesmo pacote e certificado: instale sobre a versão anterior, sem desinstalar.

Licenças e fontes: esta edição do aplicativo é software livre sob GNU GPL v3 ou posterior, sem garantia, com licença na tela Downloads → Licença e código-fonte e no pacote de fontes Onda-Fontes.zip. Inclui NewPipe Extractor (GPL v3 ou posterior), LAME (GNU Library GPL v2 ou posterior) e LibVLC 3.7.7 © VideoLAN e colaboradores (LGPL 2.1 ou posterior); as dependências conservam suas respectivas licenças. Fontes do aplicativo, NewPipe e LAME estão anexadas a esta release. Fonte do LibVLC: https://code.videolan.org/videolan/libvlcjni .

Pacote: `{package_name}`. Código: {version_code}. APK ARM32 e ARM64 com certificado de teste fixado do projeto.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
