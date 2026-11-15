"""Inject verified optional test weights into the disposable emulator's private app directory."""
from pathlib import Path
import subprocess,shlex
from prepare_ai_test_models import ROOT,MODELS,sha
PACKAGE='br.com.onda.musica'
def shell(*args):subprocess.run(['adb','shell',shlex.join(args)],check=True,timeout=180)
shell('run-as',PACKAGE,'mkdir','-p','files/ai-models')
for repo,rev,name,size,expected in MODELS:
    file=ROOT/name
    assert file.stat().st_size==size and sha(file)==expected
    remote='/data/local/tmp/'+name
    subprocess.run(['adb','push',str(file),remote],check=True,timeout=180)
    shell('chmod','644',remote)
    shell('run-as',PACKAGE,'cp',remote,'files/ai-models/'+name)
    shell('rm','-f',remote)
