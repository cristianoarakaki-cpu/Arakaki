import subprocess,time,xml.etree.ElementTree as ET,json
from pathlib import Path
out=Path('Onda/lab-preview');out.mkdir(exist_ok=True,parents=True)
package='br.com.onda.musica.lab'
def adb(*args):return subprocess.check_output(['adb',*args],timeout=45)
def nodes():
 adb('shell','uiautomator','dump','/sdcard/onda-lab.xml')
 return ET.fromstring(adb('shell','cat','/sdcard/onda-lab.xml'))
def capture(name):
 (out/(name+'.png')).write_bytes(adb('exec-out','screencap','-p'))
 (out/(name+'.xml')).write_bytes(adb('shell','cat','/sdcard/onda-lab.xml'))
def tap(label):
 import re
 for n in nodes().iter('node'):
  if n.get('text','').casefold()==label.casefold():
   x1,y1,x2,y2=map(int,re.findall(r'\d+',n.get('bounds')));adb('shell','input','tap',str((x1+x2)//2),str((y1+y2)//2));return
 raise AssertionError(label)
def shared(text):
 adb('shell','am','start','-n',package+'/.DownloadsActivity','-a','android.intent.action.SEND','-t','text/plain','--es','android.intent.extra.TEXT',text);time.sleep(2)
shared('https://youtube.com.evil.test/watch?v=aqz-KE-bpKQ');tap('Analisar link');time.sleep(1)
assert any('Cole um link HTTPS' in n.get('text','') for n in nodes().iter('node'));capture('01-invalid-link')
shared('https://www.youtube.com/watch?v=aqz-KE-bpKQ');tap('Analisar link')
result='timeout'
for _ in range(50):
 time.sleep(4);texts=[n.get('text','') for n in nodes().iter('node')]
 if any('Áudio M4A' in t or 'Vídeo MP4' in t for t in texts):result='formats-found';break
 if any('Não foi possível analisar' in t for t in texts):result='provider-unavailable';break
capture('02-youtube-result')
(out/'live-result.json').write_text(json.dumps({'video':'Blender Big Buck Bunny (CC BY)','result':result,'note':'Live provider availability is separate from native mux and UI assertions.'},indent=2))
assert result!='timeout','Extractor did not finish within time budget'
adb('logcat','-d','-s','OndaDownload:I','*:S')
print('Native download UI passed; live provider:',result)
