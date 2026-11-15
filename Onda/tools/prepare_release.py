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
(output / 'notes.md').write_text(f"""Onda Música {version_name} — Interface mais limpa

Visual limpo ativado por padrão: menos bordas, relevos e gradientes nos controles, com cores de destaque reservadas às ações principais. Mantém o leão, as cores do tema e os dezenove temas existentes. Para recuperar os efeitos completos, abra Aparências → Opções de estilo e desligue Visual limpo. A troca do estilo atualiza a tela sem reiniciar o tocador.

Biblioteca com menos elementos repetidos: os cartões deixam de repetir o logotipo em cada resultado no visual limpo, ampliando o espaço para título e artista. Compartilhamento e favoritas permanecem acessíveis. O texto de repetição aparece quando há repetição ou uma faixa de coletânea selecionada.

Downloads prioriza o link, a análise e o andamento. Qualidade MP3, arquivos, histórico, relatório e licença ficam em Opções de download. Cancelar aparece durante uma operação ativa. As explicações completas continuam em Como funcionam os downloads.

Tradução ao vivo com mais espaço para o canto e a tradução. Idiomas e modelo ficam em uma seção expansível, com resumo visível da seleção; explicações completas em Como funciona. O aviso experimental permanece visível. Reconhecimento, modelos, tradução e comportamento da reprodução são os mesmos: sem microfone, sem upload do áudio e sem API paga; há atraso e possíveis erros. Para ao sair da tela mantendo a música.

Os controles continuam nativos, com ajuste à fonte do Android e rolagem. Esta mudança não adiciona downloads de imagens, tarefas de monitoramento ou animações contínuas. Botões animados continuam opcionais, com efeito breve ao toque e respeito à economia de bateria.

Mesmo pacote e assinatura: instale sobre a versão atual sem desinstalar, mantendo seus dados. O atualizador a partir da 0.74.0 aceita este tamanho de APK; versões anteriores precisam do link direto desta release.

Licenças e fontes: aplicativo GNU GPL v3 ou posterior, sem garantia; Whisper.cpp e modelos Whisper MIT, NewPipe Extractor GPL v3 ou posterior, LAME GNU Library GPL v2 ou posterior e LibVLC 3.7.7 LGPL 2.1 ou posterior. Fontes do aplicativo e dos componentes Whisper.cpp, NewPipe e LAME acompanham a release. Fontes do LibVLC: https://code.videolan.org/videolan/libvlcjni . Avisos no app em Downloads → Opções de download → Licença e código-fonte. Dependências conservam suas licenças.

Pacote: `{package_name}`. Código: {version_code}. APK ARM32 e ARM64 com o certificado fixado do projeto. Modelos opcionais não são incluídos no APK.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
