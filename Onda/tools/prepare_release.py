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
(output / 'notes.md').write_text(f"""Onda Novo {version_name} — Análise de coletâneas em segundo plano

Correção: minimizar o Onda, apagar a tela ou fechar a tela de faixas não cancela mais a análise da coletânea. Um serviço de primeiro plano realiza a leitura local, exibe o andamento na notificação e permite cancelar. Ao voltar à tela, o resultado e o andamento são recuperados. O resultado pertence sempre ao arquivo analisado, mesmo se outro áudio for selecionado durante o processamento. Uma análise por vez.

A reprodução é pausada quando você solicita a análise e não reinicia automaticamente ao concluir. A análise continua procurando pausas aproximadas, sem identificar nomes de músicas. Os arquivos originais são preservados. Cancelar mantém as marcações anteriores. Se o Android encerrar o processo ou atingir seu limite de processamento em segundo plano, o Onda informa a interrupção, preserva as marcações e permite iniciar novamente; não reinicia trabalho sozinho.

Economia de bateria: serviço e bloqueio parcial de CPU existem somente durante a análise solicitada; são liberados ao terminar, cancelar ou interromper. Sem manter a tela acesa, copiar a coletânea inteira, acesso à internet, novos modelos ou serviços pagos. Notificações de progresso menos frequentes em segundo plano. A permissão de notificação é solicitada no Android 13+ para acompanhar o andamento; o comportamento também está sujeito às regras do Android e do fabricante.

Faixas editáveis, repetição de trechos e exportação MP3 da versão 0.80.0 preservadas. A exportação MP3 continua sendo uma operação da própria tela; esta correção trata especificamente da análise da coletânea. Mesma assinatura e pacote do Onda Novo instalado; atualização mantém seus dados.

Licenças: aplicativo GPLv3+; llama.cpp e Whisper.cpp MIT; NewPipe GPLv3+; LAME GPLv2+; LibVLC LGPL2.1+; PDFBox Android Apache2.0. Fontes acompanham a release; demais avisos no app. Sem garantia. Pacote `{package_name}`, código {version_code}.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
