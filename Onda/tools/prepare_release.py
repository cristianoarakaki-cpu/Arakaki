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
(output / 'notes.md').write_text(f"""Onda Novo {version_name} — MP3 em segundo plano e detecção ajustável

Salvar faixa em MP3 agora continua ao minimizar o Onda, apagar a tela ou fechar a tela de exportação. A notificação mostra o andamento, permite cancelar e abre o resultado. Ao voltar, o botão Compartilhar reaparece para o MP3 concluído. Uma conversão por vez, com trecho e qualidade fixados no pedido. A análise em segundo plano da versão anterior foi preservada.

O original nunca é aberto para escrita. O destino deve ser um arquivo novo e vazio; aliases do original e destinos com conteúdo são rejeitados. Um descritor do destino é mantido durante a operação, evitando depender da tela para gravar. Cancelamento tenta remover a cópia incompleta; provedores que recusam exclusão podem deixar um arquivo vazio. Se o Android encerrar o processo à força, o destino pode estar incompleto; o Onda informa a interrupção e não retoma sozinho. Alguns provedores podem exigir novo acesso para compartilhar depois de fechar o aplicativo.

Em Faixas → Detecção, escolha Conservadora (pausas claras, faixas de pelo menos 30 s), Equilibrada (25 s) ou Sensível (20 s). Equilibrada é o padrão para novas análises. Os modos adaptáveis consideram o volume do arquivo, toleram ruído de fundo baixo e confirmam a retomada do som para reduzir cortes em estalos. Sensibilidade maior pode criar divisões extras em trechos suaves. São estimativas de limites, sem reconhecer nomes de músicas; mixes contínuos podem não separar. Os horários e nomes continuam editáveis, e marcações existentes não são alteradas sem solicitar análise.

Processamento local, sem serviços pagos, modelos novos, cópia WAV da coletânea inteira ou monitoramento contínuo. Recursos e bloqueio parcial de CPU são liberados ao terminar ou cancelar. Permita notificações para acompanhar o andamento. A duração em segundo plano está sujeita às regras do Android e do fabricante.

Mesma assinatura e pacote do Onda Novo instalado, preservando os dados em uma atualização normal. Música, vídeo, downloads, rádios, PDF e IA local existentes preservados.

Licenças: aplicativo GPLv3+; llama.cpp e Whisper.cpp MIT; NewPipe GPLv3+; LAME GPLv2+; LibVLC LGPL2.1+; PDFBox Android Apache2.0. Fontes acompanham a release; demais avisos no app. Sem garantia. Pacote `{package_name}`, código {version_code}.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
