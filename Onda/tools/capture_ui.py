"""Capture the real Android UI with temporary local demo audio (not shipped in app)."""
from pathlib import Path
import math
import atexit
import unicodedata
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
    shell('rm','-f','/sdcard/onda-window.xml')
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
    moved={'Reler arquivos do celular':'Recarregar biblioteca','Onda Lab':'Coleções inteligentes','Ver letra da música':'Letra da música','Atualizações':'Atualizações'}
    if description in moved:
        return click(description='Menu da biblioteca') and click(text=moved[description])
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
assert any(n.attrib.get('content-desc')=='Busca por voz no celular' for n in nodes()),'Local voice search button missing'
capture('01-biblioteca')
assert click(prefix='Tocar '),'Demo audio not visible in library'
time.sleep(1)
playing=False
for _ in range(5):
    session=shell('dumpsys','media_session').decode(errors='replace')
    if 'PlaybackState {state=3,' in session:
        playing=True
        break
    time.sleep(1)
capture('02-reproducao')
assert playing,'Playback did not start'
# Stop the changing counter before UIAutomator waits for an idle UI tree.
shell('input','keyevent','127')
time.sleep(1)
# Exercise the command execution path without assuming an emulator speech service.
shell('am','start','-W','-n',PACKAGE+'/br.com.onda.MainActivity','--activity-single-top','--es','voice_phrase','toque Onda Sessions')
time.sleep(31)
assert 'PlaybackState {state=3,' in shell('dumpsys','media_session').decode(errors='replace'),'Voice play command failed'
shell('am','start','-W','-n',PACKAGE+'/br.com.onda.MainActivity','--activity-single-top','--es','voice_phrase','pause')
time.sleep(1)
assert 'PlaybackState {state=2,' in shell('dumpsys','media_session').decode(errors='replace'),'Voice pause command failed'
# Seek near the end while paused, then verify automatic fade and next-track playback.
seek=next(n for n in nodes() if n.attrib.get('content-desc')=='Posição na música')
coords=[int(v) for v in re.findall(r'\d+',seek.attrib['bounds'])]
shell('input','tap',coords[0]+int((coords[2]-coords[0])*.90),(coords[1]+coords[3])//2)
shell('input','keyevent','126');time.sleep(8)
fade_log=adb('logcat','-d','-s','OndaFade:D').decode(errors='replace')
assert 'fade-out' in fade_log and 'fade-in' in fade_log,fade_log
shell('input','keyevent','127');time.sleep(1)
assert click(description='Onda Lab'),'Smart library entry unavailable'
assert any(n.attrib.get('content-desc')=='Coleção inteligente' for n in nodes()),'Smart collections missing'
capture('08-onda-lab')
assert click(description='Coleção inteligente')
assert click(text='Mais tocadas')
assert any('1 reproduções' in n.attrib.get('text','') for n in nodes()),'Actual listening history was not recorded'
capture('10-mais-tocadas')
assert click(description='Coleção inteligente')
assert click(text='Redescobrir')
assert any(n.attrib.get('content-desc','').startswith('Tocar ') for n in nodes()),'Rediscovery has no local music'
capture('09-redescobrir')
shell('input','keyevent','4');time.sleep(.5)
assert click(description='Ver letra da música'),'Lyrics button unavailable'
capture('03-letras')
shell('input','keyevent','4');time.sleep(.5)
assert click(description='Buscar e ouvir online'),'Online button unavailable'
assert any(n.attrib.get('content-desc')=='Busca por voz na internet' for n in nodes()),'Online voice search button missing'
capture('04-online')
assert click(description='Buscar no acervo online'),'Online search field unavailable'
shell('input','text','Chitaozinho%se%sxororo')
assert click(text='Buscar online  ↗'),'Search action unavailable'
found=False
for _ in range(12):
    tree=nodes()
    for node in tree:
        desc=node.attrib.get('content-desc','')
        plain=''.join(c for c in unicodedata.normalize('NFD',desc.lower()) if unicodedata.category(c)!='Mn')
        if desc.startswith('Ouvir prévia de ') and 'chitaozinho' in plain and 'xororo' in plain:
            found=True
            break
    if found:break
    time.sleep(2)
assert found,'Chitaozinho e xororo not found in Android catalog search'
capture('06-busca-artista')
assert click(prefix='Ouvir prévia de '),'Preview action unavailable'
started=False
for _ in range(15):
    if 'PlaybackState {state=3,' in shell('dumpsys','media_session').decode(errors='replace'):
        started=True
        break
    time.sleep(1)
assert started,'Online preview did not start on Android'
capture('07-previa-artista')
shell('input','keyevent','127');time.sleep(1)
shell('input','keyevent','4');time.sleep(.5)
assert click(description='Atualizações'),'Updates button unavailable'
capture('05-atualizacoes')
logs=adb('logcat','-d','-s','AndroidRuntime:E').decode(errors='replace')
assert 'FATAL EXCEPTION' not in logs,logs
print('Android UI: library, active playback, lyrics, online and updates captured; no fatal crash.')
