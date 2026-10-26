"""Check speech controls, persistence and absence of autoplay on actual Android UI."""
from pathlib import Path
import subprocess,shlex,time,re,json,xml.etree.ElementTree as ET
P='br.com.onda.musica';OUT=Path('Onda/ui-preview')
def adb(*a):return subprocess.check_output(['adb',*a],timeout=60)
def shell(*a):return adb('shell',shlex.join(str(x) for x in a))
def nodes():
 shell('uiautomator','dump','/sdcard/onda-speech.xml');return list(ET.fromstring(shell('cat','/sdcard/onda-speech.xml')).iter('node'))
def tap_node(n):
 l,t,r,b=map(int,re.findall(r'\d+',n.attrib['bounds']));assert r>l and b>t;shell('input','tap',(l+r)//2,(t+b)//2);time.sleep(.4)
def find(label):
 controls={'Ativar equilíbrio de fala','Ativar redução de silêncios','Verificar na reprodução','Desligar recursos de fala'}
 for _ in range(7):
  ns=nodes();scroll=next((n for n in ns if n.attrib.get('class')=='android.widget.ScrollView'),None)
  for n in ns:
   if n.attrib.get('content-desc')!=label and n.attrib.get('text','').casefold()!=label.casefold():continue
   l,t,r,b=map(int,re.findall(r'\d+',n.attrib['bounds']))
   if r<=l or b<=t:continue
   if label in controls and scroll is not None:
    a,c,d,e=map(int,re.findall(r'\d+',scroll.attrib['bounds']))
    if t<c or b>e:continue
   return n
  if scroll is None:break
  l,t,r,b=map(int,re.findall(r'\d+',scroll.attrib['bounds']));low=t+int((b-t)*.85);high=t+int((b-t)*.2)
  if label in ('Verificar na reprodução','Desligar recursos de fala'):shell('input','swipe',(l+r)//2,low,(l+r)//2,high,250)
  else:shell('input','swipe',(l+r)//2,high,(l+r)//2,low,250)
 raise AssertionError('Control not reachable: '+label)
def tap(label):tap_node(find(label))
def open_screen():
 shell('am','start','-W','-n',P+'/br.com.onda.MainActivity');time.sleep(.5);tap('Menu da biblioteca')
 for _ in range(8):
  ns=nodes();listing=next(n for n in ns if n.attrib.get('content-desc')=='Opções do menu');l,t,r,b=map(int,re.findall(r'\d+',listing.attrib['bounds']));target=next((n for n in ns if n.attrib.get('content-desc')=='Aulas e podcasts'),None)
  if target is not None:
   a,c,d,e=map(int,re.findall(r'\d+',target.attrib['bounds']))
   if e>c and c>=t and e<=b:tap_node(target);return
  shell('input','swipe',(l+r)//2,t+int((b-t)*.85),(l+r)//2,t+int((b-t)*.2),250)
 raise AssertionError('Speech menu unreachable')
def checked(label):return find(label).attrib.get('checked')=='true'
try:
 shell('am','force-stop',P);open_screen()
 assert not checked('Ativar equilíbrio de fala');assert not checked('Ativar redução de silêncios')
 tap('Ativar equilíbrio de fala');tap('Ativar redução de silêncios');tap('Verificar na reprodução')
 assert 'PlaybackState {state=3,' not in shell('dumpsys','media_session').decode(),'Changing speech settings started playback'
 assert checked('Ativar equilíbrio de fala') and checked('Ativar redução de silêncios')
 (OUT/'49-aulas-e-podcasts.png').write_bytes(adb('exec-out','screencap','-p'))
 shell('am','force-stop',P);open_screen();assert checked('Ativar equilíbrio de fala') and checked('Ativar redução de silêncios')
 assert 'PlaybackState {state=3,' not in shell('dumpsys','media_session').decode(),'Restoring speech settings started playback'
 tap('Desligar recursos de fala');assert not checked('Ativar equilíbrio de fala') and not checked('Ativar redução de silêncios')
 (OUT/'speech-ui-tests.json').write_text(json.dumps(dict(defaultsOff=True,noAutoplay=True,settingsSurviveProcessRestart=True,explicitReset=True),indent=2))
except Exception:
 (OUT/'speech-ui-failure.png').write_bytes(adb('exec-out','screencap','-p'));raise
finally:shell('am','force-stop',P)
