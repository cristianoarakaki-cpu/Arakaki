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
(output / 'notes.md').write_text(f"""Onda Música {version_name} — Música identificada e tradução local das letras

IMPORTANTE: esta versão inclui o motor de tradução local e supera o limite de 64 MB dos atualizadores antigos. Instale Onda-Musica.apk pelo link direto desta release, sobre o aplicativo atual e sem desinstalar. O pacote e a assinatura são os mesmos. O atualizador desta versão passa a aceitar APKs de até 256 MB, mantendo conferência de hash, pacote, versão e certificado, e verifica espaço livre antes do download. Esta edição não pode ser baixada pelo atualizador das versões antigas que ainda têm o limite de 64 MB.

Toque no título da música no tocador ou no quadro da emissora em Rádios para abrir “Que música é esta?”. Mostra título, artista/intérprete, compositor e álbum quando disponíveis, com opção de copiar. A biblioteca também consulta o compositor informado pelo Android. Dados ausentes aparecem como “Não informado”.

O tocador acompanha os metadados recebidos durante a transmissão da rádio e mostra artista e música quando a emissora os envia. Nome, favoritos e endereço da emissora permanecem preservados. A identificação não grava áudio, não acessa microfone, não faz consultas externas e não adiciona tarefas de monitoramento. Trata-se de metadados, sem reconhecimento acústico; não identifica músicas quando o arquivo ou a emissora não fornecem informações. Compositor e intérprete são campos diferentes.

Tradução local de letras pelo Google ML Kit, sem API paga ou cobrança por uso. Em Letra da música → Traduzir letra, escolha o idioma original e o destino. A primeira utilização baixa modelos de aproximadamente 30 MB por idioma; Wi-Fi é o padrão oferecido, e dados móveis só são usados se o usuário escolher essa opção. A tradução processa cada verso uma vez e reutiliza refrões repetidos, com prioridade para o verso atual. Mantém o original visível, os tempos e o controle de reprodução. Modelos baixados permitem tradução offline. Traduções automáticas podem conter erros. Se a letra não tem tempos, a tradução também não inventa sincronização. Não transcreve o canto quando a letra original não está disponível.

Mantém a Central inteligente gratuita, os temas futuristas, economia de dados das rádios e todos os recursos existentes. Mesmo pacote e certificado; instale pelo link direto sobre a versão anterior sem desinstalar.

Licenças e fontes: esta edição do aplicativo é software livre sob GNU GPL v3 ou posterior, sem garantia, com licença na tela Downloads → Licença e código-fonte e no pacote de fontes Onda-Fontes.zip. Inclui NewPipe Extractor (GPL v3 ou posterior), LAME (GNU Library GPL v2 ou posterior) e LibVLC 3.7.7 © VideoLAN e colaboradores (LGPL 2.1 ou posterior); as dependências conservam suas respectivas licenças. Fontes do aplicativo, NewPipe e LAME estão anexadas a esta release. Fonte do LibVLC: https://code.videolan.org/videolan/libvlcjni .

Pacote: `{package_name}`. Código: {version_code}. APK ARM32 e ARM64 com certificado de teste fixado do projeto.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
