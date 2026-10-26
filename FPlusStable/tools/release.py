import hashlib,json,os,pathlib,re,subprocess,sys
from signing import api
ROOT=pathlib.Path('FPlusStable');REPO='cristianoarakaki-cpu/Arakaki'
def gh(*args):return subprocess.check_output(['gh',*args],text=True)
def prepare():
 v=json.loads((ROOT/'version.json').read_text());assert re.fullmatch(r'\d+\.\d+\.\d+',v['versionName']);assert type(v['versionCode']) is int and v['versionCode']>0
 apk=pathlib.Path('FPlus/source/build/Folha-PDF-Stable.apk');bt=pathlib.Path(os.environ['ANDROID_HOME'])/'build-tools/35.0.0'
 signature=subprocess.check_output([str(bt/'apksigner'),'verify','--verbose','--print-certs',str(apk)],text=True)
 certs={x.replace(':','').lower() for x in re.findall(r'certificate SHA-256 digest:\s*([a-fA-F0-9:]+)',signature)}
 assert certs=={(ROOT/'signing/certificate.sha256').read_text().strip()},'Certificado diferente da identidade permanente'
 badging=subprocess.check_output([str(bt/'aapt'),'dump','badging',str(apk)],text=True);p=re.search(r"package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'",badging)
 assert p and p[1]=='com.folha.pd2.stable' and int(p[2])==v['versionCode'] and p[3]==v['versionName']
 tag='folha-stable-v'+v['versionName'];info={'packageName':'com.folha.pd2.stable','versionCode':v['versionCode'],'versionName':v['versionName'],'downloadAvailable':True,'downloadUrl':f'https://github.com/{REPO}/releases/download/{tag}/Folha-PDF-Stable.apk','sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'notes':v['notes']}
 out=pathlib.Path('stable-output');out.mkdir(exist_ok=True);(out/'update.json').write_text(json.dumps(info,ensure_ascii=False,indent=2)+'\n');(out/'SHA256SUMS.txt').write_text(info['sha256']+'  Folha-PDF-Stable.apk\n');(out/'notes.txt').write_text(v['notes']+'\n\nInstalação independente dos testes anteriores. As próximas atualizações desta edição usam a mesma assinatura. O Android pede confirmação para instalar.\n');(out/'tag.txt').write_text(tag)
 print('APK definitivo, certificado e versão conferidos.')
def publish():
 import base64
 info=json.loads(pathlib.Path('stable-output/update.json').read_text());tag='folha-stable-v'+info['versionName']
 # Never downgrade the channel; same-version retries must retain the same APK.
 remote=api('contents/FPlusStable/update.json?ref=main');current=json.loads(base64.b64decode(remote['content']));assert current['packageName']==info['packageName'];assert current['versionCode']<=info['versionCode'],'Canal já tem versão superior'
 release=subprocess.run(['gh','release','view',tag,'--repo',REPO,'--json','isDraft'],capture_output=True,text=True)
 if release.returncode:
  subprocess.run(['gh','release','create',tag,'FPlus/source/build/Folha-PDF-Stable.apk','stable-output/update.json','stable-output/SHA256SUMS.txt','--repo',REPO,'--target',os.environ['FOLHA_STABLE_RELEASE_COMMIT'],'--title','Folha PDF+ Definitivo '+info['versionName'],'--notes-file','stable-output/notes.txt','--latest=false','--draft'],check=True)
  subprocess.run(['gh','release','edit',tag,'--repo',REPO,'--draft=false','--latest=false'],check=True)
 else:assert not json.loads(release.stdout)['isDraft'],'Existe rascunho de publicação; confira seus arquivos antes de publicar'
 verify=pathlib.Path('stable-verify');verify.mkdir(exist_ok=True)
 subprocess.run(['gh','release','download',tag,'--repo',REPO,'--pattern','Folha-PDF-Stable.apk','--dir',str(verify),'--clobber'],check=True)
 assert hashlib.sha256((verify/'Folha-PDF-Stable.apk').read_bytes()).hexdigest()==info['sha256'],'APK publicado divergente'
 if current['versionCode']==info['versionCode'] and current.get('downloadAvailable'):
  assert current.get('sha256')==info['sha256'];print('Canal já atualizado.');return
 api('contents/FPlusStable/update.json','PUT',{'message':'Publicar Folha PDF+ Definitivo '+info['versionName'],'sha':remote['sha'],'branch':'main','content':base64.b64encode(pathlib.Path('stable-output/update.json').read_bytes()).decode()})
 print('Download verificado; canal definitivo atualizado.')
if __name__=='__main__':
 if sys.argv[1]=='prepare':prepare()
 elif sys.argv[1]=='publish':publish()
 else:raise SystemExit('Use prepare ou publish')
