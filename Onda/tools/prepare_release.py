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
(output / 'notes.md').write_text(f"""Onda Novo {version_name} — Várias faixas em MP3

Abra Faixas no tocador e toque em ⇩ no topo. Marque as faixas desejadas, ou use Marcar todas/Limpar, escolha a qualidade MP3 e toque em Salvar selecionadas. A autorização da pasta do Onda é reutilizada; se necessário, o Android pede a pasta. Cada operação cria uma subpasta nova em Onda/Áudios. Os nomes preservam a numeração original das faixas e não sobrescrevem exportações anteriores.

A conversão é sequencial, continua com o app minimizado ou a tela apagada e mostra o andamento na notificação. Qualidade, nomes e horários ficam fixados no pedido. Uma conversão de áudio por vez, individual ou em seleção. Cancelar mantém os MP3 já concluídos. Uma falha numa faixa é registrada e as demais continuam, desde que o arquivo e as divisões ainda sejam válidos.

Ver resultados mostra o relatório da última seleção. Toque num arquivo concluído para ouvir no Onda ou compartilhar pelo Android. Os arquivos também ficam na pasta de áudios do Onda. O arquivo original e as marcações são preservados. Nenhum arquivo existente é aberto para sobrescrita; cada destino é criado novo e conferido antes de gravar.

Se o Android encerrar o processo à força ou atingir seu limite de processamento, a operação não reinicia sozinha. Os arquivos concluídos permanecem; confira o relatório e a pasta, pois o arquivo em processamento pode estar incompleto. Provedores de nuvem dependem das permissões e da conexão do próprio provedor.

Processamento local sem serviços pagos, novos modelos ou cópia WAV da coletânea inteira. Serviço e bloqueio parcial de CPU duram apenas durante a conversão solicitada, sendo liberados ao terminar ou cancelar. Análise com sensibilidades ajustáveis, exportação individual MP3, repetição de trechos e demais recursos anteriores preservados. Mesma assinatura e pacote do Onda Novo instalado; atualize sem desinstalar.

Licenças: aplicativo GPLv3+; llama.cpp e Whisper.cpp MIT; NewPipe GPLv3+; LAME GPLv2+; LibVLC LGPL2.1+; PDFBox Android Apache2.0. Fontes acompanham a release; demais avisos no app. Sem garantia. Pacote `{package_name}`, código {version_code}.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
