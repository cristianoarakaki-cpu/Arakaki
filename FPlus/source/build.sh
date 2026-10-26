#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT"
MODE=${1:-verify}
test "$MODE" = verify || test "$MODE" = production
SDK=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}
: "${SDK:?Defina ANDROID_HOME com SDK Android instalado}"
BT="$SDK/build-tools/35.0.0"
PLATFORM="$SDK/platforms/android-35/android.jar"
test -f "$PLATFORM" && test -x "$BT/aapt2"
for tool in javac java keytool python3; do command -v "$tool" >/dev/null; done
export FPLUS_BUILD_MODE="$MODE"
python3 FPlus/tools/extract_vendor.py
rm -rf FPlus/source/build
mkdir -p FPlus/source/build/classes FPlus/source/build/dex FPlus/source/build/generated
python3 - <<'PY'
from pathlib import Path
import json,os,re
r=Path('FPlus/source');v=json.loads((r/'version.json').read_text());assert re.fullmatch(r'\d+\.\d+\.\d+',v['versionName']);assert type(v['versionCode']) is int and v['versionCode']>15
prod=os.environ['FPLUS_BUILD_MODE']=='production'
pairs={'applicationId':'com.folha.pd2' if prod else 'com.folha.pd2.dev','appLabel':'Folha PDF+' if prod else 'Folha PDF+ Teste','versionCode':str(v['versionCode']),'versionName':v['versionName'] if prod else v['versionName']+'-teste'}
s=(r/'AndroidManifest.xml').read_text()
for key,value in pairs.items():s=s.replace('${'+key+'}',value)
(r/'build/AndroidManifest.xml').write_text(s)
PY
"$BT/aapt2" compile --dir FPlus/source/res -o FPlus/source/build/resources.zip
"$BT/aapt2" link -o FPlus/source/build/base.apk --manifest FPlus/source/build/AndroidManifest.xml -I "$PLATFORM" --java FPlus/source/build/generated -A FPlus/source/assets FPlus/source/build/resources.zip
javac -source 8 -target 8 -proc:none -encoding UTF-8 -bootclasspath "$PLATFORM:$BT/core-lambda-stubs.jar" -d FPlus/source/build/classes FPlus/source/src/com/folha/pd2/*.java
python3 - <<'PY'
from pathlib import Path
from zipfile import ZipFile
r=Path('FPlus/source/build')
with ZipFile(r/'classes.jar','w') as z:
 for f in (r/'classes').rglob('*.class'):z.write(f,f.relative_to(r/'classes'))
PY
"$BT/d8" --lib "$PLATFORM" --min-api 26 --output FPlus/source/build/dex FPlus/source/build/classes.jar
python3 - <<'PY'
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
r=Path('FPlus/source/build')
with ZipFile(r/'base.apk','a',ZIP_DEFLATED) as z:
 for f in (r/'dex').glob('*.dex'):z.write(f,f.name)
PY
"$BT/zipalign" -f -p 4 FPlus/source/build/base.apk FPlus/source/build/aligned.apk
if [ "$MODE" = production ]; then
 : "${FPLUS_KEYSTORE_BASE64:?Chave original ausente}" "${FPLUS_STORE_PASSWORD:?Senha ausente}" "${FPLUS_KEY_PASSWORD:?Senha da chave ausente}" "${FPLUS_KEY_ALIAS:?Alias ausente}"
 KEY_FILE=$(mktemp "${RUNNER_TEMP:-/tmp}/fplus-keystore.XXXXXX")
 export FPLUS_KEY_FILE="$KEY_FILE"
 trap 'rm -f "$KEY_FILE"' EXIT
 python3 - <<'PY'
import os,base64,pathlib
p=pathlib.Path(os.environ['FPLUS_KEY_FILE']);p.write_bytes(base64.b64decode(os.environ['FPLUS_KEYSTORE_BASE64'],validate=True));p.chmod(0o600)
PY
 "$BT/apksigner" sign --ks "$KEY_FILE" --ks-key-alias "$FPLUS_KEY_ALIAS" --ks-pass env:FPLUS_STORE_PASSWORD --key-pass env:FPLUS_KEY_PASSWORD --out FPlus/source/build/Folha-PDF.apk FPlus/source/build/aligned.apk
else
 cp FPlus/source/build/aligned.apk FPlus/source/build/Folha-PDF-Plus-VALIDACAO.apk.unsigned
 echo 'Sem chave original: validação sem assinatura. Nenhum APK instalável foi gerado.'
fi
if [ "$MODE" = production ]; then
 python3 FPlus/source/tools/build_release_info.py
 python3 FPlus/tools/verify_signature.py "$BT/apksigner" "$BT/aapt"
else
 "$BT/aapt" dump badging FPlus/source/build/Folha-PDF-Plus-VALIDACAO.apk.unsigned > FPlus/source/build/metadata.txt
 head -1 FPlus/source/build/metadata.txt
fi
