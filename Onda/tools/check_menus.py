"""Reproduce the cut-off menu on a small display with enlarged text, then rotate."""
from pathlib import Path
import subprocess,shlex,time,re,json,xml.etree.ElementTree as ET
PACKAGE='br.com.onda.musica'
OUT=Path('Onda/ui-preview');OUT.mkdir(exist_ok=True,parents=True)
def adb(*a):return subprocess.check_output(['adb',*a],timeout=60)
def shell(*a):return adb('shell',shlex.join(str(v) for v in a))
def nodes():
 shell('uiautomator','dump','/sdcard/onda-menu.xml')
 return list(ET.fromstring(shell('cat','/sdcard/onda-menu.xml')).iter('node'))
def bounds(n):return [int(v) for v in re.findall(r'\d+',n.attrib['bounds'])]
def tap(n):
 x1,y1,x2,y2=bounds(n);assert x2>x1 and y2>y1
 shell('input','tap',(x1+x2)//2,(y1+y2)//2);time.sleep(.4)
def find(desc):return next(n for n in nodes() if n.attrib.get('content-desc')==desc)
def capture(name):
 (OUT/(name+'.png')).write_bytes(adb('exec-out','screencap','-p'))
 (OUT/(name+'.xml')).write_bytes(shell('cat','/sdcard/onda-menu.xml'))
old_size=shell('wm','size').decode();override=re.search(r'Override size:\s*(\d+x\d+)',old_size)
old_font=shell('settings','get','system','font_scale').decode().strip()
density_text=shell('wm','density').decode();density_values=re.findall(r'(?:Physical|Override) density:\s*(\d+)',density_text)
density=int(density_values[-1])/160
results=[]
try:
 shell('pm','grant',PACKAGE,'android.permission.READ_EXTERNAL_STORAGE')
 for name,size,font in [('portrait','720x1280','1.5'),('landscape','1280x720','1.3')]:
  shell('am','force-stop',PACKAGE);shell('wm','size',size);shell('settings','put','system','font_scale',font);time.sleep(1)
  shell('am','start','-W','-n',PACKAGE+'/br.com.onda.MainActivity');time.sleep(1)
  tap(find('Menu da biblioteca'));ns=nodes();capture('00-menu-'+name+'-inicio')
  width,height=map(int,size.split('x'))
  listing=next(n for n in ns if n.attrib.get('content-desc')=='Opções do menu')
  close=next(n for n in ns if n.attrib.get('resource-id')=='android:id/button2')
  for n in [listing,close]:
   left,top,right,bottom=bounds(n);assert 0<=left<right<=width and 0<top<bottom<height,(name,n.attrib)
  assert bounds(close)[1]>=bounds(listing)[3], 'Close button must remain outside the scrolling list'
  for _ in range(18):
   ns=nodes();listing=next(n for n in ns if n.attrib.get('content-desc')=='Opções do menu')
   last=next((n for n in ns if n.attrib.get('text')=='Minhas frases'),None)
   if last is not None and bounds(last)[3]-bounds(last)[1]>=int(48*density)-2:break
   left,top,right,bottom=bounds(listing);x=(left+right)//2
   shell('input','swipe',x,top+int((bottom-top)*.9),x,top+int((bottom-top)*.1),250);time.sleep(.2)
  else:raise AssertionError('Last menu item not fully reachable on '+name)
  capture('00-menu-'+name+'-fim');tap(last)
  assert find('Adicionar frase de voz') is not None, 'Last item must open its actual screen'
  shell('input','keyevent','4');time.sleep(.3);tap(find('Menu da biblioteca'))
  tap(next(n for n in nodes() if n.attrib.get('resource-id')=='android:id/button2'))
  assert not any(n.attrib.get('content-desc')=='Opções do menu' for n in nodes()),'Close did not dismiss menu'
  tap(find('Menu da biblioteca'));shell('input','keyevent','4');time.sleep(.3)
  assert not any(n.attrib.get('content-desc')=='Opções do menu' for n in nodes()),'Back did not dismiss menu'
  results.append({'layout':name,'size':size,'fontScale':float(font),'lastItemReachable':True,'lastItemOpensScreen':True,'fixedClose':True,'backDismisses':True})
 print('Bounded menus passed: small portrait with large font, landscape, last item, fixed close and Back.')
except Exception:
 try:nodes();capture('00-menu-failure');(OUT/'menu-failure-logcat.txt').write_bytes(adb('logcat','-d'))
 except Exception:pass
 raise
finally:
 (OUT/'menu-tests.json').write_text(json.dumps(results,indent=2)+'\n')
 shell('am','force-stop',PACKAGE)
 shell('wm','size',override.group(1) if override else 'reset')
 shell('settings','put','system','font_scale',old_font if old_font not in ('','null') else '1.0')
