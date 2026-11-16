"""Gera o índice público após copiar o APK assinado para entregas/. Não envia arquivos."""
from pathlib import Path
import sys,re,json,hashlib
app=Path(__file__).resolve().parents[1]
repo=app.parent
apk=Path(sys.argv[1]).resolve()
relative=apk.relative_to(repo).as_posix()
if not relative.startswith('entregas/') or apk.suffix!='.apk':
    raise SystemExit('Escolha o APK assinado dentro de entregas/.')
build=(app/'app/build.gradle').read_text()
version=re.search(r"versionName '([^']+)'",build).group(1)
code=int(re.search(r'versionCode (\d+)',build).group(1))
if apk.name!=f'CodigoLivre-{version}-arm64.apk':
    raise SystemExit('Nome do APK não corresponde à versão do projeto.')
index={
 'packageName':'br.com.arakaki.codigolivre',
 'versionCode':code,'versionName':version,
 'url':'https://raw.githubusercontent.com/cristianoarakaki-cpu/Arakaki/entrega/codigo-livre-android-offline/'+relative,
 'sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),
 'bytes':apk.stat().st_size,
 'notes':'IA online com Gemini, Groq e modelos gratuitos OpenRouter; alternância respeitando cotas, chaves cifradas no aparelho e envio de anexos apenas com autorização.'
}
(app/'update.json').write_text(json.dumps(index,ensure_ascii=False,indent=2)+'\n')
print('Índice atualizado:',app/'update.json')
