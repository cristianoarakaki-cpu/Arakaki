#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
MODE=${1:-verify}
test "$MODE" = verify
SDK=${ANDROID_HOME:?Defina ANDROID_HOME}
BT="$SDK/build-tools/35.0.0"
PLATFORM="$SDK/platforms/android-35/android.jar"
test -f "$PLATFORM" && test -x "$BT/aapt2"
python3 PrismaVoz/tools/vendor.py
rm -rf PrismaVoz/build
mkdir -p PrismaVoz/build/classes PrismaVoz/build/dex PrismaVoz/build/generated
python3 - <<'PY'
import json,pathlib,re
r=pathlib.Path('PrismaVoz');v=json.loads((r/'version.json').read_text());assert type(v['versionCode']) is int and v['versionCode']>0;assert re.fullmatch(r'\d+\.\d+\.\d+',v['versionName'])
s=(r/'AndroidManifest.xml').read_text().replace('${versionCode}',str(v['versionCode'])).replace('${versionName}',v['versionName']);(r/'build/AndroidManifest.xml').write_text(s)
PY
"$BT/aapt2" compile --dir PrismaVoz/res -o PrismaVoz/build/resources.zip
"$BT/aapt2" link -o PrismaVoz/build/base.apk --manifest PrismaVoz/build/AndroidManifest.xml -I "$PLATFORM" --java PrismaVoz/build/generated -A PrismaVoz/assets PrismaVoz/build/resources.zip
javac -source 8 -target 8 -encoding UTF-8 -proc:none -bootclasspath "$PLATFORM:$BT/core-lambda-stubs.jar" -d PrismaVoz/build/classes PrismaVoz/src/com/arakaki/prismavoz/*.java
python3 - <<'PY'
from pathlib import Path
from zipfile import ZipFile
r=Path('PrismaVoz/build')
with ZipFile(r/'classes.jar','w') as z:
 for f in (r/'classes').rglob('*.class'):z.write(f,f.relative_to(r/'classes'))
PY
"$BT/d8" --lib "$PLATFORM" --min-api 26 --output PrismaVoz/build/dex PrismaVoz/build/classes.jar
python3 - <<'PY'
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
r=Path('PrismaVoz/build')
with ZipFile(r/'base.apk','a',ZIP_DEFLATED) as z:
 for f in (r/'dex').glob('*.dex'):z.write(f,f.name)
PY
"$BT/zipalign" -f -p 4 PrismaVoz/build/base.apk PrismaVoz/build/aligned.apk
cp PrismaVoz/build/aligned.apk PrismaVoz/build/Prisma-Voz-VALIDACAO.apk.unsigned
"$BT/aapt" dump badging PrismaVoz/build/Prisma-Voz-VALIDACAO.apk.unsigned > PrismaVoz/build/metadata.txt
head -1 PrismaVoz/build/metadata.txt
