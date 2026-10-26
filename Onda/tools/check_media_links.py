"""Actual Downloads UI: public direct file formats and the user's TikTok short URL."""
from pathlib import Path
import subprocess,shlex,time,re,json,xml.etree.ElementTree as ET
P='br.com.onda.musica';OUT=Path('Onda/ui-preview');OUT.mkdir(exist_ok=True,parents=True)
def adb(*a):return subprocess.check_output(['adb',*a],timeout=60)
def shell(*a):return adb('shell',shlex.join(str(x) for x in a))
def nodes():
 for _ in range(4):
  try:
   shell('rm','-f','/sdcard/onda-media-links.xml');shell('uiautomator','dump','/sdcard/onda-media-links.xml');return list(ET.fromstring(shell('cat','/sdcard/onda-media-links.xml')).iter('node'))
  except (subprocess.CalledProcessError,ET.ParseError):time.sleep(.3)
 raise AssertionError('Accessibility tree unavailable')
def tap(text):
 for _ in range(6):
  n=next((n for n in nodes() if n.attrib.get('text','').casefold()==text.casefold()),None)
  if n is not None:
   l,t,r,b=map(int,re.findall(r'\d+',n.attrib['bounds']));assert r>l and b>t;shell('input','tap',(l+r)//2,(t+b)//2);time.sleep(.3);return
  time.sleep(.2)
 raise AssertionError('Missing '+text)
def share(url):
 shell('am','start','-W','-n',P+'/br.com.onda.DownloadsActivity','-a','android.intent.action.SEND','-t','text/plain','--es','android.intent.extra.TEXT',url);time.sleep(.3);tap('Analisar link')
def result():
 until=time.monotonic()+95
 while time.monotonic()<until:
  time.sleep(.5)
  try:
   xml=ET.fromstring(shell('run-as',P,'cat','shared_prefs/downloads.xml'));status=next((n.text or '' for n in xml if n.attrib.get('name')=='status'),'')
  except (subprocess.CalledProcessError,ET.ParseError):continue
  if 'Escolha um formato para baixar' in status:return 'formats-found',status
  if 'Não foi possível analisar' in status:return 'provider-unavailable',status
  if 'Cole um link HTTPS' in status:raise AssertionError('Valid link rejected: '+status)
 raise AssertionError('Link analysis did not finish')
def capture(name):(OUT/(name+'.png')).write_bytes(adb('exec-out','screencap','-p'))
try:
 shell('am','force-stop',P)
 share('https://raw.githubusercontent.com/cristianoarakaki-cpu/Arakaki/245b693e64cf5b5b33bc2a5f491a607f6a435655/Onda/tests/fixtures/download.mp4')
 direct,status=result();assert direct=='formats-found',status
 ns=nodes();assert any(n.attrib.get('text')=='MP4 • arquivo original' for n in ns);assert any('MP3 • extrair áudio' in n.attrib.get('text','') for n in ns);capture('70-download-direto')
 share('Veja este vídeo https://vt.tiktok.com/ZSg42qGJc/ no TikTok')
 tiktok,status=result();assert tiktok=='formats-found' or 'TikTok' in status,status
 capture('71-tiktok-link-curto')
 (OUT/'media-links-tests.json').write_text(json.dumps(dict(directFile=direct,originalMp4Option=True,mp3ExtractionOption=True,tiktokShortUrlAccepted=True,shareCaption=True,tiktok=tiktok,tiktokStatus=status),indent=2,ensure_ascii=False))
 print('Media link UI: direct='+direct+', TikTok='+tiktok)
except Exception:
 (OUT/'media-links-failure.png').write_bytes(adb('exec-out','screencap','-p'));(OUT/'media-links-failure-logcat.txt').write_bytes(adb('logcat','-d'));raise
finally:shell('am','force-stop',P)
