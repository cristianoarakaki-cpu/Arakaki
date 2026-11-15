"""Pinned optional weights for real emulator tests; never copied into application assets."""
from pathlib import Path
import urllib.request, hashlib, json, time
ROOT=Path('/tmp/onda-ai-test-models');ROOT.mkdir(exist_ok=True)
MODELS=[('bartowski/SmolLM2-135M-Instruct-GGUF','09816acd5d99df7be770d85ea30822623dab342c','SmolLM2-135M-Instruct-Q4_K_M.gguf',105454432,'2e8040ceae7815abe0dcb3540b9995eaa1fa0d2ca9e797d0a635ae4433c68c2d'),('Qwen/Qwen2.5-0.5B-Instruct-GGUF','9217f5db79a29953eb74d5343926648285ec7e67','qwen2.5-0.5b-instruct-q4_k_m.gguf',491400032,'74a4da8c9fdbcd15bd1f6d01d621410d31c6fc00986f5eb687824e7b93d7a9db')]
def sha(file):
    value=hashlib.sha256()
    with file.open('rb') as stream:
        while chunk:=stream.read(1048576):value.update(chunk)
    return value.hexdigest()
for repo,rev,name,size,expected in MODELS:
    file=ROOT/name
    if file.is_file() and file.stat().st_size==size and sha(file)==expected:continue
    part=file.with_suffix('.part')
    for attempt in range(3):
        try:
            request=urllib.request.Request(f'https://huggingface.co/{repo}/resolve/{rev}/{name}',headers={'User-Agent':'Onda-Android-CI'})
            with urllib.request.urlopen(request,timeout=90) as response,part.open('wb') as stream:
                count=0
                while chunk:=response.read(1048576):
                    count+=len(chunk)
                    assert count<=size,'Model larger than pinned size'
                    stream.write(chunk)
            assert part.stat().st_size==size and sha(part)==expected,'Model fingerprint mismatch'
            part.replace(file);break
        except Exception:
            part.unlink(missing_ok=True)
            if attempt==2:raise
            time.sleep(2)
    print(json.dumps(dict(model=name,bytes=file.stat().st_size,sha256=expected)),flush=True)
