"""CI emulator only: install the previous Onda, retain its data across a real package upgrade."""
from pathlib import Path
import subprocess,shlex,time,re,json,xml.etree.ElementTree as ET
PACKAGE='br.com.onda.musica'
def adb(*args,data=None):
 return subprocess.run(['adb',*args],input=data,stdout=subprocess.PIPE,stderr=subprocess.PIPE,check=True,timeout=90).stdout
def shell(*args,data=None):return adb('shell',shlex.join(str(v) for v in args),data=data)
assert any(shell('getprop',prop).strip()==b'1' for prop in ('ro.kernel.qemu','ro.boot.qemu')),'Upgrade test is restricted to an emulator'
previous=Path('Onda/upgrade-fixtures/Onda-0.21.1-x86_64.apk');current=Path('Onda/app/build/outputs/apk/debug/app-debug.apk')
assert previous.is_file() and current.is_file()
adb('install','-r',str(previous));old_info=shell('dumpsys','package',PACKAGE).decode()
assert re.search(r'versionCode=25\b',old_info),'Expected the actual Onda 0.21.1'
shell('pm','grant',PACKAGE,'android.permission.READ_EXTERNAL_STORAGE')
shell('am','force-stop',PACKAGE);shell('run-as',PACKAGE,'mkdir','-p','shared_prefs')
playlist=[{'id':'d52038c3-a495-42c4-aae6-f270ec3fd93f','name':'AtualizacaoTeste','songs':['100001']}]
phrases=[{'id':'6ef7b11c-7951-4774-9961-299a534ae94f','phrase':'momento preservado','action':'FAVORITES','query':'','minutes':0}]
seeds={
 'library':{'favorites':{'100001'}},
 'playlists':{'lists':json.dumps(playlist,ensure_ascii=False)},
 'voice_phrases':{'entries':json.dumps(phrases,ensure_ascii=False)},
 'sound':{'enabled':True,'bass':10,**{f'gain_{i}':v for i,v in enumerate([1,-1,0,1,0])}},
}
def xml(values):
 root=ET.Element('map')
 for key,value in values.items():
  if isinstance(value,bool):ET.SubElement(root,'boolean',name=key,value=str(value).lower())
  elif isinstance(value,int):ET.SubElement(root,'int',name=key,value=str(value))
  elif isinstance(value,set):
   node=ET.SubElement(root,'set',name=key)
   for item in sorted(value):ET.SubElement(node,'string').text=item
  else:ET.SubElement(root,'string',name=key).text=value
 return ET.tostring(root,encoding='utf-8',xml_declaration=True)
def read(name):
 root=ET.fromstring(shell('run-as',PACKAGE,'cat','shared_prefs/'+name+'.xml'));out={}
 for node in root:
  if node.tag=='set':value={child.text for child in node}
  elif node.tag=='boolean':value=node.get('value')=='true'
  elif node.tag=='int':value=int(node.get('value'))
  else:value=node.text or ''
  out[node.get('name')]=value
 return out
for name,values in seeds.items():shell('run-as',PACKAGE,'sh','-c','cat > shared_prefs/'+name+'.xml',data=xml(values))
shell('am','start','-W','-n',PACKAGE+'/br.com.onda.MainActivity');time.sleep(1);shell('am','force-stop',PACKAGE)
for name,values in seeds.items():assert read(name)==values,('Old Onda did not retain its seed',name)
adb('install','-r',str(current));new_info=shell('dumpsys','package',PACKAGE).decode()
assert re.search(r'versionCode=50\b',new_info),'The main Onda was not upgraded'
assert re.search(r'userId=(\d+)',old_info).group(1)==re.search(r'userId=(\d+)',new_info).group(1),'App UID changed'
shell('am','start','-W','-n',PACKAGE+'/br.com.onda.MainActivity');time.sleep(1);shell('am','force-stop',PACKAGE)
for name,values in seeds.items():assert read(name)==values,('Upgrade lost data',name)
output=Path('Onda/ui-preview');output.mkdir(exist_ok=True,parents=True)
(output/'upgrade-tests.json').write_text(json.dumps({'from':'0.21.1','to':'0.41.0','installWithoutUninstall':True,'samePackageAndUid':True,'favorites':True,'playlists':True,'voicePhrases':True,'sound':True},indent=2))
print('Real Onda upgrade passed: favorites, playlists, voice phrases and sound settings retained.')
# Reset only the emulator test fixture, so the existing regression suite starts in its normal state.
shell('pm','clear',PACKAGE)
