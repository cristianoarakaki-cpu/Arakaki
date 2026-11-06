"""Version-aware production/test source inventory, excluding generated caches."""
import json,pathlib

def source_files(root=pathlib.Path('PrismaVoz')):
 native=json.loads((root/'version.json').read_text()).get('architecture')=='native'
 if native:
  files={p for folder in ['src','res','native-assets','native-build/src','native-build/gradle'] for p in (root/folder).rglob('*') if p.is_file()}
  files.update(p for p in (root/'native-build').glob('*') if p.is_file() and p.name!='local.properties')
  files.update(root/p for p in ['AndroidManifest.xml','version.json','build.sh'])
  return sorted(files)
 return sorted(p for p in root.rglob('*') if p.is_file() and ((p.suffix=='.java' and (root/'src') in p.parents) or (p.parent==root/'assets' and p.suffix in {'.js','.css','.html'}) or p in [root/'AndroidManifest.xml',root/'version.json',root/'build.sh',root/'dependencies/manifest.json']))
