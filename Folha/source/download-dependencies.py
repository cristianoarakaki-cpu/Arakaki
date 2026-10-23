import urllib.request,concurrent.futures,pathlib
root=pathlib.Path(__file__).resolve().parent/'assets'/'vendor'
(root/'lang').mkdir(parents=True,exist_ok=True)
files={'pdf-lib.js':'https://cdn.jsdelivr.net/npm/pdf-lib@1.17.1/dist/pdf-lib.min.js','pdf.js':'https://cdn.jsdelivr.net/npm/pdfjs-dist@3.11.174/build/pdf.min.js','pdf.worker.js':'https://cdn.jsdelivr.net/npm/pdfjs-dist@3.11.174/build/pdf.worker.min.js','tesseract.js':'https://cdn.jsdelivr.net/npm/tesseract.js@5.1.1/dist/tesseract.min.js','worker.min.js':'https://cdn.jsdelivr.net/npm/tesseract.js@5.1.1/dist/worker.min.js'}
for variant in ['lstm','simd-lstm']:
 for ext in ['wasm.js','wasm']:
  name=f'tesseract-core-{variant}.{ext}';files[name]='https://cdn.jsdelivr.net/npm/tesseract.js-core@5.1.1/'+name
for lang in ['por','eng','spa']:files['lang/'+lang+'.traineddata.gz']='https://cdn.jsdelivr.net/npm/@tesseract.js-data/'+lang+'@1.0.0/4.0.0_best_int/'+lang+'.traineddata.gz'
def fetch(item):
 name,url=item
 for attempt in range(3):
  try:
   with urllib.request.urlopen(url,timeout=60) as r: data=r.read()
   (root/name).write_bytes(data);return name,len(data)
  except Exception as e:
   if attempt==2:return name,str(e)
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as ex:
 for r in ex.map(fetch,files.items()):print(r,flush=True)
