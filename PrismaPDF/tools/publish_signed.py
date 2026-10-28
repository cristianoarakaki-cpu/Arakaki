"""Publish an already-signed APK. Never reads or receives a private signing key."""
import base64,hashlib,json,pathlib,re,subprocess,sys,zipfile
ROOT=pathlib.Path('PrismaPDF');REPO='cristianoarakaki-cpu/Arakaki'
def gh(*args):return subprocess.check_output(['gh',*args],text=True)
def api(path,method='GET',data=None):
 command=['gh','api','--method',method,'repos/'+REPO+'/'+path]
 if data is not None:command+=['--input','-']
 result=subprocess.run(command,input=None if data is None else json.dumps(data).encode(),capture_output=True)
 if result.returncode:raise RuntimeError('Falha ao acessar '+path)
 return json.loads(result.stdout) if result.stdout.strip() else {}
def prepare():
 info=json.loads((ROOT/'distribution/release.json').read_text());parts=json.loads((ROOT/'distribution/parts.json').read_text())
 assert info['packageName']=='com.arakaki.prismapdf'
 assert type(info['versionCode']) is int and info['versionCode']>0
 assert re.fullmatch(r'\d+\.\d+\.\d+',info['versionName'])
 assert re.fullmatch(r'[a-f0-9]{64}',info['sha256'])
 assert info['certificateSha256']==(ROOT/'signing/certificate.sha256').read_text().strip()
 assert info['downloadUrl']==f"https://github.com/{REPO}/releases/download/prisma-v{info['versionName']}/Prisma-PDF.apk"
 chunks=[]
 for i,p in enumerate(parts):
  assert p['name']==f'Prisma-PDF.apk.part{i:03d}'
  data=(ROOT/'distribution'/p['name']).read_bytes();assert len(data)==p['size'] and hashlib.sha256(data).hexdigest()==p['sha256'];chunks.append(data)
 data=b''.join(chunks);assert len(data)==info['size'] and hashlib.sha256(data).hexdigest()==info['sha256']
 out=pathlib.Path('prisma-publish');out.mkdir(exist_ok=True);(out/'Prisma-PDF.apk').write_bytes(data)
 with zipfile.ZipFile(out/'Prisma-PDF.apk') as z:assert z.testzip() is None and 'assets/THIRD-PARTY-NOTICES.txt' in z.namelist()
 bt=pathlib.Path(sys.argv[2]);verified=subprocess.check_output([str(bt/'apksigner'),'verify','--verbose','--print-certs',str(out/'Prisma-PDF.apk')],text=True)
 certs={s.replace(':','').lower() for s in re.findall(r'certificate SHA-256 digest:\s*([a-fA-F0-9:]+)',verified)};assert certs=={info['certificateSha256']},'Assinatura diferente da identidade fixada'
 subprocess.run([str(bt/'zipalign'),'-c','4',str(out/'Prisma-PDF.apk')],check=True)
 badging=subprocess.check_output([str(bt/'aapt'),'dump','badging',str(out/'Prisma-PDF.apk')],text=True)
 package=re.search(r"package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'",badging)
 assert package and package[1]==info['packageName'] and int(package[2])==info['versionCode'] and package[3]==info['versionName']
 manifest={key:info[key] for key in ['packageName','versionCode','versionName','downloadUrl','sha256','notes']};manifest['downloadAvailable']=True
 (out/'update.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n');(out/'SHA256SUMS.txt').write_text(info['sha256']+'  Prisma-PDF.apk\n');(out/'tag.txt').write_text('prisma-v'+info['versionName']);(out/'notes.txt').write_text(info['notes']+'\n\nAPK instalável assinado. Sem conta e sem cadastro de senha. As ações online começam desativadas. O Android pede confirmação para instalar.\n')
 print('APK, assinatura, certificado, alinhamento, pacote e versão conferidos.')
def publish():
 info=json.loads((ROOT/'distribution/release.json').read_text());out=pathlib.Path('prisma-publish');tag='prisma-v'+info['versionName']
 remote=api('contents/PrismaPDF/update.json?ref=main');current=json.loads(base64.b64decode(remote['content']));assert current['packageName']==info['packageName'];assert current['versionCode']<=info['versionCode'],'Canal contém versão superior'
 release=subprocess.run(['gh','release','view',tag,'--repo',REPO,'--json','isDraft'],capture_output=True,text=True)
 if release.returncode:
  import os
  subprocess.run(['gh','release','create',tag,str(out/'Prisma-PDF.apk'),str(out/'update.json'),str(out/'SHA256SUMS.txt'),'--repo',REPO,'--target',os.environ['GITHUB_SHA'],'--title','Prisma PDF '+info['versionName'],'--notes-file',str(out/'notes.txt'),'--latest=false','--draft'],check=True)
  subprocess.run(['gh','release','edit',tag,'--repo',REPO,'--draft=false','--latest=false'],check=True)
 else:assert not json.loads(release.stdout)['isDraft'],'Existe um rascunho; confira os arquivos antes de publicar'
 check=out/'download-check';check.mkdir(exist_ok=True)
 subprocess.run(['gh','release','download',tag,'--repo',REPO,'--pattern','Prisma-PDF.apk','--dir',str(check),'--clobber'],check=True)
 assert hashlib.sha256((check/'Prisma-PDF.apk').read_bytes()).hexdigest()==info['sha256'],'Download publicado divergente'
 if current['versionCode']==info['versionCode'] and current.get('downloadAvailable'):
  assert current.get('sha256')==info['sha256'] and current.get('downloadUrl')==info['downloadUrl'];print('Canal já atualizado.');return
 api('contents/PrismaPDF/update.json','PUT',{'message':'Ativar download Prisma PDF '+info['versionName'],'branch':'main','sha':remote['sha'],'content':base64.b64encode((out/'update.json').read_bytes()).decode()})
 print('Download publicado e canal atualizado após conferir o arquivo remoto.')
if __name__=='__main__':
 if sys.argv[1]=='prepare':prepare()
 elif sys.argv[1]=='publish':publish()
 else:raise SystemExit('Use prepare ou publish')
