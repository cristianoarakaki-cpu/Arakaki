"""Real menu, Android folder grant, QR waiting state and explicit cancellation."""
from pathlib import Path
import subprocess,shlex,time,re,json,xml.etree.ElementTree as ET
P='br.com.onda.musica';OUT=Path('Onda/ui-preview');OUT.mkdir(exist_ok=True,parents=True)
def adb(*a):return subprocess.check_output(['adb',*a],timeout=60)
def shell(*a):return adb('shell',shlex.join(str(x) for x in a))
def nodes():
 for _ in range(4):
  try:
   shell('rm','-f','/sdcard/onda-connect.xml');shell('uiautomator','dump','/sdcard/onda-connect.xml');return list(ET.fromstring(shell('cat','/sdcard/onda-connect.xml')).iter('node'))
  except (subprocess.CalledProcessError,ET.ParseError):time.sleep(.3)
 raise AssertionError('No accessible Android tree')
def tap_node(n):
 l,t,r,b=map(int,re.findall(r'\d+',n.attrib['bounds']));assert r>l and b>t;shell('input','tap',(l+r)//2,(t+b)//2);time.sleep(.4)
def find(value):
 for _ in range(8):
  ns=nodes();n=next((n for n in ns if n.attrib.get('content-desc')==value or n.attrib.get('text','').casefold()==value.casefold() or n.attrib.get('resource-id')==value),None)
  if n is not None:return n
  time.sleep(.3)
 raise AssertionError('Missing '+value)
def tap(value):tap_node(find(value))
def capture(name):(OUT/(name+'.png')).write_bytes(adb('exec-out','screencap','-p'))
try:
 shell('am','force-stop',P);shell('pm','grant',P,'android.permission.READ_EXTERNAL_STORAGE');shell('am','start','-W','-n',P+'/br.com.onda.MainActivity');tap('Menu da biblioteca');tap('Onda Conecta')
 assert find('Escolher arquivos para enviar').attrib.get('enabled')=='true'
 capture('60-conecta-inicial');tap('Receber arquivos pelo Conecta')
 # The system folder picker is English in this emulator.
 ns=nodes();drawer=next((n for n in ns if n.attrib.get('content-desc') in ['Show roots','Mostrar raízes']),None)
 if drawer is not None:tap_node(drawer)
 ns=nodes();download=next((n for n in ns if n.attrib.get('text')=='Downloads'),None)
 if download is not None:tap_node(download)
 for _ in range(5):
  ns=nodes();select=next((n for n in ns if n.attrib.get('resource-id')=='com.android.documentsui:id/action_menu_select' or n.attrib.get('text','').casefold() in ('use this folder','usar esta pasta','select')),None)
  if select is not None:tap_node(select);break
  time.sleep(.3)
 else:raise AssertionError('Android folder confirmation unavailable')
 ns=nodes();allow=next((n for n in ns if n.attrib.get('text','').casefold() in ('allow','permitir')),None)
 if allow is not None:tap_node(allow)
 find('QR de pareamento do Onda Conecta');capture('61-conecta-qr')
 # No media starts automatically while advertising a receiving session.
 assert 'state=3,' not in shell('dumpsys','media_session').decode()
 # Cancel is below the fold; scroll only within the page.
 for _ in range(9):
  ns=nodes();n=next((n for n in ns if n.attrib.get('text')=='Cancelar transferência'),None)
  if n is not None:
   l,t,r,b=map(int,re.findall(r'\d+',n.attrib['bounds']))
   if b>t and t>0:tap_node(n);break
  shell('input','swipe',540,1580,540,550,300)
 else:raise AssertionError('Cancel not reachable')
 assert not any(n.attrib.get('content-desc')=='QR de pareamento do Onda Conecta' for n in nodes())
 assert any('Cancelado.' in n.attrib.get('text','') for n in nodes())
 capture('62-conecta-cancelado')
 (OUT/'connect-ui-tests.json').write_text(json.dumps(dict(menu=True,systemFolderGrant=True,localQr=True,noAutoplay=True,explicitCancellation=True),indent=2))
except Exception:
 (OUT/'connect-failure.png').write_bytes(adb('exec-out','screencap','-p'));(OUT/'connect-failure-logcat.txt').write_bytes(adb('logcat','-d'));raise
finally:shell('am','force-stop',P)
