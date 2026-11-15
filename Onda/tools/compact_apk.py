"""Lossless APK recompression. Caller must zipalign and re-sign with the existing key."""
from pathlib import Path
import copy
import hashlib
import json
import sys
import struct
import zipfile
import zopfli.zlib

source, target = map(Path, sys.argv[1:3])
# Optional cache is keyed by complete uncompressed SHA256, never by name/CRC alone.
# Reusing an existing raw deflate stream changes neither bytes nor signing policy.
cached_streams = {}
reused_entries = 0
if len(sys.argv) > 3:
    with zipfile.ZipFile(Path(sys.argv[3])) as reference:
        for item in reference.infolist():
            if item.compress_type != zipfile.ZIP_DEFLATED or not item.filename.endswith(('.so', '.dex')):
                continue
            digest = hashlib.sha256(reference.read(item)).digest()
            reference.fp.seek(item.header_offset)
            header = reference.fp.read(30)
            assert header[:4] == b'PK\x03\x04'
            name_size, extra_size = struct.unpack_from('<HH', header, 26)
            reference.fp.seek(name_size + extra_size, 1)
            stream = reference.fp.read(item.compress_size)
            assert len(stream) == item.compress_size
            cached_streams[digest] = stream
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
        global reused_entries
        digest = hashlib.sha256(self.data).digest()
        if digest in cached_streams:
            reused_entries += 1
            return cached_streams[digest]
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
print(json.dumps({'beforeBytes': source.stat().st_size, 'afterBytes': target.stat().st_size, 'identicalContents': True, 'reusedEntries': reused_entries}))
