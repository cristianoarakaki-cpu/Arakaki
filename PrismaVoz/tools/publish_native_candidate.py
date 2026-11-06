"""Publish the genuine native implementation as a prerelease, never bypass checks."""
import hashlib,json,os,pathlib,subprocess
repo='cristianoarakaki-cpu/Arakaki';root=pathlib.Path('PrismaVoz');info=json.loads((root/'distribution/release.json').read_text());assert info.get('architecture')=='native'
out=pathlib.Path('prismavoz-publish');apk=out/'Prisma-Voz.apk';assert hashlib.sha256(apk.read_bytes()).hexdigest()==info['sha256'];tag='prismavoz-v'+info['versionName']
existing=subprocess.run(['gh','release','view',tag,'--repo',repo],capture_output=True)
if existing.returncode:
 notes=out/'native-notes.txt';notes.write_text(info['notes']+'\n\nAPK Android nativo com mesma identidade e assinatura. Não abre navegador nem WebView para ler PDFs. Candidato testado em Android; isso não constitui liberação pelo Google Play Protect. Se houver alerta, não force instalação. O canal automático não é ativado por este workflow.\n')
 subprocess.run(['gh','release','create',tag,str(apk),str(out/'SHA256SUMS.txt'),'--repo',repo,'--target',os.environ['GITHUB_SHA'],'--title','Prisma Voz '+info['versionName']+' — Android nativo','--notes-file',str(notes),'--prerelease','--latest=false'],check=True)
check=out/'native-download-check';check.mkdir(exist_ok=True);subprocess.run(['gh','release','download',tag,'--repo',repo,'--pattern','Prisma-Voz.apk','--dir',str(check),'--clobber'],check=True);assert hashlib.sha256((check/'Prisma-Voz.apk').read_bytes()).hexdigest()==info['sha256'];print('Candidato nativo publicado e download conferido. Canal automático preservado.')
