"""Configure original signing secrets from the owner's trusted computer.
Never prints passwords, private key bytes or base64. Requires keytool and gh.
"""
import argparse,base64,getpass,hashlib,os,pathlib,shutil,subprocess,sys
REPO='cristianoarakaki-cpu/Arakaki'
EXPECTED='261f78cf56ce24cf0589f5f718bd19c38a7ac4016af43bc6b03841199bcde8ce'
def main():
 p=argparse.ArgumentParser(description='Verificar a chave original e configurar assinatura permanente do Folha PDF+.')
 p.add_argument('--keystore',required=True,type=pathlib.Path)
 p.add_argument('--alias',required=True)
 p.add_argument('--check-only',action='store_true',help='Só conferir o certificado; não alterar secrets.')
 args=p.parse_args()
 if not args.keystore.is_file():p.error('Arquivo de chave não encontrado.')
 if not shutil.which('keytool') or not shutil.which('jarsigner'):p.error('Instale um JDK que forneça keytool.')
 if not args.check_only and not shutil.which('gh'):p.error('Instale o GitHub CLI e autentique a conta proprietária.')
 password=getpass.getpass('Senha do keystore (não será exibida): ')
 env=os.environ.copy();env['FPLUS_LOCAL_STORE_PASSWORD']=password
 result=subprocess.run(['keytool','-exportcert','-keystore',str(args.keystore),'-alias',args.alias,'-storepass:env','FPLUS_LOCAL_STORE_PASSWORD'],env=env,capture_output=True)
 if result.returncode:raise SystemExit('Não foi possível ler o certificado: confira arquivo, alias e senha.')
 fingerprint=hashlib.sha256(result.stdout).hexdigest()
 if fingerprint!=EXPECTED:raise SystemExit('Esta chave não corresponde ao Folha PDF+ 1.9.3 original. Nenhum secret foi alterado.')
 print('Certificado original confirmado.')
 if args.check_only:return
 key_password=getpass.getpass('Senha da chave (Enter se igual à do keystore): ') or password
 # Confirm the key password by signing a throwaway JAR, not merely exporting its public certificate.
 import tempfile,zipfile
 with tempfile.TemporaryDirectory(prefix='folha-signing-check-') as tmp:
  jar=pathlib.Path(tmp)/'check.jar'
  with zipfile.ZipFile(jar,'w') as z:z.writestr('verification.txt','Folha PDF signing access verification')
  env['FPLUS_LOCAL_KEY_PASSWORD']=key_password
  verified=subprocess.run(['jarsigner','-keystore',str(args.keystore),'-storepass:env','FPLUS_LOCAL_STORE_PASSWORD','-keypass:env','FPLUS_LOCAL_KEY_PASSWORD',str(jar),args.alias],env=env,capture_output=True)
  if verified.returncode:raise SystemExit('Não foi possível usar a chave privada. Confira a senha da chave. Nenhum secret foi alterado.')
 if subprocess.run(['gh','auth','status'],capture_output=True).returncode:raise SystemExit('Autentique o GitHub CLI com gh auth login e execute novamente.')
 login=subprocess.run(['gh','api','user','--jq','.login'],capture_output=True,text=True)
 if login.returncode or login.stdout.strip()!='cristianoarakaki-cpu':raise SystemExit('Use a conta GitHub cristianoarakaki-cpu para configurar este repositório.')
 values={'FPLUS_KEYSTORE_BASE64':base64.b64encode(args.keystore.read_bytes()),'FPLUS_STORE_PASSWORD':password.encode(),'FPLUS_KEY_PASSWORD':key_password.encode(),'FPLUS_KEY_ALIAS':args.alias.encode()}
 # Key first: a partial failure cannot combine a newly supplied password with a different old key.
 for name,value in values.items():
  result=subprocess.run(['gh','secret','set',name,'--repo',REPO],input=value,capture_output=True)
  if result.returncode:raise SystemExit('Falha ao gravar '+name+'. A operação pode ter gravado alguns secrets. Execute novamente; valores não serão exibidos.')
 print('Assinatura configurada nos quatro secrets. Guarde uma cópia privada do keystore e suas senhas.')
 print('A próxima compilação oficial verificará novamente certificado, pacote e versão antes de publicar.')
if __name__=='__main__':main()
