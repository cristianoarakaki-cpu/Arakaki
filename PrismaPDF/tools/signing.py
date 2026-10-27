"""Create once, encrypt and persist a signing key; decrypt on subsequent builds."""
import base64,hashlib,json,os,pathlib,re,subprocess,sys
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.scrypt import Scrypt
REPO='cristianoarakaki-cpu/Arakaki';PREFIX='PrismaPDF/signing';AAD=b'Prisma PDF signing key v1'
def encrypt(data,password):
 salt=os.urandom(16);nonce=os.urandom(12);key=Scrypt(salt=salt,length=32,n=32768,r=8,p=1).derive(password.encode())
 return {'format':1,'salt':base64.b64encode(salt).decode(),'nonce':base64.b64encode(nonce).decode(),'ciphertext':base64.b64encode(AESGCM(key).encrypt(nonce,data,AAD)).decode()}
def decrypt(bundle,password):
 if bundle.get('format')!=1:raise ValueError('Formato de chave desconhecido')
 salt=base64.b64decode(bundle['salt'],validate=True);nonce=base64.b64decode(bundle['nonce'],validate=True)
 if len(salt)!=16 or len(nonce)!=12:raise ValueError('Envelope de chave inválido')
 key=Scrypt(salt=salt,length=32,n=32768,r=8,p=1).derive(password.encode())
 return AESGCM(key).decrypt(nonce,base64.b64decode(bundle['ciphertext'],validate=True),AAD)
def api(path,method='GET',data=None):
 cmd=['gh','api','--method',method,'repos/'+REPO+'/'+path]
 if data is not None:cmd+=['--input','-']
 r=subprocess.run(cmd,input=None if data is None else json.dumps(data).encode(),capture_output=True)
 if r.returncode:raise RuntimeError('Falha ao acessar '+path+'; nenhuma chave privada será exibida.')
 return json.loads(r.stdout) if r.stdout.strip() else {}
def get_optional(path):
 # Use the API status; a permission or network error must never be mistaken for an absent key.
 r=subprocess.run(['gh','api','--include','repos/'+REPO+'/contents/'+path+'?ref=main'],capture_output=True)
 if r.returncode:
  if b'HTTP 404' in r.stderr or re.search(rb'HTTP/\S+ 404',r.stdout):return None
  raise RuntimeError('Não foi possível verificar a chave persistida no GitHub.')
 raw=r.stdout.split(b'\r\n\r\n',1)
 if len(raw)!=2:raw=r.stdout.split(b'\n\n',1)
 info=json.loads(raw[-1]);return base64.b64decode(info['content'])
def certificate(keyfile):
 r=subprocess.run(['keytool','-exportcert','-keystore',str(keyfile),'-alias','prisma-pdf','-storepass:env','PRISMA_SIGNING_PASSWORD'],capture_output=True)
 if r.returncode:raise RuntimeError('Não foi possível abrir a chave. Confira o secret; não será criada outra chave.')
 return hashlib.sha256(r.stdout).hexdigest()
def persist(bundle,cert,expected_head):
 head=api('git/ref/heads/main')['object']['sha']
 if head!=expected_head:raise RuntimeError('A branch avançou. Execute novamente no commit atual antes de iniciar a identidade definitiva.')
 commit=api('git/commits/'+head)
 tree=api('git/trees','POST',{'base_tree':commit['tree']['sha'],'tree':[{'path':PREFIX+'/key.enc.json','mode':'100644','type':'blob','content':json.dumps(bundle,indent=2)+'\n'},{'path':PREFIX+'/certificate.sha256','mode':'100644','type':'blob','content':cert+'\n'}]})
 created=api('git/commits','POST',{'message':'Persistir chave de assinatura definitiva criptografada','tree':tree['sha'],'parents':[head]})
 api('git/refs/heads/main','PATCH',{'sha':created['sha'],'force':False})
 return created['sha']
def main():
 password=os.environ.get('PRISMA_SIGNING_PASSWORD','')
 if len(password)<24 or not password.isascii():raise SystemExit('Cadastre PRISMA_SIGNING_PASSWORD com ao menos 24 caracteres ASCII e guarde uma cópia privada.')
 root=pathlib.Path('PrismaPDF');keyfile=pathlib.Path(os.environ['RUNNER_TEMP'])/'prisma-signing.p12'
 keyfile.parent.mkdir(parents=True,exist_ok=True)
 encrypted=get_optional(PREFIX+'/key.enc.json');certdata=get_optional(PREFIX+'/certificate.sha256');head=os.environ['GITHUB_SHA']
 try:
  if encrypted is None and certdata is None:
   channel=get_optional('PrismaPDF/update.json')
   if channel and json.loads(channel).get('downloadAvailable'):raise RuntimeError('Já existe uma edição publicada sem a chave persistida. Restaure a chave criptografada; não será criada outra.')
   if keyfile.exists():keyfile.unlink()
   subprocess.run(['keytool','-genkeypair','-storetype','PKCS12','-keystore',str(keyfile),'-storepass:env','PRISMA_SIGNING_PASSWORD','-keypass:env','PRISMA_SIGNING_PASSWORD','-alias','prisma-pdf','-keyalg','RSA','-keysize','3072','-validity','10000','-dname','CN=Prisma PDF'],check=True,capture_output=True)
   keyfile.chmod(0o600);cert=certificate(keyfile);bundle=encrypt(keyfile.read_bytes(),password)
   head=persist(bundle,cert,head)
   encrypted=json.dumps(bundle).encode();certdata=(cert+'\n').encode()
  elif encrypted is None or certdata is None:raise RuntimeError('Backup de assinatura incompleto; nenhuma chave nova será criada.')
  else:
   try:data=decrypt(json.loads(encrypted),password)
   except Exception:raise RuntimeError('A senha não abre a chave persistida. Restaure o secret correto; não será criada outra chave.') from None
   keyfile.write_bytes(data);keyfile.chmod(0o600)
   if certificate(keyfile)!=certdata.decode().strip():raise RuntimeError('O certificado não corresponde ao backup persistido.')
  path=root/'signing';path.mkdir(exist_ok=True);(path/'key.enc.json').write_bytes(encrypted);(path/'certificate.sha256').write_bytes(certdata)
  with open(os.environ['GITHUB_ENV'],'a') as f:f.write('PRISMA_KEYSTORE='+str(keyfile)+'\nPRISMA_RELEASE_COMMIT='+head+'\n')
  print('Assinatura permanente preparada; backup criptografado conferido.')
 except Exception:
  keyfile.unlink(missing_ok=True);raise
if __name__=='__main__':
 try:main()
 except Exception as e:raise SystemExit(str(e))
