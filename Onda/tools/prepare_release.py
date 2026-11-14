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
(output / 'notes.md').write_text(f"""Onda Música {version_name} — Tradução do canto ao vivo (experimental)

Em Letra da música → Ao vivo, escolha o idioma cantado, o idioma de destino e o modelo, com uma música ou rádio já tocando no tocador do Onda. Toque em Iniciar. O reconhecimento usa o áudio realmente decodificado pelo tocador, mesmo sem letra no catálogo, sem abrir o microfone e sem enviar o canto a um servidor. Mostra o trecho reconhecido e sua tradução automática.

É um recurso experimental: trabalha com janelas de 8 segundos, há atraso e podem ocorrer erros, sobretudo com instrumentos, coros, ruído, vozes sobrepostas e gravações antigas. Não garante identificação ou tradução de qualquer música. O modelo Equilibrado baixa cerca de 60 MB; Precisão, cerca de 190 MB e exige mais memória e processamento. Os idiomas do tradutor Google ML Kit usam aproximadamente 30 MB por idioma. O primeiro uso exige download, com escolha explícita entre Wi-Fi e dados móveis. Depois os modelos permitem processamento local, sem API paga ou cobrança por uso.

Funciona no áudio nativo de músicas e rádios, incluindo o áudio do YouTube aberto no tocador; não captura vídeos reproduzidos pela página WebView do YouTube ou pelo tocador de vídeo. Não inicia, pausa ou troca a música. Ao pausar a reprodução, o reconhecimento aguarda; ao sair desta tela ou tocar em Parar, encerra a captura e o reconhecimento. Mantém apenas uma janela em espera para evitar fila crescente em aparelhos lentos. Desativado por padrão, sem reconhecimento ou microfone em segundo plano. Ativado consome mais energia; desempenho e bateria variam por aparelho.

Mantém a busca e tradução das letras escritas, as faixas de coletâneas, identificação por metadados, rádios, downloads, conversões, PDF, temas e os demais recursos existentes. Mesmo pacote e assinatura: instale sobre a versão atual, sem desinstalar. Atualizadores anteriores à 0.74.0 ainda têm limite de 64 MB e precisam do link direto desta release; a partir da 0.74.0 o atualizador aceita até 256 MB com conferência de hash, pacote e certificado.

Licenças e fontes: aplicativo GNU GPL v3 ou posterior, sem garantia; Whisper.cpp e modelos Whisper MIT, NewPipe Extractor GPL v3 ou posterior, LAME GNU Library GPL v2 ou posterior e LibVLC 3.7.7 LGPL 2.1 ou posterior. Fontes do aplicativo e dos componentes Whisper.cpp, NewPipe e LAME estão anexadas. Fontes do LibVLC: https://code.videolan.org/videolan/libvlcjni . Avisos no app em Downloads → Licença e código-fonte. Dependências conservam suas licenças.

Pacote: `{package_name}`. Código: {version_code}. APK ARM32 e ARM64 com o certificado fixado do projeto. Modelos opcionais não são incluídos no APK.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
