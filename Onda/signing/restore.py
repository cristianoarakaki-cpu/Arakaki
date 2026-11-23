"""Restore the pinned keystore from authenticated ciphertext; no signing-key cache is used."""
import base64
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

root = Path(__file__).resolve().parents[1]
def restore():
    password = os.environ.get('ONDA_SIGNING_PASSPHRASE', '')
    if not password:
        raise RuntimeError('Configure the private ONDA_SIGNING_PASSPHRASE repository secret. Never generate a replacement signing key.')
    data = json.loads((root / 'signing/keystore.enc.json').read_text())
    expected = (root / 'signing-certificate.sha256').read_text().strip()
    assert data['version'] == 1 and data['packageName'] == 'br.com.onda.player'
    assert data['algorithm'] == 'AES-256-GCM' and data['kdf'] == 'PBKDF2-HMAC-SHA256'
    assert data['certificateSha256'] == expected and data['iterations'] == 600000
    decode = lambda value: base64.b64decode(value, validate=True)
    kdf = PBKDF2HMAC(algorithm=hashes.SHA256(), length=32, salt=decode(data['salt']), iterations=data['iterations'])
    plain = AESGCM(kdf.derive(password.encode())).decrypt(decode(data['nonce']), decode(data['ciphertext']), b'onda-signing-v1:br.com.onda.player')
    folder = root / '.signing'
    folder.mkdir(mode=0o700, exist_ok=True)
    folder.chmod(0o700)
    handle, name = tempfile.mkstemp(prefix='restore-', suffix='.keystore', dir=folder)
    try:
        with os.fdopen(handle, 'wb') as output:
            output.write(plain)
        certificate = subprocess.check_output(['keytool', '-exportcert', '-keystore', name, '-storepass:env', 'ONDA_SIGNING_PASSPHRASE', '-alias', 'onda-release'], stderr=subprocess.DEVNULL)
        if hashlib.sha256(certificate).hexdigest() != expected:
            raise RuntimeError('Restored key does not match the pinned signing certificate.')
        target = folder / 'release.keystore'
        os.replace(name, target)
        target.chmod(0o600)
        print('Encrypted signing backup restored and pinned certificate verified.')
    finally:
        Path(name).unlink(missing_ok=True)
if __name__ == '__main__':
    try:
        restore()
    except Exception:
        raise SystemExit('Signing restoration failed. Check ONDA_SIGNING_PASSPHRASE and the encrypted backup; no replacement key was generated.')
