"""Prepare release metadata locally; never commits private signing material."""
import hashlib,json,pathlib
root=pathlib.Path('FPlus');v=json.loads((root/'source/version.json').read_text());channel=json.loads((root/'update.json').read_text())
assert v['versionCode']>channel['versionCode'],'Aumente versionCode antes de publicar uma atualização'
cert=(root/'signing-certificate.sha256').read_text().strip();data=(root/'source/build/Folha-PDF.apk').read_bytes()
info={'packageName':'com.folha.pd2','versionCode':v['versionCode'],'versionName':v['versionName'],'downloadUrl':f"https://github.com/cristianoarakaki-cpu/Arakaki/releases/download/folha-vplus{v['versionName']}/Folha-PDF.apk",'sha256':hashlib.sha256(data).hexdigest(),'certificateSha256':cert,'notes':v['notes'],'size':len(data)}
(root/'release.json').write_text(json.dumps(info,ensure_ascii=False,indent=2)+'\n')
out=pathlib.Path('release-output');out.mkdir(exist_ok=True);(out/'Folha-PDF.apk').write_bytes(data)
manifest={k:info[k] for k in ['packageName','versionCode','versionName','downloadUrl','sha256','notes']};manifest['downloadAvailable']=True
(out/'folha-update.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
(out/'SHA256SUMS.txt').write_text(info['sha256']+'  Folha-PDF.apk\n');(out/'tag.txt').write_text('folha-vplus'+info['versionName'])
(out/'notes.txt').write_text(v['notes']+'\n\nInstale sem desinstalar a versão anterior. A assinatura original foi conferida. O Android solicita confirmação.\n')
