#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
SDK="${FOLHA_ANDROID_SDK:-/workspace/android-sdk}"
BT="$SDK/build-tools/android-15"
PLATFORM="$SDK/platforms/android-35/android.jar"
mkdir -p build/classes build/dex
"$BT/aapt2" compile --dir res -o build/resources.zip
"$BT/aapt2" link -o build/base.apk --manifest AndroidManifest.xml -I "$PLATFORM" --java build/generated -A assets build/resources.zip
java -jar "$SDK/ecj.jar" -source 1.8 -target 1.8 -proc:none -bootclasspath "$PLATFORM:$BT/core-lambda-stubs.jar" -d build/classes src/com/folha/pdf/*.java
python - <<'PY'
import zipfile,pathlib
with zipfile.ZipFile('build/classes.jar','w') as z:
 for f in pathlib.Path('build/classes').rglob('*.class'):z.write(f,str(f.relative_to('build/classes')))
PY
"$BT/d8" --lib "$PLATFORM" --min-api 26 --output build/dex build/classes.jar
python - <<'PY'
import zipfile
with zipfile.ZipFile('build/base.apk','a',compression=zipfile.ZIP_DEFLATED) as z:z.write('build/dex/classes.dex','classes.dex')
PY
"$BT/zipalign" -f -p 4 build/base.apk build/aligned.apk
if [ ! -f build/folha-test.jks ]; then
 /usr/lib/jvm/java-21-openjdk-amd64/bin/keytool -genkeypair -keystore build/folha-test.jks -storepass android -keypass android -alias folha -keyalg RSA -keysize 2048 -validity 10000 -dname 'CN=Folha PDF, O=Local, C=BR'
fi
"$BT/apksigner" sign --ks build/folha-test.jks --ks-key-alias folha --ks-pass pass:android --key-pass pass:android --out /workspace/Folha-PDF-1.2.0.apk build/aligned.apk
"$BT/apksigner" verify --verbose /workspace/Folha-PDF-1.2.0.apk
