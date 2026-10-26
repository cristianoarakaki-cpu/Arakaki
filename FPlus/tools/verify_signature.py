import json,pathlib,re,subprocess,sys
info=json.loads(pathlib.Path('FPlus/release.json').read_text())
signer,aapt=sys.argv[1:]
text=subprocess.check_output([signer,'verify','--verbose','--print-certs','release-output/Folha-PDF.apk'],text=True)
print(text)
certs={value.replace(':','').lower() for value in re.findall(r'certificate SHA-256 digest:\s*([a-fA-F0-9:]+)',text)}
assert certs=={info['certificateSha256']},'Certificado diferente do aplicativo original: '+repr(sorted(certs))
text=subprocess.check_output([aapt,'dump','badging','release-output/Folha-PDF.apk'],text=True)
p=re.search(r"package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'",text)
assert p and p[1]==info['packageName'] and int(p[2])==info['versionCode'] and p[3]==info['versionName'],'Versão ou pacote divergente'
print('Assinatura, certificado, pacote e versão conferidos')
