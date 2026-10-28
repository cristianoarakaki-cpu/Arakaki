"""Sign in the private execution workspace; never uploads the signing material."""
import argparse,hashlib,json,os,pathlib,re,subprocess

def main():
 p=argparse.ArgumentParser(description='Assinar o Prisma com a identidade privada existente, sem pedir senha ao usuário.')
 p.add_argument('--input',type=pathlib.Path,required=True);p.add_argument('--output',type=pathlib.Path,required=True)
 p.add_argument('--tools',type=pathlib.Path,default=pathlib.Path('/workspace/prisma-tools'))
 p.add_argument('--private-directory',type=pathlib.Path,default=pathlib.Path('/workspace/.prisma-signing/active'))
 args=p.parse_args();statefile=args.private_directory/'credentials.json';keystore=args.private_directory/'private.p12'
 if not statefile.is_file() or not keystore.is_file():raise SystemExit('A chave privada existente não está disponível. Restaure o armazenamento privado; não gere outra chave para o app instalado.')
 state=json.loads(statefile.read_text());env=os.environ.copy();env['PRISMA_LOCAL_STORE_PASSWORD']=state['password']
 root=pathlib.Path(__file__).resolve().parents[1];expected=(root/'signing/certificate.sha256').read_text().strip()
 cert=subprocess.run(['keytool','-exportcert','-keystore',str(keystore),'-alias',state['alias'],'-storepass:env','PRISMA_LOCAL_STORE_PASSWORD'],env=env,capture_output=True)
 if cert.returncode or hashlib.sha256(cert.stdout).hexdigest()!=expected:raise SystemExit('A chave não corresponde à identidade publicada do Prisma.')
 jar=args.tools/'apksigner.jar';args.output.parent.mkdir(parents=True,exist_ok=True)
 result=subprocess.run(['java','-jar',str(jar),'sign','--ks',str(keystore),'--ks-key-alias',state['alias'],'--ks-pass','env:PRISMA_LOCAL_STORE_PASSWORD','--key-pass','env:PRISMA_LOCAL_STORE_PASSWORD','--out',str(args.output),str(args.input)],env=env,capture_output=True)
 if result.returncode:raise SystemExit('Falha ao assinar; nenhum segredo será exibido.')
 result=subprocess.run(['java','-jar',str(jar),'verify','--verbose','--print-certs',str(args.output)],capture_output=True,text=True)
 certs={c.replace(':','').lower() for c in re.findall(r'certificate SHA-256 digest:\s*([a-fA-F0-9:]+)',result.stdout)}
 if result.returncode or certs!={expected}:raise SystemExit('O APK não passou na verificação da assinatura.')
 subprocess.run([str(args.tools/'zipalign'),'-c','4',str(args.output)],check=True)
 print('APK assinado e conferido. SHA-256:',hashlib.sha256(args.output.read_bytes()).hexdigest())
if __name__=='__main__':main()
