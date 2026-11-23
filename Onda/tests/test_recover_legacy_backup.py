import importlib.util,unittest
from pathlib import Path
spec=importlib.util.spec_from_file_location('recovery',Path(__file__).resolve().parents[1]/'tools/recover_legacy_backup.py');recovery=importlib.util.module_from_spec(spec);spec.loader.exec_module(recovery)
class RecoveryTests(unittest.TestCase):
 def test_parse_reads_only_explicit_metadata(self):
  self.assertEqual({'favorites':['12','download:-42']},recovery.preferences('<map><set name="favorites"><string>12</string><string>download:-42</string></set><int name="unrelated" value="10"/></map>'))
 def test_legacy_numeric_and_download_references_become_portable_version_two(self):
  uri='content://media/external/audio/media/12';key=recovery.java_hash(uri)
  prefs={'library':{'favorites':['12',key,'99']},'playlists':{'lists':'[{"name":"Viagem","songs":["12","99"]}]'},'voice_phrases':{},'downloaded_audio':{'documents':recovery.json.dumps({uri:{'title':'Download','mime':'audio/mpeg'}})}}
  data,missing=recovery.assemble(prefs,lambda key:dict(key=key,title='Song',artist='Artist',album='',duration=60000) if key=='12' else None)
  self.assertEqual(2,data['version']);self.assertEqual({'12',key},set(data['favorites']));self.assertEqual(['99'],missing);self.assertEqual(['12'],data['playlists'][0]['songs']);self.assertNotIn('content://',recovery.json.dumps(data));self.assertEqual('download:96354',recovery.java_hash('abc'))
 def test_unknown_reference_is_omitted_not_guessed(self):
  data,missing=recovery.assemble({'library':{'favorites':['download:99']},'playlists':{},'voice_phrases':{},'downloaded_audio':{}},lambda k:None)
  self.assertFalse(data['favorites']);self.assertEqual(['download:99'],missing)
 def test_document_hash_collision_is_not_assigned_to_either_file(self):
  one='content://documents/Aa';two='content://documents/BB';key=recovery.java_hash(one);self.assertEqual(key,recovery.java_hash(two))
  docs={one:{'title':'One','mime':'audio/mpeg'},two:{'title':'Two','mime':'audio/mpeg'}}
  data,missing=recovery.assemble({'library':{'favorites':[key]},'playlists':{},'voice_phrases':{},'downloaded_audio':{'documents':recovery.json.dumps(docs)}},lambda k:None)
  self.assertFalse(data['favorites']);self.assertEqual([key],missing)
if __name__=='__main__':unittest.main()
