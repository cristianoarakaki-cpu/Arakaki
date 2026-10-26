"""Real local audio/video resume, mixed collections and persistent PDF page annotations."""
from pathlib import Path
import subprocess,shlex,time,re,json,xml.etree.ElementTree as ET
P='br.com.onda.musica';OUT=Path('Onda/ui-preview')
def adb(*a):return subprocess.check_output(['adb',*a],timeout=60)
def shell(*a):return adb('shell',shlex.join(str(x) for x in a))
def nodes():
 shell('uiautomator','dump','/sdcard/onda-shelf.xml');return list(ET.fromstring(shell('cat','/sdcard/onda-shelf.xml')).iter('node'))
def target(value):
 for _ in range(5):
  n=next((n for n in nodes() if value in (n.attrib.get('content-desc'),n.attrib.get('text'))),None)
  if n is not None:return n
  time.sleep(.3)
 raise AssertionError('Missing '+value)
def tap(value,hold=False):
 n=target(value);l,t,r,b=map(int,re.findall(r'\d+',n.attrib['bounds']));assert r>l and b>t;point=((l+r)//2,(t+b)//2)
 if hold:shell('input','swipe',*point,*point,1100)
 else:shell('input','tap',*point)
 time.sleep(.4)
def media(kind,name):
 path='content://media/external/'+('file' if kind=='file' else kind+'/media');raw=shell('content','query','--uri',path,'--projection','_id','--where',"_display_name='"+name+"'").decode();found=re.search(r'_id=(\d+)',raw);assert found,raw;return path+'/'+found[1]
def open_file(uri,mime,*extras):shell('am','start','-W','-a','android.intent.action.VIEW','-d',uri,'-t',mime,'-p',P,'--grant-read-uri-permission',*extras);time.sleep(.5)
def video_log():return adb('logcat','-d','-s','OndaVideo:D').decode(errors='replace')
def page(n):
 for _ in range(8):
  ns=nodes()
  if any(x.attrib.get('content-desc')=='Página atual do PDF' and x.attrib.get('text')==f'Página {n} de 3' for x in ns):return
  time.sleep(.3)
 raise AssertionError('PDF did not navigate to '+str(n))
def capture(name):(OUT/(name+'.png')).write_bytes(adb('exec-out','screencap','-p'))
def open_space():
 tap('Menu da biblioteca')
 for _ in range(10):
  ns=nodes();listing=next(n for n in ns if n.attrib.get('content-desc')=='Opções do menu');l,t,r,b=map(int,re.findall(r'\d+',listing.attrib['bounds']))
  found=next((n for n in ns if n.attrib.get('content-desc')=='Continuar e coleções'),None)
  if found is not None:
   x1,y1,x2,y2=map(int,re.findall(r'\d+',found.attrib['bounds']))
   if y2>y1 and y1>=t and y2<=b:tap('Continuar e coleções');return
  shell('input','swipe',(l+r)//2,t+int((b-t)*.85),(l+r)//2,t+int((b-t)*.2),250)
 raise AssertionError('Meu espaço menu unreachable')
def add_recent(label):tap('Adicionar no Meu espaço');tap('Escolher de Continuar');tap(label)
# Independent of the longer video UI regression: create its one required movie.
fixture=Path('/tmp/Onda-Shelf.mp4')
subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-f','lavfi','-i','color=c=blue:s=320x180:r=15','-f','lavfi','-i','sine=frequency=440:sample_rate=44100','-t','20','-c:v','libx264','-threads','2','-pix_fmt','yuv420p','-c:a','aac',str(fixture)],check=True,timeout=60)
shell('mkdir','-p','/sdcard/Movies/OndaDemo');adb('push',str(fixture),'/sdcard/Movies/OndaDemo/Onda-Video.mp4');shell('am','broadcast','-a','android.intent.action.MEDIA_SCANNER_SCAN_FILE','-d','file:///sdcard/Movies/OndaDemo/Onda-Video.mp4');time.sleep(1)
try:
 shell('am','force-stop',P)
 open_file(media('audio','Onda-Audio.mp3'),'audio/mpeg','--el','onda_start_ms','12000')
 for _ in range(30):
  if 'PlaybackState {state=3,' in shell('dumpsys','media_session').decode():break
  time.sleep(.2)
 else:raise AssertionError('Resumed audio did not play')
 shell('input','keyevent','127');time.sleep(.8)
 positions=[int(v) for v in re.findall(r'position=(\d+)',shell('dumpsys','media_session').decode())]
 assert any(11000<=p<18000 for p in positions),positions
 count=video_log().count('resumed 6000')
 open_file(media('video','Onda-Video.mp4'),'video/mp4','--el','onda_start_ms','6000')
 for _ in range(35):
  if video_log().count('resumed 6000')>count:break
  time.sleep(.3)
 else:raise AssertionError('Video did not seek to requested journal point')
 shell('input','keyevent','3');time.sleep(.5)
 pdf=media('file','Onda-Guia.pdf');open_file(pdf,'application/pdf','--ei','onda_page','1');page(2)
 tap('Menu do PDF');tap('Continuar e coleções');tap('Coleções');tap('Adicionar no Meu espaço');tap('Nome da coleção multimídia');shell('input','text','Estudo');tap('Salvar')
 add_recent('Áudio • Onda-Audio');add_recent('Vídeo • Onda-Video.mp4');add_recent('PDF • Onda-Guia.pdf')
 assert all(target('Retomar '+name) for name in ['Onda-Audio','Onda-Video.mp4','Onda-Guia.pdf'])
 capture('47-colecao-multimidia')
 tap('Retomar Onda-Guia.pdf',True);tap('Nova anotação');tap('Texto da anotação');shell('input','text','Revisar%saula');tap('Salvar')
 open_file(pdf,'application/pdf','--ei','onda_page','2');page(3)
 shell('am','force-stop',P);shell('am','start','-W','-n',P+'/br.com.onda.MainActivity');time.sleep(.5);open_space()
 tap('Coleções');tap('Abrir coleção Estudo');tap('Retomar Onda-Guia.pdf',True);tap('Ver anotações');tap('Página 2 • Revisar aula');capture('48-nota-pagina-pdf');tap('Abrir ponto');page(2)
 (OUT/'shelf-tests.json').write_text(json.dumps(dict(audioResumeMs=12000,videoResumeMs=6000,mixedCollection=['audio','video','pdf'],annotationSurvivesProcessRestart=True,annotationOverridesLastPage=True,collectionSurvivesProcessRestart=True),indent=2))
except Exception:
 (OUT/'shelf-failure.png').write_bytes(adb('exec-out','screencap','-p'));(OUT/'shelf-failure-logcat.txt').write_bytes(adb('logcat','-d'));raise
finally:shell('am','force-stop',P)
