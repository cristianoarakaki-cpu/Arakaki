import base64,contextlib,io,json,os,pathlib,subprocess,tempfile,unittest
from unittest.mock import patch
from cryptography.exceptions import InvalidTag
import signing
class SigningTests(unittest.TestCase):
 def test_roundtrip_preserves_key(self):
  data=os.urandom(128);password='a-random-test-passphrase-12345';bundle=signing.encrypt(data,password)
  self.assertEqual(signing.decrypt(bundle,password),data)
  self.assertNotIn(base64.b64encode(data).decode(),json.dumps(bundle))
 def test_wrong_password_rejected(self):
  bundle=signing.encrypt(b'private-key','a-test-password-1234567890')
  with self.assertRaises(InvalidTag):signing.decrypt(bundle,'a-different-password-123456')
 def test_ciphertext_tampering_rejected(self):
  bundle=signing.encrypt(b'private-key','a-test-password-1234567890');raw=bytearray(base64.b64decode(bundle['ciphertext']));raw[0]^=1;bundle['ciphertext']=base64.b64encode(raw).decode()
  with self.assertRaises(InvalidTag):signing.decrypt(bundle,'a-test-password-1234567890')
 def test_network_error_is_not_missing_key(self):
  with patch.object(signing.subprocess,'run',return_value=subprocess.CompletedProcess([],1,stdout=b'',stderr=b'HTTP 403')):
   with self.assertRaises(RuntimeError):signing.get_optional('key.enc.json')
 def test_incomplete_backup_never_generates_key(self):
  with tempfile.TemporaryDirectory() as temp,patch.dict(os.environ,{'RUNNER_TEMP':temp,'GITHUB_SHA':'a'*40,'PRISMA_SIGNING_PASSWORD':'a-valid-test-password-1234567890'}),patch.object(signing,'get_optional',side_effect=[b'{}',None]),patch.object(signing.subprocess,'run') as run:
   with self.assertRaises(RuntimeError):signing.main()
   run.assert_not_called()
 def test_wrong_secret_never_generates_key(self):
  encrypted=json.dumps(signing.encrypt(b'private-key','a-valid-test-password-1234567890')).encode()
  with tempfile.TemporaryDirectory() as temp,patch.dict(os.environ,{'RUNNER_TEMP':temp,'GITHUB_SHA':'a'*40,'PRISMA_SIGNING_PASSWORD':'a-different-password-1234567890'}),patch.object(signing,'get_optional',side_effect=[encrypted,b'0'*64]),patch.object(signing.subprocess,'run') as run:
   with self.assertRaises(RuntimeError):signing.main()
   run.assert_not_called()
 def test_real_keystore_is_reused_across_runs(self):
  import shutil
  if not shutil.which('keytool'):self.skipTest('keytool não instalado')
  with tempfile.TemporaryDirectory() as folder:
   previous=os.getcwd();root=pathlib.Path(folder);(root/'PrismaPDF').mkdir();saved={}
   def persist(bundle,cert,head):
    saved['bundle']=json.dumps(bundle).encode();saved['cert']=(cert+'\n').encode();return head
   def get(path):
    if path.endswith('key.enc.json'):return saved.get('bundle')
    if path.endswith('certificate.sha256'):return saved.get('cert')
    return json.dumps({'downloadAvailable':False}).encode()
   try:
    os.chdir(root)
    with patch.dict(os.environ,{'RUNNER_TEMP':str(root),'GITHUB_SHA':'a'*40,'GITHUB_ENV':str(root/'env.txt'),'PRISMA_SIGNING_PASSWORD':'local-integration-test-only-1234567890'}),patch.object(signing,'get_optional',side_effect=get),patch.object(signing,'persist',side_effect=persist),contextlib.redirect_stdout(io.StringIO()):
     signing.main();key=root/'prisma-signing.p12';first=key.read_bytes();key.unlink();signing.main();self.assertEqual(first,key.read_bytes())
   finally:os.chdir(previous)
if __name__=='__main__':unittest.main()
