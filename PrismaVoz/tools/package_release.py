"""Package only a verified signed APK for the existing Actions publication model."""
import argparse,hashlib,json,pathlib,re,subprocess
p=argparse.ArgumentParser();p.add_argument('--tools',type=pathlib.Path,required=True);a=p.parse_args();root=pathlib.Path('PrismaVoz');apk=root/'build/Prisma-Voz.apk';version=json.loads((root/'version.json').read_text());certificate=(root/'signing/certificate.sha256').read_text().strip()
verified=subprocess.check_output([str(a.tools/'apksigner'),'verify','--print-certs',str(apk)],text=True)
assert set(re.findall(r'certificate SHA-256 digest:\s*([a-fA-F0-9]+)',verified))=={certificate}
subprocess.run([str(a.tools/'zipalign'),'-c','4',str(apk)],check=True)
badging=subprocess.check_output([str(a.tools/'aapt'),'dump','badging',str(apk)],text=True);match=re.search(r"package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'",badging)
assert match and match[1]=='com.arakaki.prismavoz' and int(match[2])==version['versionCode'] and match[3]==version['versionName']
data=apk.read_bytes();out=root/'distribution';out.mkdir(exist_ok=True);parts=[]
for old in out.glob('Prisma-Voz.apk.part*'):old.unlink()
for i,start in enumerate(range(0,len(data),524288)):
 content=data[start:start+524288];name=f'Prisma-Voz.apk.part{i:03d}';(out/name).write_bytes(content);parts.append({'name':name,'size':len(content),'sha256':hashlib.sha256(content).hexdigest()})
info={'packageName':'com.arakaki.prismavoz',**version,'sha256':hashlib.sha256(data).hexdigest(),'size':len(data),'certificateSha256':certificate,'downloadUrl':f"https://github.com/cristianoarakaki-cpu/Arakaki/releases/download/prismavoz-v{version['versionName']}/Prisma-Voz.apk"}
(out/'parts.json').write_text(json.dumps(parts,indent=2)+'\n');(out/'release.json').write_text(json.dumps(info,ensure_ascii=False,indent=2)+'\n')
channel={key:info[key] for key in ['packageName','versionCode','versionName','downloadUrl','sha256','notes']};channel['downloadAvailable']=False
if not (root/'update.json').exists():(root/'update.json').write_text(json.dumps(channel,ensure_ascii=False,indent=2)+'\n')
print('Partes, identidade e metadados preparados; o canal só é ativado após conferir o download publicado.')

source={p.as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in root.rglob('*') if p.is_file() and ((p.suffix=='.java' and (root/'src') in p.parents) or (p.parent==root/'assets' and p.suffix in {'.js','.css','.html'}) or p in [root/'AndroidManifest.xml',root/'version.json',root/'build.sh',root/'dependencies/manifest.json'])}
(out/'source-sha256.json').write_text(json.dumps(source,indent=2,sort_keys=True)+'\n')
