from pathlib import Path
import zipfile
root=Path(__file__).resolve().parents[1]
output=root/'app/src/main/assets/CodigoLivre-Android-Kit.zip'
with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED) as z:
 for p in sorted((root/'android-kit').rglob('*')):
  if p.is_file() and 'saida' not in p.parts:z.write(p,p.relative_to(root/'android-kit'))
print(output)
