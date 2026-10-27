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
 for name in ['download_history','onda_folders','library']:saved[name]=readprefs(name)
 folder=json.loads(shell('run-as',P,'cat','files/onda-folders-tests.json'))
 writeprefs('onda_folders',prefsxml({'tree':folder['tree'],'enabled':True}))
 entry=dict(id=str(uuid.uuid4()),title='Exemplo para tentar novamente',source=URL,format='mp4',state='failed',detail='Conexão interrompida no teste',time=int(time.time()*1000),bytes=50,expected=100)
 writeprefs('download_history',prefsxml({'data':json.dumps(dict(version=1,items=[entry]))}))
 shell('am','start','-W','-n',P+'/br.com.onda.DownloadCenterActivity');time.sleep(.5)
 tap('Exemplo para tentar novamente');tap('Tentar novamente')
 assert any(n.attrib.get('content-desc')=='Link do vídeo' and n.attrib.get('text')==URL for n in nodes())
 tap('Analisar link');until=time.monotonic()+95
 while time.monotonic()<until:
  time.sleep(.5);status=prefs('downloads').get('status','')
  if 'Escolha um formato para baixar' in status:break
  assert 'Não foi possível analisar' not in status,status
 else:raise AssertionError('Direct link timeout')
 tap('MP4 • arquivo original');assert any('Onda/Vídeos' in n.attrib.get('text','') for n in nodes());capture('72-pasta-onda-confirmacao');tap('Salvar na pasta Onda')
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
 shell('am','start','-W','-n',P+'/br.com.onda.MainActivity');time.sleep(.6);tap('Menu da biblioteca',True);tap('Organizar biblioteca');tap('Ordenar: Título A–Z');tap('Artista A–Z');time.sleep(.3)
 library=ET.fromstring(shell('run-as',P,'cat','shared_prefs/library.xml'));assert any(n.attrib.get('name')=='sort_order' and n.attrib.get('value')=='1' for n in library)
 capture('74-biblioteca-artistas')
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
