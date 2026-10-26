import pathlib,subprocess,zipfile
subprocess.run(['python3','FPlus/tools/prepare_release.py'],check=True)
root=pathlib.Path('FPlus/source/assets')
with zipfile.ZipFile('release-output/Folha-PDF.apk') as z:
 for entry in z.infolist():
  if entry.filename.startswith('assets/vendor/'):
   path=root/pathlib.PurePosixPath(entry.filename).relative_to('assets')
   assert '..' not in path.parts
   path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(z.read(entry))
print('Bibliotecas e modelos extraídos do APK preservado para FPlus/source/assets/vendor')
