"""Advance channel only after the published asset is downloaded and verified."""
import base64,hashlib,json,pathlib,subprocess
info=json.loads(pathlib.Path('FPlus/release.json').read_text());tag='folha-vplus'+info['versionName'];repo='cristianoarakaki-cpu/Arakaki'
def gh(*args):return subprocess.check_output(['gh',*args],text=True)
release=json.loads(gh('release','view',tag,'--repo',repo,'--json','isDraft,assets'))
assert not release['isDraft'],'Release ainda não publicada'
asset=next(a for a in release['assets'] if a['name']=='Folha-PDF.apk')
assert asset['url']==info['downloadUrl']
path=pathlib.Path('verify-download');path.mkdir(exist_ok=True)
subprocess.run(['gh','release','download',tag,'--repo',repo,'--pattern','Folha-PDF.apk','--dir',str(path),'--clobber'],check=True)
assert hashlib.sha256((path/'Folha-PDF.apk').read_bytes()).hexdigest()==info['sha256'],'Download remoto divergente'
remote=json.loads(gh('api',f'repos/{repo}/contents/FPlus/update.json?ref=main'))
current=json.loads(base64.b64decode(remote['content']));assert current['packageName']==info['packageName']
assert current['versionCode']<=info['versionCode'],'Canal já tem versão mais nova'
new=pathlib.Path('release-output/folha-update.json').read_bytes()
if current['versionCode']==info['versionCode'] and current.get('downloadAvailable'):
 assert current.get('sha256')==info['sha256'] and current.get('downloadUrl')==info['downloadUrl'],'Não substituímos versões já publicadas'
 print('Canal já atualizado');raise SystemExit(0)
payload={'message':f"Publicar canal Folha PDF+ {info['versionName']}",'branch':'main','sha':remote['sha'],'content':base64.b64encode(new).decode()}
p=pathlib.Path('release-output/channel-request.json');p.write_text(json.dumps(payload))
subprocess.run(['gh','api','--method','PUT',f'repos/{repo}/contents/FPlus/update.json','--input',str(p)],check=True,stdout=subprocess.DEVNULL)
print('Canal atualizado depois de conferir o download publicado')
