"""Own permanent signing identity for Prisma Voz; never reuses Prisma PDF keys."""
import argparse,hashlib,json,os,pathlib,secrets,subprocess
p=argparse.ArgumentParser();p.add_argument('--tools',type=pathlib.Path,required=True);p.add_argument('--private-directory',type=pathlib.Path,default=pathlib.Path('/workspace/.prismavoz-signing/active'));p.add_argument('--input',type=pathlib.Path,required=True);p.add_argument('--output',type=pathlib.Path,required=True);a=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[1];pin=root/'signing/certificate.sha256';private=a.private_directory
private.mkdir(parents=True,exist_ok=True,mode=0o700);private.chmod(0o700);key=private/'private.p12';credentials=private/'credentials.json'
if key.exists()!=credentials.exists():raise SystemExit('Assinatura incompleta. Restaure a identidade privada antes de continuar.')
if not key.exists():
 if pin.exists():raise SystemExit('Já existe certificado publicado. Restaure a chave privada; não crie outra identidade.')
 secret=secrets.token_urlsafe(48);env=os.environ.copy();env['PRISMAVOZ_STORE_PASSWORD']=secret
 result=subprocess.run(['keytool','-genkeypair','-keystore',str(key),'-storetype','PKCS12','-storepass:env','PRISMAVOZ_STORE_PASSWORD','-keypass:env','PRISMAVOZ_STORE_PASSWORD','-alias','prismavoz','-dname','CN=Prisma Voz,O=Arakaki,C=BR','-keyalg','RSA','-keysize','3072','-validity','10000'],env=env,capture_output=True)
 if result.returncode:raise SystemExit('Não foi possível criar a identidade privada do novo aplicativo.')
 key.chmod(0o600);fd=os.open(credentials,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
 with os.fdopen(fd,'w') as f:json.dump({'alias':'prismavoz','password':secret},f)
state=json.loads(credentials.read_text());env=os.environ.copy();env['PRISMAVOZ_STORE_PASSWORD']=state['password']
cert=subprocess.run(['keytool','-exportcert','-keystore',str(key),'-storepass:env','PRISMAVOZ_STORE_PASSWORD','-alias',state['alias']],env=env,capture_output=True)
if cert.returncode:raise SystemExit('Não foi possível conferir o certificado da chave privada.')
actual=hashlib.sha256(cert.stdout).hexdigest()
if pin.exists() and pin.read_text().strip()!=actual:raise SystemExit('A chave não corresponde à assinatura fixada do Prisma Voz.')
pin.parent.mkdir(exist_ok=True);pin.write_text(actual+'\n')
a.output.parent.mkdir(parents=True,exist_ok=True)
result=subprocess.run([str(a.tools/'apksigner'),'sign','--ks',str(key),'--ks-key-alias',state['alias'],'--ks-pass','env:PRISMAVOZ_STORE_PASSWORD','--key-pass','env:PRISMAVOZ_STORE_PASSWORD','--out',str(a.output),str(a.input)],env=env,capture_output=True)
if result.returncode:raise SystemExit('Falha ao assinar o APK. Nenhum segredo será exibido.')
subprocess.run([str(a.tools/'apksigner'),'verify','--verbose',str(a.output)],check=True)
subprocess.run([str(a.tools/'zipalign'),'-c','4',str(a.output)],check=True)
print('Prisma Voz assinado com identidade própria. Certificado público SHA-256:',actual)
