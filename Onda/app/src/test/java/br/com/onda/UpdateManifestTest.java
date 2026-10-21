package br.com.onda;

import org.json.JSONObject;
import org.junit.Test;
import static org.junit.Assert.*;

public class UpdateManifestTest {
    private JSONObject data() throws Exception {
        return new JSONObject().put("versionCode",6).put("versionName","0.5.0").put("packageName","br.com.onda.musica")
            .put("apkUrl","https://github.com/cristianoarakaki-cpu/Arakaki/releases/download/onda-v0.5.0/Onda-Musica.apk")
            .put("sha256","ab".repeat(32));
    }
    private void rejects(JSONObject data) throws Exception {
        try { new UpdateRepository.Update(data,"br.com.onda.musica"); fail("Expected invalid manifest to be rejected"); }
        catch (java.io.IOException expected) {}
    }
    @Test public void validRelease() throws Exception {UpdateRepository.Update u=new UpdateRepository.Update(data(),"br.com.onda.musica");assertEquals(6,u.code);assertEquals("0.5.0",u.version);}
    @Test public void rejectsOtherPackage() throws Exception {rejects(data().put("packageName","br.com.other"));}
    @Test public void rejectsNonHttpsOrOtherRepository() throws Exception {rejects(data().put("apkUrl","http://github.com/cristianoarakaki-cpu/Arakaki/releases/download/test.apk"));rejects(data().put("apkUrl","https://github.com/other/repo/releases/download/test.apk"));}
    @Test public void rejectsHostSpoof() throws Exception {assertFalse(UpdateRepository.validAsset("https://github.com.evil.example/cristianoarakaki-cpu/Arakaki/releases/download/test.apk"));assertFalse(UpdateRepository.validAsset(null));}
    @Test public void rejectsInvalidVersionAndHash() throws Exception {rejects(data().put("versionCode",0));rejects(data().put("sha256","xyz"));}
}
