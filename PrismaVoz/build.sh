#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
test "${1:-verify}" = verify
: "${ANDROID_HOME:?Defina ANDROID_HOME}"
GRADLE_EXECUTABLE="${PRISMA_GRADLE:-gradle}"
"$GRADLE_EXECUTABLE" --no-daemon -p PrismaVoz/native-build assembleRelease testReleaseUnitTest
mkdir -p PrismaVoz/build
cp PrismaVoz/native-build/build/outputs/apk/release/PrismaVozNative-release-unsigned.apk PrismaVoz/build/aligned.apk
cp PrismaVoz/build/aligned.apk PrismaVoz/build/Prisma-Voz-VALIDACAO.apk.unsigned
"$ANDROID_HOME/build-tools/35.0.0/aapt" dump badging PrismaVoz/build/aligned.apk > PrismaVoz/build/metadata.txt
head -1 PrismaVoz/build/metadata.txt
