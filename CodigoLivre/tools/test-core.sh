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
fetch org/json/json/20240303/json-20240303.jar json.jar
fetch org/jsoup/jsoup/1.18.3/jsoup-1.18.3.jar jsoup.jar
fetch com/squareup/okhttp3/okhttp/4.12.0/okhttp-4.12.0.jar okhttp.jar
fetch com/squareup/okio/okio-jvm/3.6.0/okio-jvm-3.6.0.jar okio.jar
fetch org/jetbrains/kotlin/kotlin-stdlib/1.8.21/kotlin-stdlib-1.8.21.jar kotlin-stdlib.jar
javac -cp 'build/test-libs/*' -d build/core-tests \
 app/src/main/java/br/com/arakaki/codigolivre/{CodeFiles,DataFiles,SqliteSummary,LargeAnalysis,UpdatePolicy,AssistantModes,SpeedProfile,WebQuery,LiveFeeds,OnlineResearch,AndroidKit,WebSafety,PublicHttp,PublicPage,QuickWebAnswer,SearchRelevance}.java \
 tests/{CodeFilesTest,DataFilesTest,SqliteSummaryTest,LargeAnalysisTest,UpdatePolicyTest,SpeedProfileTest,OnlineResearchTest,PublicPageTest,LastGameTest}.java
for suite in CodeFilesTest DataFilesTest SqliteSummaryTest LargeAnalysisTest UpdatePolicyTest SpeedProfileTest OnlineResearchTest PublicPageTest LastGameTest; do
  java -cp 'build/core-tests:build/test-libs/*' "br.com.arakaki.codigolivre.$suite"
done
