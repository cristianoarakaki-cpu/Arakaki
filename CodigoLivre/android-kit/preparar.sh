#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
if [ ! -d /data/data/com.termux/files/usr ]; then
  echo 'Execute este preparador no Termux oficial para Android.' >&2
  exit 1
fi
KIT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLS_DIR="$HOME/.local/share/codigolivre-android"
mkdir -p "$TOOLS_DIR"
echo 'Serão instalados Java, aapt/aapt2, D8, apksigner, zip e utilitários pelos repositórios do Termux.'
pkg update -y
pkg install -y openjdk-21 aapt d8 apksigner zip unzip curl coreutils
for program in javac jar keytool aapt2 d8 apksigner zip zipalign; do
  command -v "$program" >/dev/null || { echo "Ferramenta ausente: $program" >&2; exit 1; }
done
if [ ! -s "$TOOLS_DIR/android.jar" ]; then
  echo 'A plataforma Android 35 será obtida do Google (aproximadamente 62 MB).'
  echo 'Leia os termos oficiais antes de continuar: https://developer.android.com/studio/terms'
  read -r -p 'Você aceita os termos do SDK Android para este download? Digite ACEITO: ' answer
  [ "$answer" = ACEITO ] || { echo 'Preparação interrompida antes do download do SDK.'; exit 1; }
  PLATFORM_ZIP="$TOOLS_DIR/platform-35.zip"
  curl -fL --retry 2 --connect-timeout 20 https://dl.google.com/android/repository/platform-35_r02.zip -o "$PLATFORM_ZIP"
  printf '%s  %s\n' '0988cacad01b38a18a47bac14a0695f246bc76c1b06c0eeb8eb0dc825ab0c8e0' "$PLATFORM_ZIP" | sha256sum -c -
  FRAMEWORK_ENTRY="$(unzip -Z1 "$PLATFORM_ZIP" | awk '/^[^/]+\/android\.jar$/ {print}')"
  [ -n "$FRAMEWORK_ENTRY" ] || { echo 'android.jar não encontrado no pacote oficial.' >&2; exit 1; }
  unzip -p "$PLATFORM_ZIP" "$FRAMEWORK_ENTRY" > "$TOOLS_DIR/android.jar.tmp"
  mv "$TOOLS_DIR/android.jar.tmp" "$TOOLS_DIR/android.jar"
  rm "$PLATFORM_ZIP"
fi
printf '\nPreparação concluída. Para compilar o exemplo:\nbash "%s/compilar.sh" "%s/projeto"\n' "$KIT_DIR" "$KIT_DIR"
echo 'As chaves de assinatura serão criadas no armazenamento privado do Termux. Não as apague nem compartilhe.'
