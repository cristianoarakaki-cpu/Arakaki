"""Bundle a pinned, redistributable Portuguese fast model; never downloads on the phone."""
from pathlib import Path
import hashlib
import time
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'app/src/main/assets/ocr'
REV = '87416418657359cb625c412a48b6e1d6d41c29bd'
BLOB = 'e9f373e95c66b4bf557c263721ef31f78e5bc301'
SIZE = 1982756

def valid(data):
    return len(data) == SIZE and hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest() == BLOB

ASSETS.mkdir(parents=True, exist_ok=True)
model = ASSETS / 'por.traineddata'
data = model.read_bytes() if model.exists() else b''
if not valid(data):
    for attempt in range(2):
        try:
            url = f'https://raw.githubusercontent.com/tesseract-ocr/tessdata_fast/{REV}/por.traineddata'
            with urllib.request.urlopen(url, timeout=45) as response:
                data = response.read(SIZE + 1)
            if not valid(data):
                raise ValueError('Modelo OCR difere da revisão fixada')
            partial = model.with_suffix('.part')
            partial.write_bytes(data)
            partial.replace(model)
            break
        except Exception:
            if attempt:
                raise
            time.sleep(1)
(ASSETS / 'por.sha256').write_text(hashlib.sha256(data).hexdigest() + '\n')
print('OCR português incluído e conferido:', len(data), 'bytes')
