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
(output / 'notes.md').write_text(f"""Onda Música {version_name} — Onda IA local e fotos próprias

Nova tela Menu → Onda IA: perguntas e mensagens processadas no celular, sem conta ou API paga. Modelos opcionais: Leve (SmolLM2,105MB,para mensagens criativas simples, sem recomendação para informações factuais) e Completo (Qwen2.5-1.5B,cerca de 1,1GB). Download verificável, retomada e Wi-Fi por padrão. Pedidos e respostas não são enviados para servidores. O modelo Completo exige 64 bits e memória suficiente. Memória e desempenho variam por aparelho; celulares simples mantêm tarefas e criações manuais mesmo sem executar um modelo. O Onda mantém Android8 ou superior, ARM32 e ARM64. Não há garantia de IA generativa completa em qualquer smartphone.

Tarefas levam o pedido à Central inteligente para revisar e tocar em Executar. Respostas de IA não executam ações. O chat é experimental, pode errar e não consulta notícias em tempo real.

Cartões: a IA cria mensagens inéditas, ou você usa o próprio texto; a arte é composta no celular. Fotos próprias podem ser usadas como fundo, com originais preservados. Selecione uma ou várias fotos pelo seletor Android, sem teto de quantidade ou tamanho imposto pelo Onda, usando os formatos que o Android consegue decodificar. Imagens em nuvem podem precisar de conexão. Prévia temporária; Salvar mantém nova cópia em Onda/IA no Android10+ ou no local escolhido em versões anteriores. Compartilhamento pelo Android.

Clipes: animação do cartão em MP4 sem som, ou apresentação de todas as fotos selecionadas, três segundos por foto. A memória de leitura é limitada por foto, sem carregar o álbum inteiro. Não é geração de fotografias ou cenas de vídeo por descrição; o modelo de texto não interpreta o conteúdo das fotos. Som, legendas e recursos anteriores continuam disponíveis nas telas existentes.

Processamento somente sob demanda, até dois núcleos de CPU para a IA, com Interromper e cancelamento ao sair da tela. Sem serviço novo, microfone permanente, consulta contínua ou download automático dos modelos. Rotinas e tarefas leves continuam disponíveis em aparelhos que não têm memória para os modelos.

Mesmo pacote e assinatura: instale sobre a versão atual sem desinstalar, mantendo seus dados. O atualizador a partir da 0.74.0 aceita este tamanho de APK; versões anteriores precisam do link direto desta release.

Licenças e fontes: llama.cpp MIT; modelos opcionais SmolLM2 e Qwen2.5 Apache2.0, não incluídos no APK; aplicativo GNU GPL v3 ou posterior, sem garantia; Whisper.cpp e modelos Whisper MIT, NewPipe Extractor GPL v3 ou posterior, LAME GNU Library GPL v2 ou posterior e LibVLC 3.7.7 LGPL 2.1 ou posterior. Fontes do aplicativo e dos componentes llama.cpp, Whisper.cpp, NewPipe e LAME acompanham a release. Fontes do LibVLC: https://code.videolan.org/videolan/libvlcjni . Avisos no app em Downloads → Opções de download → Licença e código-fonte. Dependências conservam suas licenças.

Pacote: `{package_name}`. Código: {version_code}. APK ARM32 e ARM64 com o certificado fixado do projeto. Modelos opcionais não são incluídos no APK.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
