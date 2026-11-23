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
(output / 'notes.md').write_text(f"""Onda Novo {version_name} — Meu smartphone e correção do backup

Menu → Meu smartphone: fabricante/modelo, Android e correção de segurança, processador/arquiteturas informadas, RAM e armazenamento, bateria, energia, rede ativa e sensores anunciados pelo Android. Compartilhe um relatório somente quando escolher. Sem IMEI, número de série, nomes de redes, contas, lista de apps ou envio automático. Leitura sob demanda; sem monitoramento contínuo.

Testes manuais: cores exibidas, nove áreas de toque, sinal sonoro de até dois segundos, gravação local de microfone por até quatro segundos para ouvir e avaliar, vibração e sensores comuns por até oito segundos. Microfone pede permissão só ao testar. Recursos são liberados ao sair e a gravação temporária é apagada. Resultados de som/tela/microfone/vibração são observações do usuário; receber leituras de sensor não comprova calibração. Não é laudo, antivírus, medição de desgaste/capacidade real da bateria nem garantia de funcionamento de todo o hardware.

Backup: a mensagem genérica de 8 MB do antigo também era exibida ao rejeitar favoritas de downloads locais sem duração cadastrada. A correção permite essas referências no novo formato de metadados v2, mantém leitura de v1 válido, diferencia falhas de acesso/validação/tamanho/memória e amplia o limite de segurança para 64 MB. Restauração mantém dados atuais e não associa faixas ausentes ou ambíguas.

RECUPERAÇÃO DO ANTIGO: a nova instalação não pode alterar o app com assinatura perdida nem ler seus dados privados. Os anexos Recuperar-backup-Onda.py e RECUPERAR-BACKUP-LEIA-ME.txt oferecem recuperação opcional por um PC com Python3 e ADB, via USB e depuração autorizada pelo dono. A ferramenta lê metadados, não modifica o app antigo e não envia dados à internet. Requer que o build antigo aceite run-as e que o Android libere a consulta dos títulos; não há contorno de restrições. O JSON recuperado importa no Onda Novo após conferir a prévia. Áudios precisam continuar no celular; downloads não indexados podem precisar ser abertos novamente no novo. Histórico, ajustes, favoritos de vídeo/YouTube e modelos não entram nesse backup. Mantenha o antigo instalado até conferir a recuperação.

Esta versão atualiza Onda Novo 0.78.0 (pacote br.com.onda.player), com a mesma nova assinatura preservada por backup criptografado e Secret privado do proprietário, sem depender de cache. A instalação antiga br.com.onda.musica permanece separada. Canal onda-player-update.json. Recursos de música, vídeo, downloads, rádios, fotos/IA local, conversor de PDF, OCR e voz preservados. Não há novos serviços pagos ou modelos obrigatórios.

Licenças: aplicativo GPLv3+; llama.cpp e Whisper.cpp MIT; NewPipe GPLv3+; LAME Library GPLv2+; LibVLC LGPL2.1+; PDFBox Android Apache2.0. Fontes acompanham a release; outros avisos no app. Sem garantia. Pacote `{package_name}`, código {version_code}.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
