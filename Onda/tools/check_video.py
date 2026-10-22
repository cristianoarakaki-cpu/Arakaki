"""Real Android decoding checks with generated, redistributable video fixtures."""
from pathlib import Path
import subprocess,shlex,time,re,json,xml.etree.ElementTree as ET
PACKAGE='br.com.onda.musica'
OUTPUT=Path('Onda/ui-preview');OUTPUT.mkdir(exist_ok=True)
def adb(*a):return subprocess.check_output(['adb',*a],timeout=60)
def shell(*a):return adb('shell',shlex.join(str(v) for v in a))
def nodes():
    shell('rm','-f','/sdcard/onda-video.xml');shell('uiautomator','dump','/sdcard/onda-video.xml')
    return list(ET.fromstring(shell('cat','/sdcard/onda-video.xml')).iter('node'))
def point(node):
    v=[int(x) for x in re.findall(r'\d+',node.attrib['bounds'])];return ((v[0]+v[2])//2,(v[1]+v[3])//2)
def locate(desc):return next(n for n in nodes() if n.attrib.get('content-desc')==desc)
def tap(desc):shell('input','tap',*point(locate(desc)));time.sleep(.5)
def capture(name):
    (OUTPUT/(name+'.png')).write_bytes(adb('exec-out','screencap','-p'))
    (OUTPUT/(name+'.xml')).write_bytes(shell('cat','/sdcard/onda-video.xml'))
formats=[('mp4','libx264','aac','video/mp4'),('mkv','libx264','aac','video/x-matroska'),('avi','mpeg4','libmp3lame','video/avi'),('webm','libvpx','libvorbis','video/webm'),('flv','flv','libmp3lame','video/x-flv'),('wmv','wmv2','wmav2','video/x-ms-wmv'),('mov','libx264','aac','video/quicktime'),('ts','libx264','aac','video/mp2ts')]
shell('mkdir','-p','/sdcard/Movies/OndaDemo')
for extension,vcodec,acodec,mime in formats:
    filename='Onda-Video.'+extension;local=Path('/tmp')/filename
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-f','lavfi','-i','testsrc2=size=320x180:rate=15','-f','lavfi','-i','sine=frequency=440:sample_rate=44100','-t','20','-c:v',vcodec,'-threads','2','-b:v','250k','-c:a',acodec,'-b:a','64k',str(local)],check=True,timeout=90)
    remote='/sdcard/Movies/OndaDemo/'+filename;adb('push',str(local),remote)
    shell('am','broadcast','-a','android.intent.action.MEDIA_SCANNER_SCAN_FILE','-d','file://'+remote)
    time.sleep(.3)
    # Indexing support varies; explicitly register fixtures so every codec is exercised.
    indexed=shell('content','query','--uri','content://media/external/video/media','--projection','_id','--where',"_display_name='"+filename+"'").decode()
    if 'No result found' in indexed:
        shell('content','insert','--uri','content://media/external/video/media','--bind','_data:s:'+remote,'--bind','_display_name:s:'+filename,'--bind','title:s:'+filename,'--bind','mime_type:s:'+mime,'--bind','duration:l:20000','--bind','_size:l:'+str(local.stat().st_size))
# Return from updates to the main library left by capture_ui.py.
shell('input','keyevent','4');time.sleep(.5)
entry=point(locate('Abrir biblioteca de vídeos'))
shell('am','start','-W','-n',PACKAGE+'/br.com.onda.MainActivity','--activity-single-top','--es','voice_phrase','toque Onda Sessions');time.sleep(1)
assert 'PlaybackState {state=3,' in shell('dumpsys','media_session').decode(),'Music fixture not playing before video'
shell('input','tap',*entry);time.sleep(2)
assert locate('Buscar vídeos por nome') is not None
pause_point=point(locate('Reproduzir vídeo'))
capture('11-biblioteca-videos')
results=[]
try:
 for extension,vcodec,acodec,mime in formats:
    filename='Onda-Video.'+extension
    tap('Buscar vídeos por nome');shell('input','keyevent','123')
    field=locate('Buscar vídeos por nome')
    previous=field.attrib.get('text','')
    if previous and previous!='Buscar vídeo no celular':
        for _ in previous:shell('input','keyevent','67')
    shell('input','text',extension);shell('input','keyevent','4');time.sleep(.5)
    row=locate('Assistir '+filename);adb('logcat','-c');shell('input','tap',*point(row))
    played=False
    for _ in range(20):
        log=adb('logcat','-d','-s','OndaVideo:D').decode(errors='replace')
        if 'playing '+filename in log and 'frames '+filename in log and 'audio '+filename in log:played=True;break
        time.sleep(.5)
    assert played,'No decoded frames for '+filename+'\n'+adb('logcat','-d','-t','100').decode(errors='replace')
    assert 'PlaybackState {state=3,' not in shell('dumpsys','media_session').decode(),'Music overlaps video'
    time.sleep(1);capture('12-video-'+extension)
    shell('input','tap',*pause_point);time.sleep(.5)
    assert locate('Reproduzir vídeo') is not None,'Video did not pause'
    results.append({'format':extension,'videoCodec':vcodec,'audioCodec':acodec,'decodedFrames':True,'audioTrackSelected':True})
 tap('Tela cheia do vídeo');time.sleep(1)
 assert locate('Sair da tela cheia') is not None
 capture('13-video-tela-cheia')
 tap('Reproduzir vídeo');time.sleep(1)
 adb('logcat','-c');shell('input','keyevent','3');time.sleep(1)
 assert 'paused' in adb('logcat','-d','-s','OndaVideo:D').decode(),'Video did not pause when app hidden'
 shell('am','start','-W','-n',PACKAGE+'/br.com.onda.MainActivity');time.sleep(1)
 print('Android video: 8 containers decoded, audio exclusive, search, pause, fullscreen and background pause passed.')
finally:
 (OUTPUT/'video-tests.json').write_text(json.dumps(results,indent=2)+'\n')
 (OUTPUT/'video-logcat.txt').write_bytes(adb('logcat','-d','-v','threadtime'))
 (OUTPUT/'video-last-screen.png').write_bytes(adb('exec-out','screencap','-p'))
