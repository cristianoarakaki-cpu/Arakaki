"""Build a previous-source, differently-signed legacy fixture and a future same-key upgrade fixture.
No legacy private data/key is recovered or altered; these are emulator-only fixtures.
"""
from pathlib import Path
import os,subprocess,tarfile,io,zipfile,shutil
root=Path(__file__).resolve().parents[1]
legacy=Path(os.environ['RUNNER_TEMP'])/'onda-legacy-fixture'
legacy.mkdir(exist_ok=True)
archive=subprocess.check_output(['git','archive','2a8b4415ffe80898d6ef59392ac65f7878e20863','Onda'],cwd=root.parent)
with tarfile.open(fileobj=io.BytesIO(archive)) as t:t.extractall(legacy,filter='data')
module=legacy/'Onda';keys=module/'.signing';keys.mkdir(exist_ok=True)
subprocess.run(['keytool','-genkeypair','-keystore',str(keys/'debug.keystore'),'-storepass','android','-keypass','android','-alias','androiddebugkey','-dname','CN=Legacy Emulator Fixture Only','-keyalg','RSA','-keysize','2048','-validity','30'],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
# Use identical source native libraries already compiled for the current x86 emulator APK.
native=legacy/'native';native.mkdir(exist_ok=True)
with zipfile.ZipFile(root/'app/build/outputs/apk/debug/app-debug.apk') as z:
 for name in ['libonda_ai.so','libonda_whisper.so','libonda_mp3.so']:
  p=native/'x86_64'/name;p.parent.mkdir(exist_ok=True);p.write_bytes(z.read('lib/x86_64/'+name))
tests=module/'app/src/androidTest/java';shutil.rmtree(tests);target=tests/'br/com/onda';target.mkdir(parents=True);shutil.copyfile(root/'tests/LegacyMigrationFixtureTest.java',target/'LegacyMigrationFixtureTest.java')
env=os.environ.copy();env.pop('ONDA_SIGNING_PASSPHRASE',None)
subprocess.run(['gradle','--no-daemon','-p',str(module),'-PondaEmulator=true','-PondaNativeBundle='+str(native),'assembleDebug','assembleDebugAndroidTest'],env=env,check=True)
output=root/'migration-fixtures';output.mkdir(exist_ok=True)
shutil.copyfile(module/'app/build/outputs/apk/debug/app-debug.apk',output/'legacy.apk')
shutil.copyfile(module/'app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk',output/'legacy-test.apk')
# Verify a future update really keeps the new app's identity/data and signature.
config=root/'app/build.gradle';before=config.read_text()
try:
 assert 'versionCode 105;' in before
 config.write_text(before.replace('versionCode 105;','versionCode 106;'))
 subprocess.run(['gradle','--no-daemon','-p',str(root),'-PondaEmulator=true','-PondaNativeBundle='+str(native),'assembleDebug'],check=True)
 shutil.copyfile(root/'app/build/outputs/apk/debug/app-debug.apk',output/'future-update.apk')
finally:config.write_text(before)
# Restore the tested initial package for installation; the ARM distribution APK is stored separately.
shutil.copyfile(root/'migration-fixtures/current-x86.apk',root/'app/build/outputs/apk/debug/app-debug.apk')
print('Legacy fixture and future same-key update prepared; neither is a production release.')
