"""Lossless APK recompression. Caller must zipalign and re-sign with the existing key."""
from pathlib import Path
import copy
import hashlib
import json
import sys
import zipfile
import zopfli.zlib

source, target = map(Path, sys.argv[1:3])
def signature(name):
    name = name.upper()
    return name.startswith('META-INF/') and (name.endswith(('.RSA', '.DSA', '.EC', '.SF')) or name == 'META-INF/MANIFEST.MF')

# Retain zipfile's CRC/size/central-directory implementation. Only the compressor changes.
original = zipfile._get_compressor
class ExactCompressor:
    def __init__(self):
        self.data = bytearray()
    def compress(self, data):
        self.data.extend(data)
        return b''
    def flush(self):
        return zopfli.zlib.compress(bytes(self.data), numiterations=5)[2:-4]
def compressor(kind, level=None):
    return ExactCompressor() if kind == zipfile.ZIP_DEFLATED and level == 99 else original(kind, level)
zipfile._get_compressor = compressor

expected = {}
with zipfile.ZipFile(source) as before, zipfile.ZipFile(target, 'w') as after:
    for entry in before.infolist():
        if signature(entry.filename):
            continue
        data = before.read(entry)
        expected[entry.filename] = hashlib.sha256(data).hexdigest()
        info = copy.copy(entry)
        if entry.filename.endswith(('.so', '.dex')):
            info.compress_type = zipfile.ZIP_DEFLATED
        info._compresslevel = 99 if entry.filename.endswith(('.so', '.dex')) else 9
        after.writestr(info, data)
with zipfile.ZipFile(target) as result:
    assert result.testzip() is None
    actual = {name: hashlib.sha256(result.read(name)).hexdigest() for name in result.namelist()}
    assert actual == expected, 'Conteúdo do APK mudou durante a compactação'
print(json.dumps({'beforeBytes': source.stat().st_size, 'afterBytes': target.stat().st_size, 'identicalContents': True}))
