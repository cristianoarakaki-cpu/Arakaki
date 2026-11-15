#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/core-tests build/test-libs
fetch() {
  if [ ! -s "build/test-libs/$2" ]; then
    curl -fLsS --retry 2 "https://repo.maven.apache.org/maven2/$1" -o "build/test-libs/$2"
  fi
}
# Dependências exclusivas dos testes de SQLite em Linux/JVM; não entram no APK.
fetch org/xerial/sqlite-jdbc/3.46.1.0/sqlite-jdbc-3.46.1.0.jar sqlite-jdbc.jar
fetch org/slf4j/slf4j-api/2.0.16/slf4j-api-2.0.16.jar slf4j-api.jar
fetch org/slf4j/slf4j-nop/2.0.16/slf4j-nop-2.0.16.jar slf4j-nop.jar
javac -d build/core-tests \
 app/src/main/java/br/com/arakaki/codigolivre/{CodeFiles,DataFiles,SqliteSummary}.java \
 tests/{CodeFilesTest,DataFilesTest,SqliteSummaryTest}.java
for suite in CodeFilesTest DataFilesTest SqliteSummaryTest; do
  java -cp 'build/core-tests:build/test-libs/*' "br.com.arakaki.codigolivre.$suite"
done
