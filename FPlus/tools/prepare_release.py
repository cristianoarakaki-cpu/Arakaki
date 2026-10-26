"""Validate distribution before publishing; called from repository root."""
import hashlib,json,pathlib,re,sys,zipfile
root=pathlib.Path('FPlus');info=json.loads((root/'release.json').read_text());parts=json.loads((root/'distribution/parts.json').read_text())
assert info['packageName']=='com.folha.pd2','Pacote incorreto'
assert type(info['versionCode']) is int and info['versionCode']>=15
assert re.fullmatch(r'\d+\.\d+\.\d+',info['versionName'])
assert re.fullmatch(r'[a-f0-9]{64}',info['sha256'])
assert info['certificateSha256']==(root/'signing-certificate.sha256').read_text().strip()
tag='folha-vplus'+info['versionName'];url=f'https://github.com/cristianoarakaki-cpu/Arakaki/releases/download/{tag}/Folha-PDF.apk'
assert info['downloadUrl']==url,'URL incompatível com atualizador instalado'
assert parts and len(parts)<=300
chunks=[]
for i,p in enumerate(parts):
 assert p['name']==f'Folha-PDF.apk.part{i:03d}'
 b=(root/'distribution'/p['name']).read_bytes()
 assert len(b)==p['size'] and hashlib.sha256(b).hexdigest()==p['sha256'],'Parte divergente'
 chunks.append(b)
data=b''.join(chunks)
assert len(data)==info['size'] and hashlib.sha256(data).hexdigest()==info['sha256'],'APK divergente'
assert 0<len(data)<=150*1024*1024
out=pathlib.Path('release-output');out.mkdir(exist_ok=True);(out/'Folha-PDF.apk').write_bytes(data)
with zipfile.ZipFile(out/'Folha-PDF.apk') as z:
 assert z.testzip() is None
 assert all(n in z.namelist() for n in ['classes.dex','AndroidManifest.xml','assets/index.html','assets/vendor/lang/por.traineddata.gz'])
manifest={k:info[k] for k in ['packageName','versionCode','versionName','downloadUrl','sha256','notes']};manifest['downloadAvailable']=True
(out/'folha-update.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
(out/'SHA256SUMS.txt').write_text(info['sha256']+'  Folha-PDF.apk\n')
(out/'notes.txt').write_text(info['notes']+'\n\nInstale sobre a versão anterior sem desinstalar. O Android solicita confirmação. Funções de PDF e OCR permanecem offline; consultas de atualização precisam de internet.\n')
(out/'tag.txt').write_text(tag)
print('APK reconstituído e SHA-256 conferido:',info['versionName'])
