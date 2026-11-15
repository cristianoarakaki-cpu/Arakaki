#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "${1:-$(dirname "$0")/projeto}" && pwd)"
TOOLS_DIR="${CODIGOLIVRE_TOOLS_DIR:-$HOME/.local/share/codigolivre-android}"
[ -f "$PROJECT_DIR/AndroidManifest.xml" ] || { echo 'Manifesto do projeto não encontrado.' >&2; exit 1; }
[ -f "$TOOLS_DIR/android.jar" ] || { echo 'Execute preparar.sh antes de compilar.' >&2; exit 1; }
for program in javac jar keytool aapt2 d8 apksigner zip zipalign; do
 command -v "$program" >/dev/null || { echo "Ferramenta ausente: $program" >&2; exit 1; }
done
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codigolivre-build.XXXXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT
mkdir -p "$WORK_DIR/generated" "$WORK_DIR/classes" "$PROJECT_DIR/saida" "$TOOLS_DIR"
echo '[1/5] Recursos Android'
aapt2 compile --dir "$PROJECT_DIR/res" -o "$WORK_DIR/resources.zip"
aapt2 link -I "$TOOLS_DIR/android.jar" --manifest "$PROJECT_DIR/AndroidManifest.xml" --java "$WORK_DIR/generated" --min-sdk-version 28 --target-sdk-version 35 -o "$WORK_DIR/resources.apk" "$WORK_DIR/resources.zip"
echo '[2/5] Código Java'
SOURCES=()
while IFS= read -r -d '' file; do SOURCES+=("$file"); done < <(find "$PROJECT_DIR/src" "$WORK_DIR/generated" -name '*.java' -type f -print0)
[ "${#SOURCES[@]}" -gt 0 ] || { echo 'Nenhum arquivo Java encontrado.' >&2; exit 1; }
javac -proc:none -source 8 -target 8 -encoding UTF-8 -classpath "$TOOLS_DIR/android.jar" -d "$WORK_DIR/classes" "${SOURCES[@]}"
jar cf "$WORK_DIR/classes.jar" -C "$WORK_DIR/classes" .
echo '[3/5] DEX'
d8 --lib "$TOOLS_DIR/android.jar" --min-api 28 --output "$WORK_DIR" "$WORK_DIR/classes.jar"
cp "$WORK_DIR/resources.apk" "$WORK_DIR/unsigned.apk"
zip -q -j "$WORK_DIR/unsigned.apk" "$WORK_DIR/classes.dex"
echo '[4/5] Alinhamento e assinatura'
zipalign -f 4 "$WORK_DIR/unsigned.apk" "$WORK_DIR/aligned.apk"
umask 077
if [ ! -f "$TOOLS_DIR/chave.keystore" ]; then
  [ ! -f "$TOOLS_DIR/chave.senha" ] || { echo 'Senha existente sem chave. Preserve os arquivos e recupere o backup antes de continuar.' >&2; exit 1; }
  od -An -N24 -tx1 /dev/urandom | tr -d ' \n' > "$TOOLS_DIR/chave.senha"
  keytool -genkeypair -noprompt -keystore "$TOOLS_DIR/chave.keystore" -storepass:file "$TOOLS_DIR/chave.senha" -keypass:file "$TOOLS_DIR/chave.senha" -alias codigolivre -keyalg RSA -keysize 2048 -validity 10000 -dname 'CN=Desenvolvedor Local,O=Codigo Livre,C=BR'
fi
apksigner sign --ks "$TOOLS_DIR/chave.keystore" --ks-key-alias codigolivre --ks-pass "file:$TOOLS_DIR/chave.senha" --out "$PROJECT_DIR/saida/MeuApp.apk" "$WORK_DIR/aligned.apk"
echo '[5/5] Verificação'
apksigner verify "$PROJECT_DIR/saida/MeuApp.apk"
printf '\nAPK gerado: %s/saida/MeuApp.apk\n' "$PROJECT_DIR"
echo 'No Termux, use termux-open com o caminho do APK para abrir o instalador e confirmar.'
