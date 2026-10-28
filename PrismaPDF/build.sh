#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
MODE=${1:-verify}
test "$MODE" = signed || test "$MODE" = verify
SDK=${ANDROID_HOME:?Defina ANDROID_HOME}
BT="$SDK/build-tools/35.0.0"
PLATFORM="$SDK/platforms/android-35/android.jar"
test -f "$PLATFORM" && test -x "$BT/aapt2"
python3 PrismaPDF/tools/vendor.py
rm -rf PrismaPDF/build
mkdir -p PrismaPDF/build/classes PrismaPDF/build/dex PrismaPDF/build/generated
python3 - <<'PY'
import json,pathlib,re
r=pathlib.Path('PrismaPDF');v=json.loads((r/'version.json').read_text());assert type(v['versionCode']) is int and v['versionCode']>0;assert re.fullmatch(r'\d+\.\d+\.\d+',v['versionName'])
s=(r/'AndroidManifest.xml').read_text().replace('${versionCode}',str(v['versionCode'])).replace('${versionName}',v['versionName']);(r/'build/AndroidManifest.xml').write_text(s)
PY
"$BT/aapt2" compile --dir PrismaPDF/res -o PrismaPDF/build/resources.zip
"$BT/aapt2" link -o PrismaPDF/build/base.apk --manifest PrismaPDF/build/AndroidManifest.xml -I "$PLATFORM" --java PrismaPDF/build/generated -A PrismaPDF/assets PrismaPDF/build/resources.zip
javac -source 8 -target 8 -encoding UTF-8 -proc:none -bootclasspath "$PLATFORM:$BT/core-lambda-stubs.jar" -d PrismaPDF/build/classes PrismaPDF/src/com/arakaki/prismapdf/*.java
python3 - <<'PY'
from pathlib import Path
from zipfile import ZipFile
r=Path('PrismaPDF/build')
with ZipFile(r/'classes.jar','w') as z:
 for f in (r/'classes').rglob('*.class'):z.write(f,f.relative_to(r/'classes'))
PY
"$BT/d8" --lib "$PLATFORM" --min-api 26 --output PrismaPDF/build/dex PrismaPDF/build/classes.jar
python3 - <<'PY'
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
r=Path('PrismaPDF/build')
with ZipFile(r/'base.apk','a',ZIP_DEFLATED) as z:
 for f in (r/'dex').glob('*.dex'):z.write(f,f.name)
PY
"$BT/zipalign" -f -p 4 PrismaPDF/build/base.apk PrismaPDF/build/aligned.apk
if [ "$MODE" = signed ]; then
 : "${PRISMA_KEYSTORE:?Chave permanente não preparada}" "${PRISMA_SIGNING_PASSWORD:?Senha não configurada}"
 "$BT/apksigner" sign --ks "$PRISMA_KEYSTORE" --ks-key-alias prisma-pdf --ks-pass env:PRISMA_SIGNING_PASSWORD --key-pass env:PRISMA_SIGNING_PASSWORD --out PrismaPDF/build/Prisma-PDF.apk PrismaPDF/build/aligned.apk
 python3 PrismaPDF/tools/release.py prepare
else
 cp PrismaPDF/build/aligned.apk PrismaPDF/build/Prisma-PDF-VALIDACAO.apk.unsigned
 "$BT/aapt" dump badging PrismaPDF/build/Prisma-PDF-VALIDACAO.apk.unsigned > PrismaPDF/build/metadata.txt
 head -1 PrismaPDF/build/metadata.txt
 echo 'Compilação validada. APKs instaláveis são distribuídos pelo fluxo Publicar Prisma PDF assinado.'
fi
