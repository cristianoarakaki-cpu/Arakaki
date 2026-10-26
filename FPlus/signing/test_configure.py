import contextlib,hashlib,importlib.util,io,pathlib,subprocess,sys,tempfile,unittest
from unittest.mock import patch
spec=importlib.util.spec_from_file_location('configure',pathlib.Path(__file__).with_name('configure.py'));module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
class SigningTests(unittest.TestCase):
 def invoke(self,check_only=False,wrong_certificate=False,wrong_private_password=False):
  calls=[];certificate=b'public certificate for test';secret=b'private key bytes for test'
  def run(args,**kwargs):
   calls.append((args,kwargs))
   code=1 if args[0]=='jarsigner' and wrong_private_password else 0
   out=certificate if args[0]=='keytool' else 'cristianoarakaki-cpu\n' if args[:3]==['gh','api','user'] else b''
   return subprocess.CompletedProcess(args,code,stdout=out,stderr=b'')
  with tempfile.TemporaryDirectory() as d:
   key=pathlib.Path(d)/'test.jks';key.write_bytes(secret)
   argv=['configure.py','--keystore',str(key),'--alias','original']+(['--check-only'] if check_only else [])
   expected='0'*64 if wrong_certificate else hashlib.sha256(certificate).hexdigest()
   with patch.object(sys,'argv',argv),patch.object(module,'EXPECTED',expected),patch.object(module.shutil,'which',return_value='/bin/tool'),patch.object(module.subprocess,'run',side_effect=run),patch.object(module.getpass,'getpass',side_effect=['store-password','key-password']),patch('builtins.input',return_value='CONFIGURAR'),contextlib.redirect_stdout(io.StringIO()):
    try:module.main();error=None
    except SystemExit as e:error=e
  return error,calls
 def test_wrong_certificate_never_writes_secrets(self):
  error,calls=self.invoke(wrong_certificate=True);self.assertIsNotNone(error);self.assertFalse(any(c[0][0]=='gh' for c in calls))
 def test_check_only_never_uses_gh(self):
  error,calls=self.invoke(check_only=True);self.assertIsNone(error);self.assertEqual(len(calls),1)
 def test_wrong_private_password_never_writes(self):
  error,calls=self.invoke(wrong_private_password=True);self.assertIsNotNone(error);self.assertFalse(any(c[0][0]=='gh' for c in calls))
 def test_success_sends_secrets_over_stdin(self):
  error,calls=self.invoke();self.assertIsNone(error)
  writes=[c for c in calls if c[0][:3]==['gh','secret','set']];self.assertEqual(len(writes),4)
  for args,kwargs in writes:
   self.assertIn('input',kwargs);self.assertNotIn('store-password',repr(args));self.assertNotIn('key-password',repr(args))
if __name__=='__main__':unittest.main()
