"""Real public HTML page -> declared media -> visible audio/video choices, no provider login."""
from pathlib import Path
import os,subprocess,shlex,time,re,json,xml.etree.ElementTree as ET
P='br.com.onda.musica';OUT=Path('Onda/ui-preview');OUT.mkdir(parents=True,exist_ok=True)
def adb(*args):return subprocess.check_output(['adb',*args],timeout=60)
def shell(*args):return adb('shell',shlex.join(str(x) for x in args))
def nodes():
 shell('uiautomator','dump','/sdcard/onda-public-page.xml');return list(ET.fromstring(shell('cat','/sdcard/onda-public-page.xml')).iter('node'))
def tap(n):
 l,t,r,b=map(int,re.findall(r'\d+',n.attrib['bounds']));assert r>l and b>t;shell('input','tap',(l+r)//2,(t+b)//2)
try:
 shell('am','force-stop',P)
 url='https://raw.githubusercontent.com/cristianoarakaki-cpu/Arakaki/'+os.environ['GITHUB_SHA']+'/Onda/tests/fixtures/public-media.html'
 shell('am','start','-W','-n',P+'/br.com.onda.DownloadsActivity','-a','android.intent.action.SEND','-t','text/plain','--es','android.intent.extra.TEXT',url)
 tap(next(n for n in nodes() if n.attrib.get('text')=='Analisar link'))
 deadline=time.monotonic()+95
 while time.monotonic()<deadline:
  time.sleep(.5);prefs=ET.fromstring(shell('run-as',P,'cat','shared_prefs/downloads.xml'));status=next((n.text or '' for n in prefs if n.attrib.get('name')=='status'),'')
  if 'Escolha um formato' in status:break
  assert 'Não foi possível analisar' not in status,status
 else:raise AssertionError('Public page analysis timed out')
 seen=set()
 for _ in range(7):
  ns=nodes()
  for n in ns:
   text=n.attrib.get('text','')
   for kind in ['MP4','MP3','M4A','AAC']:
    if text.startswith('Fonte 1 • '+kind):seen.add(kind)
  if len(seen)==4:break
  scroll=next(n for n in ns if n.attrib.get('class')=='android.widget.ScrollView');l,t,r,b=map(int,re.findall(r'\d+',scroll.attrib['bounds']));shell('input','swipe',(l+r)//2,t+(b-t)*7//10,(l+r)//2,t+(b-t)*3//10,350)
 assert seen=={'MP4','MP3','M4A','AAC'},seen
 assert any(n.attrib.get('content-desc')=='Aba YouTube nos downloads' for n in nodes())
 (OUT/'86-public-media-page.png').write_bytes(adb('exec-out','screencap','-p'))
 (OUT/'public-downloads-tests.json').write_text(json.dumps({'publicHtmlPage':True,'actualMediaPrefixVerified':True,'formats':sorted(seen),'youtubeTabVisible':True},indent=2)+'\n')
 print('Página pública analisada, fonte real conferida e quatro formatos oferecidos.')
except Exception:
 (OUT/'public-downloads-failure.png').write_bytes(adb('exec-out','screencap','-p'));(OUT/'public-downloads-failure-logcat.txt').write_bytes(adb('logcat','-d'));raise
finally:shell('am','force-stop',P)
