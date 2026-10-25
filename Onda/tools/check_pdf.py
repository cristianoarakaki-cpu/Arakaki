"""Open a real PDF through Android DocumentsUI, render pages, zoom and restore reading."""
from pathlib import Path
import subprocess,shlex,time,re,json,xml.etree.ElementTree as ET
PACKAGE='br.com.onda.musica';OUT=Path('Onda/ui-preview');OUT.mkdir(exist_ok=True,parents=True)
def adb(*args):return subprocess.check_output(['adb',*args],timeout=60)
def shell(*args):return adb('shell',shlex.join(str(v) for v in args))
def nodes():
 shell('uiautomator','dump','/sdcard/onda-pdf.xml');return list(ET.fromstring(shell('cat','/sdcard/onda-pdf.xml')).iter('node'))
def rect(n):return [int(v) for v in re.findall(r'\d+',n.attrib['bounds'])]
def tap_node(n):
 l,t,r,b=rect(n);assert r>l and b>t,n.attrib;shell('input','tap',(l+r)//2,(t+b)//2);time.sleep(.4)
def tap(desc):tap_node(next(n for n in nodes() if n.attrib.get('content-desc')==desc))
def capture(name):
 (OUT/(name+'.png')).write_bytes(adb('exec-out','screencap','-p'));(OUT/(name+'.xml')).write_bytes(shell('cat','/sdcard/onda-pdf.xml'))
def open_reader():
 tap('Menu da biblioteca')
 for _ in range(10):
  ns=nodes();target=next((n for n in ns if n.attrib.get('text')=='Leitor de PDF'),None)
  if target is not None and rect(target)[3]>rect(target)[1]:tap_node(target);return
  listing=next(n for n in ns if n.attrib.get('content-desc')=='Opções do menu');l,t,r,b=rect(listing)
  shell('input','swipe',(l+r)//2,t+int((b-t)*.85),(l+r)//2,t+int((b-t)*.2),250)
 raise AssertionError('PDF menu item unreachable')
def page(number):
 for _ in range(12):
  ns=nodes();status=next((n.attrib.get('text','') for n in ns if n.attrib.get('content-desc')=='Estado do leitor PDF'),'')
  label=next((n.attrib.get('text','') for n in ns if n.attrib.get('content-desc')=='Página atual do PDF'),'')
  if label==f'Página {number} de 3' and status.startswith('PDF local'):return
  time.sleep(.3)
 raise AssertionError('PDF page did not render: '+label+' / '+status)
# Self-contained, redistributable three-page fixture; no extra Python package.
objects=[b'<< /Type /Catalog /Pages 2 0 R >>',b'<< /Type /Pages /Kids [3 0 R 5 0 R 7 0 R] /Count 3 >>']
for i in range(3):
 content=f'0.9 0.95 1 rg 0 0 300 420 re f 0 0 0 rg BT /F1 20 Tf 30 360 Td (ONDA PDF - PAGINA {i+1}) Tj ET'.encode()
 objects.append(f'<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 420] /Resources << /Font << /F1 9 0 R >> >> /Contents {4+2*i} 0 R >>'.encode())
 objects.append(b'<< /Length '+str(len(content)).encode()+b' >>\nstream\n'+content+b'\nendstream')
objects.append(b'<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>')
pdf=bytearray(b'%PDF-1.4\n');offsets=[0]
for i,o in enumerate(objects,1):offsets.append(len(pdf));pdf.extend(f'{i} 0 obj\n'.encode()+o+b'\nendobj\n')
start=len(pdf);pdf.extend(f'xref\n0 {len(objects)+1}\n0000000000 65535 f \n'.encode())
for offset in offsets[1:]:pdf.extend(f'{offset:010d} 00000 n \n'.encode())
pdf.extend(f'trailer << /Size {len(objects)+1} /Root 1 0 R >>\nstartxref\n{start}\n%%EOF\n'.encode())
file=Path('/tmp/Onda-Guia.pdf');file.write_bytes(pdf);shell('mkdir','-p','/sdcard/Download');adb('push',str(file),'/sdcard/Download/Onda-Guia.pdf');shell('am','broadcast','-a','android.intent.action.MEDIA_SCANNER_SCAN_FILE','-d','file:///sdcard/Download/Onda-Guia.pdf')
try:
 shell('am','force-stop',PACKAGE);shell('am','start','-W','-n',PACKAGE+'/br.com.onda.MainActivity');time.sleep(1);open_reader();tap('Abrir PDF')
 # Search works even when the system picker remembers the video folder from prior checks.
 ns=nodes();document=next((n for n in ns if n.attrib.get('text')=='Onda-Guia.pdf'),None)
 search=next((n for n in ns if n.attrib.get('resource-id','').endswith('menu_search')),None)
 if search is None:search=next((n for n in ns if n.attrib.get('content-desc','').casefold() in ('search','pesquisar','buscar')),None)
 if document is None:
  assert search is not None,'Document picker search unavailable';tap_node(search);shell('input','text','Onda-Guia');shell('input','keyevent','66');time.sleep(.5)
 for _ in range(6):
  document=next((n for n in nodes() if n.attrib.get('text')=='Onda-Guia.pdf'),None)
  if document is not None:break
  time.sleep(.4)
 assert document is not None,'Generated PDF absent in system picker';tap_node(document);page(1);capture('37-pdf-primeira-pagina')
 tap('Próxima página do PDF');page(2);tap('Aumentar zoom do PDF');page(2)
 assert next(n for n in nodes() if n.attrib.get('content-desc')=='Zoom do PDF').attrib.get('text')=='125%'
 capture('38-pdf-zoom');tap('Página anterior do PDF');page(1)
 tap('Ir à página do PDF');tap('Número da página do PDF');shell('input','keyevent','123');shell('input','keyevent','67');shell('input','text','3');shell('input','keyevent','4')
 tap_node(next(n for n in nodes() if n.attrib.get('text','').casefold()=='abrir'));page(3)
 shell('am','force-stop',PACKAGE);shell('am','start','-W','-n',PACKAGE+'/br.com.onda.MainActivity');time.sleep(.5);open_reader();tap('Continuar último PDF');page(3);capture('39-pdf-retomada')
 (OUT/'pdf-tests.json').write_text(json.dumps({'systemPickerReadGrant':True,'pages':3,'nextAndPrevious':True,'zoom':1.25,'goToPage':3,'restoreAfterProcessRestart':3},indent=2)+'\n')
 tap('Voltar do PDF');time.sleep(.5)
 print('PDF reader passed: system picker, real pages, previous/next, zoom, page selection and persisted read permission after process restart.')
except Exception:
 try:nodes();capture('pdf-failure');(OUT/'pdf-failure-logcat.txt').write_bytes(adb('logcat','-d'))
 except Exception:pass
 raise
