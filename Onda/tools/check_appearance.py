"""Choose all skins through the real UI and revisit music/video without restarting them."""
from pathlib import Path
import subprocess,shlex,time,re,json,xml.etree.ElementTree as ET
P='br.com.onda.musica';OUT=Path('Onda/ui-preview');OUT.mkdir(exist_ok=True,parents=True)
def adb(*a):return subprocess.check_output(['adb',*a],timeout=60)
def shell(*a):return adb('shell',shlex.join(str(x) for x in a))
def nodes():
 for _ in range(4):
  try:shell('uiautomator','dump','/sdcard/onda-appearance.xml');return list(ET.fromstring(shell('cat','/sdcard/onda-appearance.xml')).iter('node'))
  except (subprocess.CalledProcessError,ET.ParseError):time.sleep(.3)
 raise AssertionError('No appearance accessibility tree')
def bounds(n):return list(map(int,re.findall(r'\d+',n.attrib['bounds'])))
def tap(label,desc=False):
 for _ in range(18):
  ns=nodes();node=next((n for n in ns if n.attrib.get('content-desc' if desc else 'text')==label),None)
  scroll=next((n for n in ns if n.attrib.get('content-desc') in ('Lista de aparências','Opções do menu')),None)
  if node is not None:
   l,t,r,b=bounds(node);inside=True
   if scroll is not None:
    sl,st,sr,sb=bounds(scroll);inside=t>=st and b<=sb and b-t>=40
   if inside and r>l and b>t:
    assert node.attrib.get('enabled')!='false',label;shell('input','tap',(l+r)//2,(t+b)//2);time.sleep(.4);return
  if scroll is not None:
   l,t,r,b=bounds(scroll);shell('input','swipe',(l+r)//2,t+(b-t)*8//10,(l+r)//2,t+(b-t)//10,220)
  time.sleep(.2)
 raise AssertionError('Appearance control not reachable: '+label)
def capture(name):(OUT/(name+'.png')).write_bytes(adb('exec-out','screencap','-p'))
def launch():shell('am','start','-W','-n',P+'/br.com.onda.MainActivity');time.sleep(.5)
old_font=shell('settings','get','system','font_scale').decode().strip();old=None
try:
 shell('am','force-stop',P)
 try:old=shell('run-as',P,'cat','shared_prefs/appearance.xml')
 except subprocess.CalledProcessError:pass
 results=[]
 for index,(theme,name) in enumerate([('nebula','Nebulosa'),('circuit','Circuito'),('solar','Cyber Solar'),('graphite','Grafite'),('original','Onda Original')]):
  launch();tap('Menu da biblioteca',True);tap('Aparências');tap('Usar aparência '+name,True)
  assert any(n.attrib.get('text')=='Aparência atual: '+name for n in nodes())
  prefs=ET.fromstring(shell('run-as',P,'cat','shared_prefs/appearance.xml'));assert any(n.attrib.get('name')=='theme' and n.text==theme for n in prefs)
  capture('80-aparencia-'+theme+'-lista');shell('input','keyevent','4');time.sleep(.4)
  assert any(n.attrib.get('text')=='Minhas músicas' for n in nodes());capture('81-aparencia-'+theme+'-biblioteca')
  tap('Abrir biblioteca de vídeos',True);assert any(n.attrib.get('text')=='Onda Vídeos' for n in nodes());tap('Abrir biblioteca de músicas',True)
  results.append(dict(theme=theme,selectionSaved=True,returnsToLibrary=True,videoNavigation=True))
 shell('settings','put','system','font_scale','1.4');time.sleep(.8);launch();tap('Menu da biblioteca',True);tap('Aparências');tap('Usar aparência Cyber Solar',True);capture('82-aparencias-fonte-grande')
 assert any(n.attrib.get('text')=='Aparência atual: Cyber Solar' for n in nodes())
 (OUT/'appearance-ui-tests.json').write_text(json.dumps(dict(themes=results,largeFontReachable=True,fontScale=1.4),indent=2,ensure_ascii=False))
except Exception:
 capture('appearance-failure');(OUT/'appearance-logcat.txt').write_bytes(adb('logcat','-d'));raise
finally:
 shell('am','force-stop',P);shell('settings','put','system','font_scale',old_font if old_font not in ('','null') else '1.0')
 if old is None:shell('run-as',P,'rm','-f','shared_prefs/appearance.xml')
 else:
  path=Path('/tmp/onda-old-appearance.xml');path.write_bytes(old);adb('push',str(path),'/data/local/tmp/onda-old-appearance.xml');shell('run-as',P,'cp','/data/local/tmp/onda-old-appearance.xml','shared_prefs/appearance.xml')
