"""Confirm that the pre-signed release contains the exact reviewed frontend."""
import hashlib,json,pathlib,zipfile
root=pathlib.Path('PrismaVoz');source=json.loads((root/'distribution/source-sha256.json').read_text())
required={p.as_posix() for p in root.rglob('*') if p.is_file() and ((p.suffix=='.java' and (root/'src') in p.parents) or (p.parent==root/'assets' and p.suffix in {'.js','.css','.html'}) or p in [root/'AndroidManifest.xml',root/'version.json',root/'build.sh',root/'dependencies/manifest.json'])}
assert set(source)==required,'Lista de fontes do APK incompleta ou desatualizada'
for name,sha in source.items():assert hashlib.sha256(pathlib.Path(name).read_bytes()).hexdigest()==sha,'Fonte diferente do APK preparado: '+name
apk=pathlib.Path('prismavoz-publish/Prisma-Voz.apk')
with zipfile.ZipFile(apk) as z:
 for p in (root/'assets').rglob('*'):
  if p.is_file():assert z.read('assets/'+p.relative_to(root/'assets').as_posix())==p.read_bytes(),'Asset do APK diferente da fonte: '+p.name
 assert 'classes.dex' in z.namelist()
print('Fontes fixadas, assets próprios, bibliotecas e modelos no APK correspondem à versão preparada.')
