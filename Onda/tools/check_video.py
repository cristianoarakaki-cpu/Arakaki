"""Real Android decoding checks with generated, redistributable video fixtures."""
from pathlib import Path
import subprocess,shlex,time,re,json,math,struct,wave,xml.etree.ElementTree as ET
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
def tap_text(text):
    node=next(n for n in nodes() if n.attrib.get('text','').casefold()==text.casefold())
    shell('input','tap',*point(node));time.sleep(.5)
def menu_action(description,label):
    tap(description);tap_text(label)
def capture(name):
    (OUTPUT/(name+'.png')).write_bytes(adb('exec-out','screencap','-p'))
    (OUTPUT/(name+'.xml')).write_bytes(shell('cat','/sdcard/onda-video.xml'))
formats=[('mp4','libx264','aac','video/mp4'),('mkv','libx264','aac','video/x-matroska'),('avi','mpeg4','libmp3lame','video/avi'),('webm','libvpx','libvorbis','video/webm'),('flv','flv','libmp3lame','video/x-flv'),('wmv','wmv2','wmav2','video/x-ms-wmv'),('mov','libx264','aac','video/quicktime'),('ts','libx264','aac','video/mp2ts')]
adb('install','-r','Onda/app/build/outputs/apk/debug/app-debug.apk')
shell('pm','grant',PACKAGE,'android.permission.READ_EXTERNAL_STORAGE')
shell('mkdir','-p','/sdcard/Music/OndaDemo')
audio=Path('/tmp/Onda-Audio.wav')
with wave.open(str(audio),'wb') as wav:
 wav.setnchannels(1);wav.setsampwidth(2);wav.setframerate(8000)
 second=b''.join(struct.pack('<h',int(1000*math.sin(2*math.pi*220*i/8000))) for i in range(8000))
 for _ in range(60):wav.writeframesraw(second)
adb('push',str(audio),'/sdcard/Music/OndaDemo/Onda-Audio.wav')
shell('am','broadcast','-a','android.intent.action.MEDIA_SCANNER_SCAN_FILE','-d','file:///sdcard/Music/OndaDemo/Onda-Audio.wav')
time.sleep(1)
shell('content','update','--uri','content://media/external/audio/media','--bind','artist:s:Onda Sessions','--where',"_display_name='Onda-Audio.wav'")
# A small diverse local library for real DJ queue checks.
for index in range(2,5):
 name=f'DJ-{index}.wav';remote='/sdcard/Music/OndaDemo/'+name
 adb('push',str(audio),remote)
 shell('am','broadcast','-a','android.intent.action.MEDIA_SCANNER_SCAN_FILE','-d','file://'+remote);time.sleep(.4)
 shell('content','update','--uri','content://media/external/audio/media','--bind',f'artist:s:DJ Artist {index}','--where',f"_display_name='{name}'")
shell('mkdir','-p','/sdcard/Movies/OndaDemo')
for extension,vcodec,acodec,mime in formats:
    filename='Onda-Video.'+extension;local=Path('/tmp')/filename
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-f','lavfi','-i','testsrc2=size=320x180:rate=15','-f','lavfi','-i','sine=frequency=440:sample_rate=44100','-t','20','-c:v',vcodec,'-threads','2','-b:v','250k','-c:a',acodec,'-b:a','64k',str(local)],check=True,timeout=90)
    remote='/sdcard/Movies/OndaDemo/'+filename;adb('push',str(local),remote)
    shell('am','broadcast','-a','android.intent.action.MEDIA_SCANNER_SCAN_FILE','-d','file://'+remote)
    time.sleep(.3)
subtitle=Path('/tmp/Onda-Captions.srt');subtitle.write_text('1\n00:00:00,000 --> 00:00:19,000\nONDA LEGENDAS\n',encoding='utf-8')
shell('mkdir','-p','/sdcard/Download/OndaSubtitles');adb('push',str(subtitle),'/sdcard/Download/OndaSubtitles/Onda-Captions.srt')
# Independent integration test: no dependency on the music UI capture script.
shell('am','start','-W','-n',PACKAGE+'/br.com.onda.MainActivity');time.sleep(2)
# Verify the simplified navigation and relocated actions on the actual Android UI.
nodes();capture('01-musicas-interface')
tap('Buscar música, artista ou álbum no celular');shell('input','text','Onda');time.sleep(.5)
assert any(n.attrib.get('content-desc','').startswith('Tocar ') for n in nodes()),'Music results hidden by keyboard'
capture('01b-busca-musicas')
shell('input','keyevent','4');time.sleep(.5)
tap('Filtrar busca no celular');tap_text('Artista')
assert locate('Filtrar busca no celular').attrib.get('text')=='Artista'
tap('Filtrar busca no celular');tap_text('Todos os campos')
tap('Menu da biblioteca');capture('02-menu-biblioteca');tap_text('Coleções inteligentes')
assert any(n.attrib.get('text')=='Onda Lab' for n in nodes())
shell('input','keyevent','4');time.sleep(.5)
menu_action('Menu da biblioteca','Atualizações');capture('03-atualizacoes-menu')
shell('input','keyevent','4');time.sleep(.5)
menu_action('Menu da biblioteca','Temporizador')
assert any(n.attrib.get('text')=='30 minutos' for n in nodes())
shell('input','keyevent','4');time.sleep(.5)
menu_action('Menu da biblioteca','Recarregar biblioteca')
tap('Buscar e ouvir online');capture('04-explorar-interface')
assert not any(n.attrib.get('content-desc')=='Fonte da busca online' for n in nodes()),'Online filters should start collapsed'
menu_action('Menu de explorar','Fontes e filtros')
assert locate('Fonte da busca online') is not None
capture('05-filtros-online')
menu_action('Menu de explorar','Fontes e filtros')
tap('Abrir biblioteca de músicas')
# Exercise recognized phrases through the same handler used by the microphone.
def voice(phrase):
 shell('am','start','-W','-n',PACKAGE+'/br.com.onda.MainActivity','--activity-single-top','--es','voice_phrase',phrase);time.sleep(.7)
voice('toque Onda Sessions');voice('pause')
assert 'PlaybackState {state=3,' not in shell('dumpsys','media_session').decode()
# Validate real session effects, readback, persistence and pause/release behavior.
def sound_state():
 log=adb('logcat','-d','-s','OndaSound:D').decode(errors='replace')
 values=re.findall(r'OndaSound.*?(\{[^\n]+\})',log)
 assert values,'No sound engine status received'
 return json.loads(values[-1])
menu_action('Menu da biblioteca','Estúdio de som')
tap('Ativar ajustes de som');tap('Escolher preset de som');tap_text('Rock');time.sleep(.5)
assert locate('Escolher preset de som').attrib.get('text')=='Preset: Rock'
sound=sound_state();assert sound['enabled'] is True
if sound['equalizer']:
 assert len(sound['levels'])==len(sound['frequencies'])>0
 def expected_level(hz):
  frequencies=[60,230,910,3600,14000];gains=[4,2,-1,2,4]
  if hz<=60:return 400
  for i in range(1,5):
   if hz<=frequencies[i]:return round(100*(gains[i-1]+math.log(hz/frequencies[i-1])/math.log(frequencies[i]/frequencies[i-1])*(gains[i]-gains[i-1])))
  return 400
 for frequency,level in zip(sound['frequencies'],sound['levels']):assert abs(level-expected_level(frequency))<=2,'Equalizer readback differs from preset'
 assert sound['eq_enabled'] is False,'Paused equalizer still processing'
assert 0<sound['headroom']<=1
capture('10-estudio-som')
tap('Voltar');voice('toque Onda Sessions');time.sleep(.5)
for _ in range(20):
 playing_sound=sound_state()
 if playing_sound['playing'] is True:break
 time.sleep(.25)
else:raise AssertionError('Sound engine did not enter playback: '+json.dumps(playing_sound))
if playing_sound['equalizer']:assert playing_sound['eq_enabled'] is True
voice('pause');paused_sound=sound_state()
if paused_sound['equalizer']:assert paused_sound['eq_enabled'] is False
menu_action('Menu da biblioteca','Estúdio de som')
assert locate('Escolher preset de som').attrib.get('text')=='Preset: Rock','Sound preset was not persisted'
for _ in range(2):shell('input','swipe',540,1500,540,500,250)
tap_text('Restaurar som original');time.sleep(.5)
assert sound_state()['enabled'] is False
(OUTPUT/'sound-tests.json').write_text(json.dumps({'configured':sound,'playing':playing_sound,'paused':paused_sound,'reset':sound_state()},indent=2)+'\n')
tap('Voltar')
voice('adicione essa música aos favoritos')
assert locate('Remover dos favoritos') is not None
# The preview is local and finite; playing must publish the exact generated queue.
menu_action('Menu da biblioteca','DJ automático')
assert locate('Modo do DJ') is not None
preview=nodes();dj_rows=[n for n in preview if n.attrib.get('content-desc','').startswith('Ouvir seleção a partir de ')]
assert len(dj_rows)==4,'DJ did not include the local library'
tap('Modo do DJ');tap_text('Só favoritas');time.sleep(.3)
favorites_preview=[n for n in nodes() if n.attrib.get('content-desc','').startswith('Ouvir seleção a partir de ')]
assert len(favorites_preview)==1,'Favorites-only DJ included other songs'
tap('Modo do DJ');tap_text('Redescobrir');time.sleep(.3)
assert len([n for n in nodes() if n.attrib.get('content-desc','').startswith('Ouvir seleção a partir de ')])==4
tap('Modo do DJ');tap_text('Para você');tap('Gerar nova mistura do DJ')
preview=nodes();dj_titles=[n.attrib.get('content-desc','') for n in preview if n.attrib.get('content-desc','').startswith('Ouvir seleção a partir de ')]
assert len(dj_titles)==len(set(dj_titles))==4
capture('14-dj-automatico')
tap('Tocar seleção do DJ');time.sleep(.8)
dj_session=shell('dumpsys','media_session').decode()
assert 'PlaybackState {state=3,' in dj_session,'DJ queue did not start playing'
assert re.search(r'queue[^\n]*size=4',dj_session,re.I),'DJ did not publish four queue entries: '+dj_session
voice('pause')
(OUTPUT/'dj-tests.json').write_text(json.dumps({'queueEntries':4,'favoriteEntries':1,'preview':dj_titles,'played':True},indent=2)+'\n')

voice('Onda, toque minhas músicas favoritas, por favor')
assert 'PlaybackState {state=3,' in shell('dumpsys','media_session').decode(),'Favorites command did not play'
voice('pause')
# Create, persist, execute, edit and delete a phrase through the actual native UI.
menu_action('Menu da biblioteca','Minhas frases')
tap('Adicionar frase de voz');tap('Frase personalizada');shell('input','text','hora%sde%srelaxar');shell('input','keyevent','4');time.sleep(.3)
tap_text('Salvar');assert locate('Editar frase: hora de relaxar') is not None
capture('09-minhas-frases')
shell('input','keyevent','4');time.sleep(.3)
voice('hora de relaxar')
assert 'PlaybackState {state=3,' in shell('dumpsys','media_session').decode(),'Custom favorites phrase did not play'
voice('pause')
menu_action('Menu da biblioteca','Minhas frases');tap('Editar frase: hora de relaxar');tap('Frase personalizada');shell('input','keyevent','123')
for _ in 'hora de relaxar':shell('input','keyevent','67')
shell('input','text','meu%smomento');shell('input','keyevent','4');time.sleep(.3)
tap('Ação da frase');tap_text('Pausar');tap_text('Salvar')
assert locate('Editar frase: meu momento') is not None
shell('input','keyevent','4');time.sleep(.3)
voice('toque Onda Sessions');voice('meu momento')
assert 'PlaybackState {state=3,' not in shell('dumpsys','media_session').decode(),'Edited phrase did not pause'
menu_action('Menu da biblioteca','Minhas frases');tap('Editar frase: meu momento');tap_text('Excluir')
assert any(n.attrib.get('text')=='Excluir frase?' for n in nodes());tap_text('Excluir')
assert not any(n.attrib.get('content-desc','').startswith('Editar frase:') for n in nodes()),'Deleted phrase remained'
shell('input','keyevent','4');time.sleep(.3)
voice('coloca aquelas musicas que eu mais gosto')
assert 'PlaybackState {state=3,' in shell('dumpsys','media_session').decode(),'Local intent classifier did not play favorites'
voice('pause');voice('remova dos favoritos')
assert locate('Adicionar aos favoritos') is not None
voice('toque as favoritas')
assert 'PlaybackState {state=3,' not in shell('dumpsys','media_session').decode(),'Empty favorites unexpectedly started playback'
menu_action('Menu da biblioteca','DJ automático');tap('Modo do DJ');tap_text('Só favoritas');time.sleep(.3)
assert locate('Tocar seleção do DJ').attrib.get('enabled')=='false','Empty favorites DJ must not play'
assert any('Nenhuma favorita disponível' in n.attrib.get('text','') for n in nodes())
tap('Voltar')

voice('ajuda');assert any(n.attrib.get('text')=='Comandos de voz' for n in nodes());capture('07-comandos-voz')
tap_text('Entendi')
menu_action('Menu da biblioteca','Assistente com IA')
assert any(n.attrib.get('text')=='Assistente local gratuito' for n in nodes())
capture('08-assistente-ia')
tap_text('Ativar')
voice('coloca aquelas musicas que eu mais gosto')
assert 'PlaybackState {state=3,' not in shell('dumpsys','media_session').decode()
entry=point(locate('Abrir biblioteca de vídeos'))
shell('am','start','-W','-n',PACKAGE+'/br.com.onda.MainActivity','--activity-single-top','--es','voice_phrase','toque Onda Sessions');time.sleep(1)
assert 'PlaybackState {state=3,' in shell('dumpsys','media_session').decode(),'Music fixture not playing before video'
shell('input','tap',*entry);time.sleep(2)
assert locate('Buscar vídeos por nome') is not None
pause_point=point(locate('Reproduzir vídeo'))
capture('11-biblioteca-videos')
tap('Menu de vídeos');capture('06-menu-videos');shell('input','keyevent','4');time.sleep(.3)
results=[]
try:
 # Exercise new controls first, then run the full container regression checks.
 tap('Buscar vídeos por nome');shell('input','text','ts');shell('input','keyevent','4');time.sleep(.3)
 first=locate('Assistir Onda-Video.ts');adb('logcat','-c');shell('input','tap',*point(first))
 for _ in range(60):
    if 'frames Onda-Video.ts' in adb('logcat','-d','-s','OndaVideo:D').decode(errors='replace'):break
    time.sleep(.3)
 else:raise AssertionError('Initial video did not render')
 shell('input','tap',*pause_point);time.sleep(.5)
 assert locate('Reproduzir vídeo') is not None
 # Gestures on the paused surface do not change global device settings.
 gesture=locate('Área de gestos do vídeo');bounds=[int(v) for v in re.findall(r'\d+',gesture.attrib['bounds'])]
 left,top,right,bottom=bounds;height=bottom-top;adb('logcat','-c')
 shell('input','swipe',left+(right-left)//4,top+height*3//4,left+(right-left)//4,top+height//4,400)
 shell('input','swipe',left+(right-left)*3//4,top+height//4,left+(right-left)*3//4,top+height*3//4,400)
 gesture_log=adb('logcat','-d','-s','OndaVideo:D').decode(errors='replace')
 assert 'gesture brightness' in gesture_log and 'gesture volume' in gesture_log,'Video gestures were not applied'
 # Real document picker grants access to the external SRT.
 tap('Legendas do vídeo');tap_text('Abrir legenda');time.sleep(.5)
 tree=nodes();folder=next((n for n in tree if n.attrib.get('text')=='OndaSubtitles'),None)
 if folder is not None:shell('input','tap',*point(folder));time.sleep(.3)
 document=next((n for n in nodes() if n.attrib.get('text')=='Onda-Captions.srt'),None)
 assert document is not None,'SRT fixture not visible in document picker'
 shell('input','tap',*point(document));time.sleep(1)
 resumed_pause=point(locate('Reproduzir vídeo'));adb('logcat','-c');shell('input','tap',*resumed_pause)
 for _ in range(20):
    subtitle_log=adb('logcat','-d','-s','OndaVideo:D').decode(errors='replace')
    if 'subtitle attached Onda-Captions.srt' in subtitle_log and 'subtitle-selected' in subtitle_log:break
    time.sleep(.3)
 else:raise AssertionError('External SRT was not selected by decoder: '+subtitle_log)
 time.sleep(5);capture('16-legenda-video');shell('input','tap',*resumed_pause);time.sleep(.5)
 # Re-selecting asks to continue, and continuing actually seeks in the decoder.
 tap('Assistir Onda-Video.ts')
 assert any(n.attrib.get('text')=='Continuar vídeo?' for n in nodes())
 capture('17-continuar-video');adb('logcat','-c');tap_text('Continuar');time.sleep(.8)
 resume_log=adb('logcat','-d','-s','OndaVideo:D').decode(errors='replace')
 resume_match=re.search(r'resumed ([0-9]+)',resume_log)
 assert resume_match and int(resume_match.group(1))>=3000,'Resume position not applied: '+resume_log
 shell('input','tap',*resumed_pause);time.sleep(.3)
 # Finish the activity and reopen: the bookmark must survive the native player instance.
 tap('Voltar à música');tap('Abrir biblioteca de vídeos')
 tap('Buscar vídeos por nome');shell('input','text','ts');shell('input','keyevent','4');time.sleep(.3)
 tap('Assistir Onda-Video.ts')
 assert any(n.attrib.get('text')=='Continuar vídeo?' for n in nodes()),'Bookmark lost after activity recreation'
 adb('logcat','-c');tap_text('Recomeçar');time.sleep(.8)
 fresh_pause=resumed_pause
 # Transport coordinates are stable in portrait; avoid idle dumps during playback.
 shell('input','tap',*fresh_pause);time.sleep(.5)
 assert 'resumed ' not in adb('logcat','-d','-s','OndaVideo:D').decode(errors='replace'),'Restart retained the old seek'
 assert locate('Reproduzir vídeo') is not None
 (OUTPUT/'video-controls-tests.json').write_text(json.dumps({'externalSrtSelected':True,'gestures':True,'resumeAfterReopen':True,'restart':True},indent=2)+'\n')
 for extension,vcodec,acodec,mime in formats:
    filename='Onda-Video.'+extension
    if extension in ('avi','flv','wmv'):
        # Use the real system file selector, which grants read access to unindexed formats.
        menu_action('Menu de vídeos','Abrir arquivo');time.sleep(1)
        tree=nodes()
        folder=next((n for n in tree if n.attrib.get('text')=='OndaDemo'),None)
        if folder is not None:shell('input','tap',*point(folder));time.sleep(.5)
        document=None
        for _ in range(5):
            tree=nodes();document=next((n for n in tree if n.attrib.get('text')==filename),None)
            if document is not None:break
            shell('input','swipe',540,1550,540,650,350);time.sleep(.3)
        (OUTPUT/('picker-'+extension+'.xml')).write_bytes(shell('cat','/sdcard/onda-video.xml'))
        assert document is not None,'File not visible in picker: '+filename
        adb('logcat','-c');shell('input','tap',*point(document));time.sleep(.5)
    else:
        tap('Buscar vídeos por nome');shell('input','keyevent','123')
        field=locate('Buscar vídeos por nome');previous=field.attrib.get('text','')
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
 # Android shows its own immersive-mode tutorial on the first fullscreen entry.
 prompt=next((n for n in nodes() if n.attrib.get('text','').upper() in ('GOT IT','ENTENDI')),None)
 if prompt is not None:shell('input','tap',*point(prompt));time.sleep(.5)
 assert locate('Sair da tela cheia') is not None
 resume=point(locate('Reproduzir vídeo'));adb('logcat','-c');shell('input','tap',*resume)
 for _ in range(20):
    if 'frames Onda-Video.ts' in adb('logcat','-d','-s','OndaVideo:D').decode(errors='replace'):break
    time.sleep(.5)
 else:raise AssertionError('Fullscreen resume did not render video')
 capture('13-video-tela-cheia')
 adb('logcat','-c');shell('input','keyevent','3');time.sleep(1)
 assert 'paused' in adb('logcat','-d','-s','OndaVideo:D').decode(),'Video did not pause when app hidden'
 shell('am','start','-W','-n',PACKAGE+'/br.com.onda.MainActivity');time.sleep(1)
 print('Android: menus, music/video/online navigation, local filters, online filter panel, timer, collections, updates and 8 video containers passed.')
finally:
 (OUTPUT/'video-tests.json').write_text(json.dumps(results,indent=2)+'\n')
 (OUTPUT/'video-logcat.txt').write_bytes(adb('logcat','-d','-v','threadtime'))
 (OUTPUT/'video-last-screen.png').write_bytes(adb('exec-out','screencap','-p'))
