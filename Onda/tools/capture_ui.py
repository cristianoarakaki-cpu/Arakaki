"""Capture the real Android UI with temporary local demo audio (not shipped in app)."""
from pathlib import Path
import math
import atexit
import re
import shlex
import struct
import subprocess
import time
import wave
import xml.etree.ElementTree as ET

PACKAGE='br.com.onda.musica'
OUTPUT=Path('Onda/ui-preview')
OUTPUT.mkdir(parents=True,exist_ok=True)
def adb(*args):
    return subprocess.check_output(['adb',*args],timeout=60)
def shell(*args):
    return adb('shell',shlex.join(str(a) for a in args))
def diagnostics():
    try:
        (OUTPUT/'android-logcat.txt').write_bytes(adb('logcat','-d','-v','threadtime'))
        (OUTPUT/'media-session.txt').write_bytes(shell('dumpsys','media_session'))
        (OUTPUT/'last-screen.png').write_bytes(adb('exec-out','screencap','-p'))
        (OUTPUT/'last-window.xml').write_bytes(shell('cat','/sdcard/onda-window.xml'))
    except Exception as e:
        print('Diagnostic collection:', e)
atexit.register(diagnostics)
def nodes():
    shell('uiautomator','dump','/sdcard/onda-window.xml')
    return list(ET.fromstring(shell('cat','/sdcard/onda-window.xml')).iter('node'))
def click(description=None,text=None,prefix=None):
    for node in nodes():
        attrs=node.attrib
        if (description is not None and attrs.get('content-desc')==description) or (text is not None and attrs.get('text')==text) or (prefix is not None and attrs.get('content-desc','').startswith(prefix)):
            coords=[int(v) for v in re.findall(r'\d+',attrs['bounds'])]
            shell('input','tap',(coords[0]+coords[2])//2,(coords[1]+coords[3])//2)
            time.sleep(1)
            return True
    return False
def capture(name):
    time.sleep(.5)
    (OUTPUT/(name+'.png')).write_bytes(adb('exec-out','screencap','-p'))
    (OUTPUT/(name+'.xml')).write_bytes(shell('cat','/sdcard/onda-window.xml'))

shell('wm','size','1080x1920')
shell('wm','density','420')
adb('install','-r','Onda/app/build/outputs/apk/debug/app-debug.apk')
shell('pm','grant',PACKAGE,'android.permission.READ_EXTERNAL_STORAGE')
shell('mkdir','-p','/sdcard/Music/OndaDemo')
for title,frequency in [('Noite Neon',220),('Horizonte Azul',330),('Entre Orbitas',440)]:
    file=Path('/tmp')/(title+'.wav')
    with wave.open(str(file),'wb') as wav:
        wav.setnchannels(1);wav.setsampwidth(2);wav.setframerate(8000)
        second=b''.join(struct.pack('<h',int(1000*math.sin(2*math.pi*frequency*i/8000))) for i in range(8000))
        for _ in range(60):wav.writeframesraw(second)
    remote='/sdcard/Music/OndaDemo/'+file.name
    adb('push',str(file),remote)
    shell('am','broadcast','-a','android.intent.action.MEDIA_SCANNER_SCAN_FILE','-d','file://'+remote)
time.sleep(2)
shell('am','start','-W','-n',PACKAGE+'/br.com.onda.MainActivity')
time.sleep(2)
# MediaStore metadata is only a visual fixture in this disposable emulator.
for title in ['Noite Neon','Horizonte Azul','Entre Orbitas']:
    try:
        shell('content','update','--uri','content://media/external/audio/media','--bind','artist:s:Onda Sessions','--where',"_display_name='"+title+".wav'")
    except subprocess.CalledProcessError:
        pass
assert click(description='Reler arquivos do celular'),'Rescan button unavailable'
time.sleep(1)
capture('01-biblioteca')
assert click(prefix='Tocar '),'Demo audio not visible in library'
time.sleep(1)
playing=False
for _ in range(5):
    if any(n.attrib.get('content-desc')=='Pausar' for n in nodes()):
        playing=True
        break
    time.sleep(1)
capture('02-reproducao')
assert playing,'Playback did not start' 
assert click(description='Ver letra da música'),'Lyrics button unavailable'
capture('03-letras')
shell('input','keyevent','4');time.sleep(.5)
assert click(description='Buscar e ouvir online'),'Online button unavailable'
capture('04-online')
shell('input','keyevent','4');time.sleep(.5)
assert click(description='Atualizações'),'Updates button unavailable'
capture('05-atualizacoes')
logs=adb('logcat','-d','-s','AndroidRuntime:E').decode(errors='replace')
assert 'FATAL EXCEPTION' not in logs,logs
print('Android UI: library, active playback, lyrics, online and updates captured; no fatal crash.')
