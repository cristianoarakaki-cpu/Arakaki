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
 adb('shell','am','start','-n',package+'/br.com.onda.DownloadsActivity','-f','0x20000000','-a','android.intent.action.SEND','-t','text/plain','--es','android.intent.extra.TEXT',text);time.sleep(2)
 assert any(n.get('content-desc')=='Link do vídeo' and n.get('text')==text for n in nodes().iter('node')),'Shared link did not reach input'
shared('https://youtube.com.evil.test/watch?v=aqz-KE-bpKQ');tap('Analisar link');time.sleep(1)
assert any('Cole um link HTTPS' in n.get('text','') for n in nodes().iter('node'));capture('01-invalid-link')
shared('https://www.youtube.com/watch?v=aqz-KE-bpKQ');tap('Analisar link')
result='timeout'
end=time.monotonic()+115
while time.monotonic()<end:
 time.sleep(2)
 try:
  xml=ET.fromstring(adb('shell','run-as',package,'cat','shared_prefs/downloads.xml'))
  status=next((n.text or '' for n in xml if n.get('name')=='status'),'')
 except (subprocess.CalledProcessError,ET.ParseError):continue
 if 'Escolha um formato para baixar' in status:result='formats-found';break
 if 'Não foi possível analisar' in status:result='provider-unavailable';break
 if subprocess.run(['adb','shell','pidof',package],stdout=subprocess.PIPE,timeout=10).returncode!=0:result='app-crashed';break
time.sleep(1)
nodes();capture('02-youtube-result')
logs=adb('logcat','-d','-s','OndaDownload:I','AndroidRuntime:E','*:S').decode(errors='replace')
(out/'download-logcat.txt').write_text(logs)
print(logs)
(out/'live-result.json').write_text(json.dumps({'video':'Blender Big Buck Bunny (CC BY)','result':result,'note':'Live provider availability is separate from native mux and UI assertions.'},indent=2))
assert result not in ('timeout','app-crashed'),'Extractor did not finish: '+result
print('Native download UI passed; live provider:',result)
