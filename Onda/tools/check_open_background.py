"""Exercise typed external opens and real background video audio on Android."""
from pathlib import Path
import subprocess,shlex,time,re,json,xml.etree.ElementTree as ET
P='br.com.onda.musica';OUT=Path('Onda/ui-preview')
def adb(*a):return subprocess.check_output(['adb',*a],timeout=60)
def shell(*a):return adb('shell',shlex.join(str(x) for x in a))
def nodes():
 shell('uiautomator','dump','/sdcard/onda-open.xml');return list(ET.fromstring(shell('cat','/sdcard/onda-open.xml')).iter('node'))
def tap_node(n):
 l,t,r,b=map(int,re.findall(r'\d+',n.attrib['bounds']));assert r>l and b>t;shell('input','tap',(l+r)//2,(t+b)//2);time.sleep(.4)
def tap(desc):tap_node(next(n for n in nodes() if n.attrib.get('content-desc')==desc))
def text(label):tap_node(next(n for n in nodes() if n.attrib.get('text')==label))
def logs(tag):return adb('logcat','-d','-s',tag+':D').decode(errors='replace')
def open_file(uri,mime):
 # No explicit component: Android resolves the registered ACTION_VIEW filter.
 shell('am','start','-W','-a','android.intent.action.VIEW','-d',uri,'-t',mime,'-p',P,'--grant-read-uri-permission');time.sleep(.7)
def media(kind,name):
 output=shell('content','query','--uri','content://media/external/'+kind+'/media','--projection','_id','--where',"_display_name='"+name+"'").decode();found=re.search(r'_id=(\d+)',output);assert found,output;return 'content://media/external/'+kind+'/media/'+found[1]
def positions():return [int(x) for x in re.findall(r'position (\d+) playing true',logs('OndaVideoBg'))]
def wait_position(after):
 for _ in range(25):
  points=positions()
  if points and points[-1]>after:return points[-1]
  time.sleep(.25)
 raise AssertionError('Background position did not advance: '+logs('OndaVideoBg'))
# A longer fixture avoids depending on how fast UIAutomator opens the menu.
fixture=Path('/tmp/Onda-Background.mp4')
subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-f','lavfi','-i','color=c=blue:s=320x180:r=15','-f','lavfi','-i','sine=frequency=440:sample_rate=44100','-t','90','-c:v','libx264','-threads','2','-pix_fmt','yuv420p','-c:a','aac',str(fixture)],check=True,timeout=90)
shell('mkdir','-p','/sdcard/Movies/OndaDemo','/sdcard/Music/OndaDemo')
audio=Path('/tmp/Onda-Audio.mp3')
subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(fixture),'-vn','-c:a','libmp3lame','-b:a','64k','-metadata','title=Onda-Audio','-metadata','artist=Onda Sessions',str(audio)],check=True,timeout=90)
adb('push',str(audio),'/sdcard/Music/OndaDemo/Onda-Audio.mp3');shell('am','broadcast','-a','android.intent.action.MEDIA_SCANNER_SCAN_FILE','-d','file:///sdcard/Music/OndaDemo/Onda-Audio.mp3')
adb('push',str(fixture),'/sdcard/Movies/OndaDemo/Onda-Background.mp4');shell('am','broadcast','-a','android.intent.action.MEDIA_SCANNER_SCAN_FILE','-d','file:///sdcard/Movies/OndaDemo/Onda-Background.mp4');time.sleep(1)
try:
 shell('am','force-stop',P);adb('logcat','-c')
 open_file(media('audio','Onda-Audio.mp3'),'audio/mpeg')
 for _ in range(30):
  if 'PlaybackState {state=3,' in shell('dumpsys','media_session').decode():break
  time.sleep(.2)
 else:raise AssertionError('External MP3 did not play')
 # Check actual playback first, then pause before dumping the one-second UI timer.
 shell('input','keyevent','127');time.sleep(1);ns=nodes()
 assert any(n.attrib.get('text')=='Onda-Audio' for n in ns),'External audio title missing'
 assert any(n.attrib.get('text')=='Onda Sessions' for n in ns),'External audio metadata missing'
 # A PDF delivered by another app opens directly in the Onda reader.
 pdf_query=shell('content','query','--uri','content://media/external/file','--projection','_id','--where',"_display_name='Onda-Guia.pdf'").decode();pdf_id=re.search(r'_id=(\d+)',pdf_query);assert pdf_id,pdf_query
 pdf='content://media/external/file/'+pdf_id[1]
 open_file(pdf,'application/pdf')
 for _ in range(15):
  ns=nodes()
  if any(n.attrib.get('content-desc')=='Página atual do PDF' and 'de 3' in n.attrib.get('text','') for n in ns):break
  time.sleep(.3)
 else:raise AssertionError('External PDF did not render')
 shell('am','start','-W','-n',P+'/br.com.onda.VideoActivity');time.sleep(.7)
 tap('Menu de vídeos');text('Reprodução em segundo plano');text('Continuar áudio')
 open_file(media('video','Onda-Background.mp4'),'video/mp4')
 for _ in range(30):
  if 'frames Onda-Background.mp4' in logs('OndaVideo'):break
  time.sleep(.3)
 else:raise AssertionError('External video did not render')
 shell('input','keyevent','3');first=wait_position(0);later=wait_position(first+2000)
 assert 'Onda vídeo' in shell('dumpsys','media_session').decode(),'Background media controls absent'
 shell('input','keyevent','127');time.sleep(.7);assert 'paused' in logs('OndaVideoBg')
 # While paused there must be no advancing native playback events.
 paused_positions=positions();time.sleep(2);assert positions()==paused_positions,'Background audio kept advancing after media pause'
 shell('input','keyevent','126');resumed=wait_position(later)
 shell('input','keyevent','223');locked=wait_position(resumed+1500)
 shell('input','keyevent','224');shell('wm','dismiss-keyguard')
 # Return to the existing video screen; restore at the service playback position.
 shell('am','start','-W','-n',P+'/br.com.onda.VideoActivity','-a','br.com.onda.RETURN_VIDEO','--activity-single-top');time.sleep(.7)
 for _ in range(25):
  restored=re.findall(r'resumed (\d+)',logs('OndaVideo'))
  if restored and int(restored[-1])>=locked-1000:break
  time.sleep(.3)
 else:raise AssertionError('Foreground video did not resume background position: '+logs('OndaVideo'))
 (OUT/'46-video-background.png').write_bytes(adb('exec-out','screencap','-p'))
 assert 'br.com.onda.VideoBackgroundService' not in shell('dumpsys','activity','services',P).decode(),'Audio continuation service was not removed on return'
 # Starting music stops a background video instead of overlapping both sources.
 before_home=max(positions(),default=0);shell('input','keyevent','3');wait_position(before_home+500);open_file(media('audio','Onda-Audio.mp3'),'audio/mpeg');time.sleep(1)
 assert 'br.com.onda.VideoBackgroundService' not in shell('dumpsys','activity','services',P).decode(),'Music did not stop background video'
 assert 'PlaybackState {state=3,' in shell('dumpsys','media_session').decode(),'External music did not resume'
 (OUT/'open-background-tests.json').write_text(json.dumps(dict(externalAudio=True,externalVideo=True,externalPdf=True,backgroundClock=True,mediaPauseAndResume=True,screenOff=True,restorePosition=True,noMusicOverlap=True),indent=2))
except Exception:
 (OUT/'open-background-logcat.txt').write_bytes(adb('logcat','-d'));(OUT/'open-background-failure.png').write_bytes(adb('exec-out','screencap','-p'));raise
finally:
 shell('input','keyevent','224');shell('wm','dismiss-keyguard');shell('am','force-stop',P)
