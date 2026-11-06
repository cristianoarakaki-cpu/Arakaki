"""Regression checks for declared security boundaries; not an antivirus verdict."""
import json,pathlib,unittest,xml.etree.ElementTree as E
ROOT=pathlib.Path('PrismaVoz');ANDROID='{http://schemas.android.com/apk/res/android}'
class SecurityBoundaries(unittest.TestCase):
 def test_permissions_are_scoped_to_document_reading_and_updates(self):
  root=E.parse(ROOT/'AndroidManifest.xml').getroot()
  expected={'INTERNET','ACCESS_NETWORK_STATE','FOREGROUND_SERVICE','FOREGROUND_SERVICE_MEDIA_PLAYBACK','POST_NOTIFICATIONS','WAKE_LOCK','REQUEST_INSTALL_PACKAGES'}
  self.assertEqual({p.attrib[ANDROID+'name'].removeprefix('android.permission.') for p in root.findall('uses-permission')},expected)
  for node in root.findall('./application/service')+root.findall('./application/provider'):self.assertEqual(node.attrib[ANDROID+'exported'],'false')
 def test_webview_is_restricted_and_safebrowsing_remains_enabled(self):
  s=(ROOT/'src/com/arakaki/prismavoz/MainActivity.java').read_text()
  for value in ['setAllowFileAccess(false)','setAllowContentAccess(false)','setAllowFileAccessFromFileURLs(false)','setAllowUniversalAccessFromFileURLs(false)','setSafeBrowsingEnabled(true)','Content-Security-Policy','ACTION_OPEN_DOCUMENT','readerReady()']:self.assertIn(value,s)
  self.assertNotIn("'unsafe-eval'",s);self.assertIn("'wasm-unsafe-eval'",s)
  self.assertIn('if(!local(uri)',s)
 def test_only_fixed_readonly_updater_payload_can_be_shared(self):
  s=(ROOT/'src/com/arakaki/prismavoz/SharedFileProvider.java').read_text();self.assertIn('!"Prisma-update.apk".equals',s);self.assertIn('if(!"r".equals(mode))throw',s);self.assertNotIn('MODE_READ_WRITE',s)
 def test_internal_updater_keeps_all_verification(self):
  s=(ROOT/'src/com/arakaki/prismavoz/UpdateManager.java').read_text()
  for value in ['sha.equalsIgnoreCase','incoming.packageName.equals','incoming.versionCode<=installed.versionCode','certificates(incoming).equals(certificates(installed))','canRequestPackageInstalls','connect(CHANNEL)']:self.assertIn(value,s)
 def test_corrected_reader_only_and_offline_dependencies_pinned(self):
  spec=json.loads((ROOT/'dependencies/manifest.json').read_text());files=set(spec['files']);self.assertIn('vendor/pdf.mjs',files);self.assertNotIn('vendor/pdf.js',files);self.assertNotIn('vendor/pdf.worker.js',files);self.assertNotIn('vendor/pdf-lib.js',files)
  self.assertEqual(json.loads((ROOT/'dependencies/provenance.json').read_text())['pdfjs-dist']['version'],'4.10.38')
  s=(ROOT/'assets/app.js').read_text();self.assertIn('isEvalSupported:false',s);self.assertIn('standardFontDataUrl:',s)
if __name__=='__main__':unittest.main(verbosity=2)
