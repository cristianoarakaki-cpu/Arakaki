"""Emulator-only process restart check using the queue created by the native service test."""
import subprocess,shlex,json,time,re,xml.etree.ElementTree as ET
from pathlib import Path
PACKAGE='br.com.onda.musica'
def adb(*args):return subprocess.check_output(['adb',*args],timeout=60)
def shell(*args):return adb('shell',shlex.join(str(v) for v in args))
assert any(shell('getprop',p).strip()==b'1' for p in ('ro.kernel.qemu','ro.boot.qemu')),'Only the CI emulator may run this fixture'
def prefs(name):
 root=ET.fromstring(shell('run-as',PACKAGE,'cat','shared_prefs/'+name+'.xml'));return {n.get('name'):(n.text or '') if n.tag=='string' else n.get('value') for n in root}
fixture=prefs('ci_dj_memory');expected=[fixture['local_id'],fixture['download_id']]
initial=prefs('music_resume');out=Path('Onda/ui-preview');out.mkdir(exist_ok=True,parents=True);(out/'dj-memory-before-stop.json').write_text(json.dumps(initial,indent=2));assert json.loads(initial['queue'])==expected,('Queue changed before process restart',initial)
time.sleep(1);shell('am','force-stop',PACKAGE);adb('logcat','-c');shell('am','start','-W','-n',PACKAGE+'/br.com.onda.MainActivity')
for _ in range(40):
 log=adb('logcat','-d','-s','OndaResume:D').decode(errors='replace')
 if 'restored count=2 index=1 position=12000' in log:break
 time.sleep(.25)
else:
 (out/'dj-memory-after-failure.json').write_text(json.dumps(prefs('music_resume'),indent=2));(out/'dj-memory-failure-logcat.txt').write_bytes(adb('logcat','-d'));(out/'dj-memory-failure.png').write_bytes(adb('exec-out','screencap','-p'));raise AssertionError('Mixed queue was not restored: '+log)
def nodes():
 shell('uiautomator','dump','/sdcard/onda-memory.xml');return list(ET.fromstring(shell('cat','/sdcard/onda-memory.xml')).iter('node'))
def tap_node(node):
 v=list(map(int,re.findall(r'\d+',node.get('bounds'))));shell('input','tap',(v[0]+v[2])//2,(v[1]+v[3])//2);time.sleep(.4)
# Read the actual menu order so adding entries does not make a deep option unreachable.
source=(Path(__file__).resolve().parents[1]/'app/src/main/java/br/com/onda/MainActivity.java').read_text()
menu_source=source.split('private void showLibraryMenu',1)[1]
menu_labels=json.loads('['+re.search(r'new String\[\]\{(.*?)\}',menu_source,re.S).group(1)+']')
def tap(text,desc=False):
 for _ in range(24):
  current=nodes();target=next((n for n in current if n.get('content-desc' if desc else 'text','').casefold()==text.casefold()),None)
  listing=next((n for n in current if n.get('content-desc')=='Opções do menu'),None)
  if target is not None:
   bounds=list(map(int,re.findall(r'\d+',target.get('bounds'))));visible=bounds[3]>bounds[1]
   if listing is not None:
    box=list(map(int,re.findall(r'\d+',listing.get('bounds'))));visible=visible and bounds[1]>=box[1] and bounds[3]<=box[3] and bounds[3]-bounds[1]>=40
   if visible:tap_node(target);return
  if listing is not None:
   left,top,right,bottom=map(int,re.findall(r'\d+',listing.get('bounds')));up=False
   if target is not None:up=bounds[1]<top
   elif text in menu_labels:
    wanted=menu_labels.index(text);visible_rows=[menu_labels.index(n.get('text')) for n in current if n.get('text') in menu_labels and int(re.findall(r'\d+',n.get('bounds'))[3])>top]
    if visible_rows:up=min(visible_rows)>wanted
   y1=top+(bottom-top)*(3 if up else 7)//10;y2=top+(bottom-top)*(7 if up else 3)//10
   shell('input','swipe',(left+right)//2,y1,(left+right)//2,y2,420)
  time.sleep(.2)
 (out/'dj-memory-menu-failure.xml').write_bytes(shell('cat','/sdcard/onda-memory.xml'))
 (out/'dj-memory-menu-failure.png').write_bytes(adb('exec-out','screencap','-p'))
 raise AssertionError('Menu/control not reachable: '+text)

try:
 state=prefs('music_resume');assert json.loads(state['queue'])==expected;cue=json.loads(state['dj_context'])[fixture['download_id']];assert cue['mode']==3 and cue['reason']=='Preferência salva no teste'
 tree=nodes();assert any(n.get('text')=='Retomada download CI' for n in tree),'Restored download metadata missing'
 assert any(n.get('content-desc')=='Reproduzir' for n in tree),'Restored session should stay paused'
 assert 'PlaybackState {state=3,' not in shell('dumpsys','media_session').decode(),'Restart autoplayed'
 tap('Menu da biblioteca',True);tap('Ajustar sessão');tap('Por que esta música?');assert any(n.get('text')=='Preferência salva no teste' for n in nodes()),'Restored explanation was not displayed'
 out=Path('Onda/ui-preview');out.mkdir(exist_ok=True,parents=True);(out/'26-dj-memoria.png').write_bytes(adb('exec-out','screencap','-p'))
 (out/'dj-memory-tests.json').write_text(json.dumps({'processRestart':True,'mixedLocalAndDownloadQueue':True,'sameOrder':True,'index':1,'positionMs':12000,'paused':True,'reasonRestored':True,'modeRestored':True},indent=2))
 print('DJ memory: real service, process restart, mixed queue, order, 12-second position, paused state and restored explanation passed.')
finally:
 # Remove the test document reference; never delete any audio files.
 shell('am','force-stop',PACKAGE)
 root=ET.Element('map');ET.SubElement(root,'string',name='documents').text=fixture['original_documents']
 xml=ET.tostring(root,encoding='utf-8',xml_declaration=True)
 subprocess.run(['adb','shell',shlex.join(['run-as',PACKAGE,'sh','-c','cat > shared_prefs/downloaded_audio.xml'])],input=xml,check=True,timeout=60)
 shell('run-as',PACKAGE,'rm','-f','shared_prefs/ci_dj_memory.xml','shared_prefs/music_resume.xml')
 shell('am','start','-W','-n',PACKAGE+'/br.com.onda.MainActivity');time.sleep(.5)
