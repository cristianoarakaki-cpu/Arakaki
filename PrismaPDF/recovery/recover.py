"""Recover metadata for an already signed upload; never signs or changes the APK."""
import base64,hashlib,json,pathlib,subprocess,sys
ROOT=pathlib.Path('PrismaPDF');REPO='cristianoarakaki-cpu/Arakaki'
def api(path,method='GET',data=None):
 p=subprocess.run(['gh','api','--method',method,'repos/'+REPO+'/'+path]+(['--input','-'] if data is not None else []),input=None if data is None else json.dumps(data).encode(),capture_output=True)
 if p.returncode:raise RuntimeError('Falha na recuperação: '+path)
 return json.loads(p.stdout) if p.stdout.strip() else {}
def prepare():
 recovery=json.loads((ROOT/'recovery/release-1.10.0.json').read_text());info=recovery['release']
 current=json.loads((ROOT/'distribution/release.json').read_text())
 if current['versionCode']>info['versionCode']:return
 if current['versionCode']==info['versionCode']:
  assert current['sha256']==info['sha256'];return
 assert info['certificateSha256']==(ROOT/'signing/certificate.sha256').read_text().strip()
 parts=[];whole=hashlib.sha256();total=0
 for i,item in enumerate(recovery['chunks']):
  name=item['name'];assert name==f'Prisma-PDF.apk.part{i:03d}'
  data=(ROOT/'distribution'/name).read_bytes()
  assert hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()==item['gitSha'],'Git blob divergente'
  parts.append(dict(name=name,size=len(data),sha256=hashlib.sha256(data).hexdigest()));whole.update(data);total+=len(data)
 assert total==info['size'] and whole.hexdigest()==info['sha256'],'APK diferente do pacote assinado e conferido'
 (ROOT/'distribution/parts.json').write_text(json.dumps(parts,indent=2)+'\n')
 (ROOT/'distribution/release.json').write_text(json.dumps(info,ensure_ascii=False,indent=2)+'\n')
 print('Metadados recuperados; bytes conferidos pelo hash completo previamente registrado.')
def persist():
 # Called only AFTER the standard certificate, package, version, zipalign and full APK checks.
 parent=api('git/refs/heads/main')['object']['sha'];commit=api('git/commits/'+parent);entries=[]
 for name in ['parts.json','release.json']:
  path='PrismaPDF/distribution/'+name;data=(ROOT/'distribution'/name).read_bytes();remote=api('contents/'+path+'?ref='+parent)
  if base64.b64decode(remote['content'])==data:continue
  # Never replace a distribution from a newer release.
  if name=='release.json':
   current=json.loads(base64.b64decode(remote['content']));new=json.loads(data)
   assert current['versionCode']<=new['versionCode'],'Distribuição mais recente no repositório'
   if current['versionCode']==new['versionCode']:assert current['sha256']==new['sha256']
  blob=api('git/blobs','POST',dict(content=base64.b64encode(data).decode(),encoding='base64'))
  entries.append(dict(path=path,mode='100644',type='blob',sha=blob['sha']))
 if not entries:return
 tree=api('git/trees','POST',dict(base_tree=commit['tree']['sha'],tree=entries))
 new=api('git/commits','POST',dict(message='Recuperar metadados do APK Prisma assinado após interrupção do ambiente',tree=tree['sha'],parents=[parent]))
 api('git/refs/heads/main','PATCH',dict(sha=new['sha'],force=False))
 print('Metadados persistidos por commit atômico sem substituir alterações concorrentes.')
if __name__=='__main__':
 if sys.argv[1]=='prepare':prepare()
 elif sys.argv[1]=='persist':persist()
 else:raise SystemExit('Use prepare ou persist')
