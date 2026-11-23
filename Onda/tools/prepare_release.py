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
(output / 'notes.md').write_text(f"""Onda Música {version_name} — Conversor de documentos e PDF

Menu → Documentos e PDF, Conversor local → Converter documentos e PDF, ou menu do leitor → Converter PDF.

Conversões locais sem conta ou serviço pago:
- Fotos JPG/PNG/WebP e formatos decodificados pelo Android → PDF, uma foto por página A4, na ordem recebida do seletor, originais preservados.
- TXT, CSV, MD, JSON e LOG em UTF-8/UTF-16 → PDF com texto paginado. CSV vira texto, não uma planilha diagramada.
- DOCX → PDF somente com o texto principal. Não mantém imagens, tabelas, estilos, cabeçalhos ou a diagramação do Word. DOC/XLS/PPT não são aceitos.
- PDF → TXT, extraindo o texto selecionável de todas as páginas. PDFs digitalizados precisam do OCR disponível no leitor; esta conversão não faz OCR automático.
- PDF → PNG: todas as páginas, até 1.600 pixels no maior lado, reunidas em um ZIP.

Novos arquivos podem ser abertos, salvos no local escolhido ou compartilhados pelo Android. Resultado temporário: use Salvar para guardar uma cópia. Sem teto fixo de páginas/fotos; depende do espaço, da memória e das regras do Android. PDFs protegidos não são desbloqueados. Processamento somente sob demanda, com Interromper, cancelado ao sair, sem serviços novos ou consultas recorrentes. Nenhuma nova biblioteca de conversão. Funções anteriores de música, vídeo, downloads, IA, fotos, rádios, OCR e leitura em voz alta preservadas.

NOVA ASSINATURA AUTORIZADA: esta é uma instalação independente, pacote br.com.onda.player e nome Onda Novo. Instale ao lado do Onda antigo sem desinstalá-lo. Não é atualização direta do pacote br.com.onda.musica. No antigo, Menu → Backup e restauração → Exportar backup; no novo, permita acesso às músicas e restaure o arquivo. Transfere favoritas de músicas, playlists e frases de voz. Histórico, ajustes, favoritos de vídeo/YouTube, modelos e mídias não são incluídos no backup. Pastas públicas permanecem no celular; pastas/documentos precisam ser selecionados novamente. Confira a transferência antes de remover o antigo. Futuras atualizações deste Onda Novo usam a nova assinatura e o manifesto onda-player-update.json; o canal do antigo permanece preservado. Modelos de IA continuam opcionais.

Licenças: aplicativo GNU GPL v3 ou posterior; llama.cpp/Whisper.cpp MIT; NewPipe GPL v3 ou posterior; LAME Library GPL v2 ou posterior; LibVLC LGPL2.1 ou posterior; PDFBox Android Apache2.0. Fontes acompanham a release; demais avisos em Downloads → Opções de download → Licença e código-fonte. Sem garantia. Pacote `{package_name}`, código {version_code}.
""")

with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
    file.write(f'tag={tag}\nversion={version_name}\n')
print(f'Preparada versão {version_name}, código {version_code}.')
