"""Confirm that the pre-signed release contains the exact reviewed frontend."""
import hashlib,json,pathlib,zipfile
root=pathlib.Path('PrismaVoz');source=json.loads((root/'distribution/source-sha256.json').read_text())
from source_files import source_files
required={p.as_posix() for p in source_files(root)}
assert set(source)==required,'Lista de fontes do APK incompleta ou desatualizada'
for name,sha in source.items():assert hashlib.sha256(pathlib.Path(name).read_bytes()).hexdigest()==sha,'Fonte diferente do APK preparado: '+name
apk=pathlib.Path('prismavoz-publish/Prisma-Voz.apk')
with zipfile.ZipFile(apk) as z:
 native=json.loads((root/'version.json').read_text()).get('architecture')=='native'
 assets=root/('native-assets' if native else 'assets')
 for p in assets.rglob('*'):
  if p.is_file():assert z.read('assets/'+p.relative_to(assets).as_posix())==p.read_bytes(),'Asset do APK diferente da fonte: '+p.name
 assert 'classes.dex' in z.namelist()
 if native:assert not any(n.endswith(('.html','.js','.mjs','.wasm')) for n in z.namelist()),'Runtime web inesperado no APK nativo'
print('Fontes fixadas, assets próprios, bibliotecas e modelos no APK correspondem à versão preparada.')
