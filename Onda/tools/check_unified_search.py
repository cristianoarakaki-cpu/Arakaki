"""Unified search UI with real MediaStore files, saved collection, annotation and PDF anchor."""
from pathlib import Path
import subprocess,shlex,time,re,json,xml.etree.ElementTree as ET
P='br.com.onda.musica';OUT=Path('Onda/ui-preview')
def adb(*a):return subprocess.check_output(['adb',*a],timeout=60)
def shell(*a):return adb('shell',shlex.join(str(x) for x in a))
def nodes():
 shell('uiautomator','dump','/sdcard/onda-search.xml');return list(ET.fromstring(shell('cat','/sdcard/onda-search.xml')).iter('node'))
def target(value):
 for _ in range(6):
  n=next((n for n in nodes() if n.attrib.get('content-desc')==value or n.attrib.get('text','').casefold()==value.casefold()),None)
  if n is not None:return n
  time.sleep(.25)
 raise AssertionError('Missing '+value)
def tap(value):
 n=target(value);l,t,r,b=map(int,re.findall(r'\d+',n.attrib['bounds']));assert r>l and b>t;shell('input','tap',(l+r)//2,(t+b)//2);time.sleep(.4)
def phrase(value):
 shell('am','start','-W','-n',P+'/br.com.onda.MainActivity','--es','voice_phrase',value);time.sleep(.5)
def capture(name):(OUT/(name+'.png')).write_bytes(adb('exec-out','screencap','-p'))
def page(n):
 for _ in range(8):
  if any(x.attrib.get('content-desc')=='Página atual do PDF' and x.attrib.get('text')==f'Página {n} de 3' for x in nodes()):return
  time.sleep(.3)
 raise AssertionError('Wrong PDF page')
try:
 shell('am','force-stop',P)
 phrase('busque no Onda Onda-Audio');target('Resultado Áudio: Onda-Audio');capture('50-busca-unificada')
 shell('input','keyevent','4');phrase('busque no Onda Revisar aula');target('Resultado Anotação: Onda-Guia.pdf');capture('51-busca-anotacao')
 tap('Resultado Anotação: Onda-Guia.pdf');tap('Abrir ponto');page(2)
 phrase('abra minha colecao Estudo');target('Retomar Onda-Guia.pdf');target('Retomar Onda-Audio');capture('52-colecao-por-voz')
 phrase('continue o ultimo PDF');page(2)
 phrase('abra o PDF Onda-Guia');target('Resultado PDF: Onda-Guia.pdf');assert not any(n.attrib.get('content-desc','').startswith('Resultado Áudio:') for n in nodes())
 tap('Tipo de resultado da busca');tap('Anotações');target('Resultado Anotação: Onda-Guia.pdf')
 (OUT/'unified-search-tests.json').write_text(json.dumps(dict(localAudio=True,annotationTextSearch=True,noteAnchorPage=2,voiceCollection=True,voiceLastPdf=True,typeFilter=True),indent=2))
except Exception:
 (OUT/'search-failure.png').write_bytes(adb('exec-out','screencap','-p'));(OUT/'search-failure-logcat.txt').write_bytes(adb('logcat','-d'));raise
finally:shell('am','force-stop',P)
