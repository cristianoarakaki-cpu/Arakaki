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
assert package_name == 'br.com.onda.player'
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
(output / 'onda-player-update.json').write_text(json.dumps(manifest, indent=2) + '\n')
shutil.copyfile(root / 'tools/recover_legacy_backup.py', output / 'Recuperar-backup-Onda.py')
shutil.copyfile(root / 'tools/RECUPERAR-BACKUP-LEIA-ME.txt', output / 'RECUPERAR-BACKUP-LEIA-ME.txt')
(output / 'notes.md').write_text(f"""Onda Novo {version_name} — Memória Multimídia local

Abra Menu → Memória Multimídia, ou diga Abra memória. Em Adicionar, escolha um PDF com texto, um áudio/vídeo acompanhado de legenda SRT/VTT, ou transcrição local de fala. A busca procura palavras e prefixos do conteúdo indexado, aceita acentos e simplifica perguntas em português; não é busca semântica nem identifica solos musicais.

Os resultados abrem PDFs na página e mídias no horário encontrado. É possível marcar favoritos, copiar ou compartilhar o texto e salvar apenas o áudio do trecho em MP3. A exportação usa o serviço de conversão existente, continua minimizada e respeita a qualidade escolhida. Não há recorte de vídeo MP4 nesta entrega. Confira os horários antes de exportar.

Transcrição de fala é opcional: no menu, Preparar voz por Wi-Fi baixa um modelo de cerca de 60 MB. Não há download automático ao escolher um arquivo. Reconhecimento roda no celular, depende de memória, codecs e compatibilidade do aparelho e pode errar, principalmente em músicas. Os horários de voz são aproximados, em janelas de até 20 segundos. A infraestrutura nativa ARM existente foi preservada. O microfone de busca usa o serviço de reconhecimento do Android.

PDFs precisam permitir extração de texto. Não há OCR de todas as páginas nesta análise; PDFs digitalizados podem não produzir resultados. Legendas aceitam até 4 MB e PDFs até 64 MB, respeitando a capacidade do leitor. Até 100 resultados por busca, refináveis por palavras. O arquivo original permanece inalterado. Reindexe em Arquivos lembrados após alterações. Remover da memória apaga o índice e suas marcações, sem apagar o arquivo.

Análise explícita em serviço com notificação, cancelamento e liberação de recursos ao terminar. Não há escuta permanente, varredura periódica ou envio dos arquivos pelo Onda. Se houver falha ou cancelamento durante a extração, a transação preserva o índice anterior. Encerramento forçado pelo Android exige iniciar novamente; resultados concluídos ficam no armazenamento privado do app. Atualização preserva dados pelo mesmo pacote e assinatura. Todos os recursos anteriores permanecem disponíveis.

Licenças: aplicativo GPLv3+; llama.cpp e Whisper.cpp MIT; NewPipe GPLv3+; LAME GPLv2+; LibVLC LGPL2.1+; PDFBox Android Apache2.0. Fontes acompanham a release; demais avisos no app. Sem garantia. Pacote `{package_name}`, código {version_code}.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
