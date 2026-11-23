"""Owner-operated, read-only recovery of Onda metadata over an authorized USB ADB connection.
Requires Python 3 and Android platform-tools (adb). Does not root, change or uninstall the old app.
"""
import argparse,json,os,re,subprocess,sys,tempfile,xml.etree.ElementTree as ET
from pathlib import Path
OLD='br.com.onda.musica'
class RecoveryError(Exception):pass

def java_hash(text):
    result=0
    raw=text.encode('utf-16-le')
    for offset in range(0,len(raw),2):result=(31*result+int.from_bytes(raw[offset:offset+2],'little'))&0xffffffff
    if result>=0x80000000:result-=0x100000000
    return 'download:'+str(result)

def preferences(raw):
    root=ET.fromstring(raw);out={}
    if root.tag!='map':raise RecoveryError('Invalid preference file')
    for child in root:
        name=child.get('name')
        if child.tag=='string':out[name]=child.text or ''
        elif child.tag=='set':out[name]=[item.text or '' for item in child if item.tag=='string']
    return out

def assemble(prefs,lookup):
    favorites=prefs['library'].get('favorites',[])
    playlists=json.loads(prefs['playlists'].get('lists','[]'))
    phrases=json.loads(prefs['voice_phrases'].get('entries','[]'))
    documents=json.loads(prefs['downloaded_audio'].get('documents','{}'))
    docs={}
    for uri,value in documents.items():
        if uri.startswith('content://') and value.get('mime','').startswith('audio/'):
            key=java_hash(uri)
            docs[key]=None if key in docs else value
    refs=set(favorites)
    for playlist in playlists:refs.update(playlist.get('songs',[]))
    tracks=[];missing=[]
    for index,key in enumerate(sorted(refs)):
        if re.fullmatch(r'\d{1,32}',key):track=lookup(key)
        elif docs.get(key) is not None:track=dict(key=key,title=docs[key].get('title') or 'Áudio baixado',artist='Download local',album='',duration=0)
        else:track=None
        if track is not None:
            for field in ['title','artist','album']:
                if not isinstance(track[field],str) or len(track[field])>512:raise RecoveryError('Metadata too long; recovery stopped without changing the old app.')
            tracks.append(track)
        else:missing.append(key)
    keys={t['key'] for t in tracks};lists=[]
    for source in playlists:
        name=source.get('name','')
        if not isinstance(name,str) or not 1<=len(name)<=60:raise RecoveryError('An old playlist name is invalid; recovery stopped.')
        lists.append(dict(name=name,songs=list(dict.fromkeys(k for k in source.get('songs',[]) if k in keys))))
    return dict(format='onda-backup',version=2,tracks=tracks,playlists=lists,favorites=list(dict.fromkeys(k for k in favorites if k in keys)),phrases=phrases),missing

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--serial',help='ADB serial, if more than one device is connected');parser.add_argument('--output',default='Onda-recuperado.json');args=parser.parse_args()
    prefix=['adb']+(['-s',args.serial] if args.serial else [])
    def adb(*command,optional=False):
        try:r=subprocess.run(prefix+list(command),stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=60)
        except FileNotFoundError:raise RecoveryError('adb was not found. Install Android platform-tools and add adb to PATH.')
        except subprocess.TimeoutExpired:raise RecoveryError('The phone did not respond. Check the USB connection and authorization prompt.')
        if r.returncode:
            message=r.stderr.decode('utf-8',errors='replace')
            if optional and 'No such file' in message:return b'<map />'
            raise RecoveryError('Cannot read the old app. Confirm USB debugging authorization and that the original Onda is still installed. Recovery requires its debuggable build; no access restrictions are bypassed.')
        return r.stdout
    devices=adb('devices').decode('utf-8');ready=[line for line in devices.splitlines() if re.search(r'\sdevice$',line)]
    if args.serial:
        if not any(line.startswith(args.serial+'\t') for line in ready):raise RecoveryError('The selected device is not authorized.')
    elif len(ready)!=1:raise RecoveryError('Connect exactly one authorized phone, or specify --serial.')
    prefs={}
    for name in ['library','playlists','voice_phrases','downloaded_audio']:
        prefs[name]=preferences(adb('exec-out','run-as',OLD,'cat','shared_prefs/'+name+'.xml',optional=True))
    def field(key,column):
        raw=adb('shell','content','query','--uri','content://media/external/audio/media/'+key,'--projection',column).decode('utf-8').strip()
        if raw=='No result found.':return None
        expected='Row: 0 '+column+'='
        if not raw.startswith(expected) or '\nRow:' in raw:raise RecoveryError('Android did not provide readable music metadata. No recovery file was saved; the old app was not changed.')
        return raw[len(expected):]
    def lookup(key):
        title=field(key,'title')
        if title is None:return None
        values={column:field(key,column) for column in ['artist','album','duration']}
        try:duration=int(values['duration'])
        except (TypeError,ValueError):return None
        if duration<=0:return None
        artist=values['artist']
        if artist in (None,'NULL','<unknown>',''):artist='Artista desconhecido'
        album=values['album'];album='' if album in (None,'NULL') else album
        return dict(key=key,title=title if title not in ('','NULL') else 'Sem título',artist=artist,album=album,duration=duration)
    archive,missing=assemble(prefs,lookup)
    output=Path(args.output).resolve()
    if output.exists():raise RecoveryError('The output already exists. Choose another --output filename to preserve it.')
    payload=json.dumps(archive,ensure_ascii=False,indent=2).encode('utf-8')
    if len(payload)>64*1024*1024:raise RecoveryError('Metadata exceeds 64 MB; nothing was saved.')
    fd,temp=tempfile.mkstemp(prefix='onda-recovery-',suffix='.tmp',dir=output.parent)
    try:
        with os.fdopen(fd,'wb') as target:target.write(payload)
        os.replace(temp,output)
    finally:Path(temp).unlink(missing_ok=True)
    print('Recovery saved:',output)
    print('Favorites:',len(archive['favorites']),'Playlists:',len(archive['playlists']),'Missing references:',len(missing))
    print('Copy this JSON to the same phone and open Onda Novo > Backup e restauracao > Restaurar backup. Review the preview. Audio files are not included; missing or ambiguous matches will not be assigned.')
if __name__=='__main__':
    try:main()
    except (RecoveryError,ValueError,ET.ParseError,TypeError,KeyError,OSError) as error:raise SystemExit('Recovery not completed: '+str(error))
