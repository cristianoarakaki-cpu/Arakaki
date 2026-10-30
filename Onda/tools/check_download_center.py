"""Real UI, SAF output and retry navigation; restore preferences after fixture cleanup."""
from pathlib import Path
import subprocess,shlex,time,json,re,xml.etree.ElementTree as ET,uuid
P='br.com.onda.musica';OUT=Path('Onda/ui-preview');OUT.mkdir(exist_ok=True,parents=True)
URL='https://raw.githubusercontent.com/cristianoarakaki-cpu/Arakaki/245b693e64cf5b5b33bc2a5f491a607f6a435655/Onda/tests/fixtures/download.mp4'
def adb(*args):return subprocess.check_output(['adb',*args],timeout=60)
def shell(*args):return adb('shell',shlex.join(str(a) for a in args))
def nodes():
 for _ in range(4):
  try:shell('uiautomator','dump','/sdcard/onda-center.xml');return list(ET.fromstring(shell('cat','/sdcard/onda-center.xml')).iter('node'))
  except (subprocess.CalledProcessError,ET.ParseError):time.sleep(.3)
 raise AssertionError('No accessibility tree')
def tap(label,desc=False):
 for attempt in range(12):
  ns=nodes()
  n=next((n for n in ns if n.attrib.get('content-desc' if desc else 'text','').casefold()==label.casefold()),None)
  if n is not None:
   l,t,r,b=map(int,re.findall(r'\d+',n.attrib['bounds']));assert r>l and b>t;shell('input','tap',(l+r)//2,(t+b)//2);time.sleep(.4);return
  scroll=next((n for n in ns if n.attrib.get('content-desc')=='Opções do menu'),None)
  if scroll is not None:
   l,t,r,b=map(int,re.findall(r'\d+',scroll.attrib['bounds']));shell('input','swipe',(l+r)//2,t+(b-t)*8//10,(l+r)//2,t+(b-t)//10,250)
  time.sleep(.3)
 raise AssertionError('Missing '+label)
def capture(name):(OUT/(name+'.png')).write_bytes(adb('exec-out','screencap','-p'))
def readprefs(name):
 try:return shell('run-as',P,'cat','shared_prefs/'+name+'.xml')
 except subprocess.CalledProcessError:return None
def writeprefs(name,data):
 path=Path('/tmp/onda-center-prefs.xml');path.write_bytes(data);adb('push',str(path),'/data/local/tmp/onda-center-prefs.xml');shell('run-as',P,'cp','/data/local/tmp/onda-center-prefs.xml','shared_prefs/'+name+'.xml')
def prefsxml(values):
 root=ET.Element('map')
 for k,v in values.items():
  if isinstance(v,bool):ET.SubElement(root,'boolean',name=k,value=str(v).lower())
  else:ET.SubElement(root,'string',name=k).text=v
 return ET.tostring(root,encoding='utf-8',xml_declaration=True)
def prefs(name):
 xml=readprefs(name);return {n.attrib['name']:n.text or '' for n in ET.fromstring(xml)} if xml else {}
saved={};downloaded=False
try:
 shell('am','force-stop',P)
 for name in ['download_history','onda_folders','library','playback_tools']:saved[name]=readprefs(name)
 folder=json.loads(shell('run-as',P,'cat','files/onda-folders-tests.json'))
 writeprefs('onda_folders',prefsxml({'tree':folder['tree'],'enabled':True}))
 entry=dict(id=str(uuid.uuid4()),title='Exemplo para tentar novamente',source=URL,format='mp4',state='failed',detail='Conexão interrompida no teste',time=int(time.time()*1000),bytes=50,expected=100)
 writeprefs('download_history',prefsxml({'data':json.dumps(dict(version=1,items=[entry]))}))
 shell('am','start','-W','-n',P+'/br.com.onda.DownloadsActivity');time.sleep(.5);tap('Central');time.sleep(.3)
 tap('Exemplo para tentar novamente');tap('Tentar novamente')
 assert any(n.attrib.get('content-desc')=='Link do vídeo' and n.attrib.get('text')==URL for n in nodes())
 tap('Analisar link');until=time.monotonic()+95
 while time.monotonic()<until:
  time.sleep(.5);status=prefs('downloads').get('status','')
  if 'Escolha um formato para baixar' in status:break
  assert 'Não foi possível analisar' not in status,status
 else:raise AssertionError('Direct link timeout')
 tap('MP4 • arquivo original');assert not any(n.attrib.get('text')=='Salvar download' for n in nodes());capture('72-pasta-onda-automatica')
 until=time.monotonic()+95
 while time.monotonic()<until:
  time.sleep(.5);status=prefs('downloads').get('status','')
  if status.startswith('Download concluído'):downloaded=True;break
  assert not status.startswith('Operação interrompida'),status
 assert downloaded,status
 ledger=json.loads(prefs('download_history')['data']);complete=next(x for x in ledger['items'] if x.get('state')=='done')
 assert complete['source']==URL and complete['bytes']>0
 assert '/Onda/Vídeos/' in complete['uri'].replace('%2F','/').replace('%C3%AD','í'),complete['uri']
 tap('Central');time.sleep(.5);assert any(n.attrib.get('text')=='Concluído • MP4 • '+time.strftime('%d/%m %H:%M',time.gmtime(complete['time']/1000)) for n in nodes()) or any('Concluído • MP4' in n.attrib.get('text','') for n in nodes());capture('73-central-downloads')
 tap('Menu da central',True);tap('Arquivos do Onda');tap('▸ Vídeos')
 files=nodes();video=next(n.attrib.get('text') for n in files if n.attrib.get('text','').startswith('download') and n.attrib.get('text','').endswith('.mp4'));tap(video);tap('Converter áudio')
 until=time.monotonic()+30
 while time.monotonic()<until:
  if any('Áudio AAC compatível' in n.attrib.get('text','') for n in nodes()):break
  time.sleep(.3)
 else:raise AssertionError('Local AAC inspection did not complete')
 capture('76-conversor-local');tap('Extrair M4A • sem recodificar');tap('Salvar na pasta Onda')
 until=time.monotonic()+60
 while time.monotonic()<until:
  time.sleep(.3);conversion=prefs('downloads').get('status','')
  if conversion.startswith('Conversão concluída'):break
  assert not conversion.startswith('Operação interrompida'),conversion
 else:raise AssertionError('Local M4A conversion did not complete')
 capture('77-conversao-central')
 shell('am','start','-W','-n',P+'/br.com.onda.MainActivity');time.sleep(.6);tap('Menu da biblioteca',True);tap('Organizar biblioteca');tap('Ordenar: Título A–Z');tap('Artista A–Z');time.sleep(.3)
 library=ET.fromstring(shell('run-as',P,'cat','shared_prefs/library.xml'));assert any(n.attrib.get('name')=='sort_order' and n.attrib.get('value')=='1' for n in library)
 capture('74-biblioteca-artistas');tap('Menu da biblioteca',True);tap('Organizar biblioteca');assert any(n.attrib.get('text')=='Copiar favoritas para a pasta do Onda' for n in nodes());capture('75-organizar-e-copiar-favoritas');tap('Fechar')
 tap('Menu da biblioteca',True);tap('Controles de áudio');tap('Velocidade de áudio');tap('1,25×');time.sleep(.4);speed=ET.fromstring(shell('run-as',P,'cat','shared_prefs/playback_tools.xml'));assert any(n.attrib.get('name')=='speed' and n.attrib.get('value')=='3' for n in speed);capture('78-controles-audio')
 (OUT/'evolution-ui-tests.json').write_text(json.dumps(dict(folderNavigation=True,localAacInspection=True,localM4aConversion=True,audioSpeedSetting=True),indent=2))
 (OUT/'download-center-tests.json').write_text(json.dumps(dict(retryReanalysesSource=True,savesInOndaVideoFolder=True,completedRecord=True,libraryArtistSort=True,folderNativeChecks=folder),indent=2,ensure_ascii=False))
except Exception:
 capture('download-center-failure');(OUT/'download-center-logcat.txt').write_bytes(adb('logcat','-d'));raise
finally:
 shell('am','force-stop',P)
 # Native DocumentsContract cleanup, not a path guess or an external-file deletion.
 subprocess.run(['adb','shell','am','instrument','-w','-e','class','br.com.onda.DownloadOrganizationTest#cleanupUiFixture',P+'.test/androidx.test.runner.AndroidJUnitRunner'],timeout=60,check=False)
 shell('am','force-stop',P)
 for name,data in saved.items():
  if data is None:shell('run-as',P,'rm','-f','shared_prefs/'+name+'.xml')
  else:writeprefs(name,data)
