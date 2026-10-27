"""Materialize bundled, hash-pinned third-party libraries; no network required."""
import hashlib,json,pathlib,zipfile,io
root=pathlib.Path('PrismaPDF');spec=json.loads((root/'dependencies/manifest.json').read_text());pieces=[]
for i,entry in enumerate(spec['parts']):
 assert entry['name']==f'vendor.zip.part{i:03d}'
 data=(root/'dependencies'/entry['name']).read_bytes();assert len(data)==entry['size'] and hashlib.sha256(data).hexdigest()==entry['sha256'],'Dependência divergente';pieces.append(data)
data=b''.join(pieces);assert hashlib.sha256(data).hexdigest()==spec['sha256'],'Pacote de bibliotecas divergente'
with zipfile.ZipFile(io.BytesIO(data)) as z:
 assert set(z.namelist())==set(spec['files'])
 for name,expected in spec['files'].items():
  path=pathlib.PurePosixPath(name);assert path.parts[0]=='vendor' and '..' not in path.parts
  content=z.read(name);assert hashlib.sha256(content).hexdigest()==expected
  out=root/'assets'/path;out.parent.mkdir(exist_ok=True,parents=True);out.write_bytes(content)
print('Bibliotecas e modelos locais conferidos e extraídos.')
