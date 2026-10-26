import json,pathlib,re,subprocess,sys
info=json.loads(pathlib.Path('FPlus/release.json').read_text())
signer,aapt=sys.argv[1:]
text=subprocess.check_output([signer,'verify','--verbose','--print-certs','release-output/Folha-PDF.apk'],text=True)
certs=re.findall(r'Signer #\d+ certificate SHA-256 digest: ([a-fA-F0-9]+)',text)
assert len(certs)==1 and certs[0].lower()==info['certificateSha256'],'Certificado diferente do aplicativo original'
text=subprocess.check_output([aapt,'dump','badging','release-output/Folha-PDF.apk'],text=True)
p=re.search(r"package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'",text)
assert p and p[1]==info['packageName'] and int(p[2])==info['versionCode'] and p[3]==info['versionName'],'Versão ou pacote divergente'
print('Assinatura, certificado, pacote e versão conferidos')
