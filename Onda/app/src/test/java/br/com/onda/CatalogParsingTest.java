package br.com.onda;

import org.json.*;
import org.junit.Test;
import static org.junit.Assert.*;

public class CatalogParsingTest {
    private JSONObject track() throws Exception {return new JSONObject().put("kind","song").put("trackId",123456789L).put("trackName","Evidências").put("artistName","Chitãozinho & Xororó").put("collectionName","Clássicos").put("previewUrl","https://audio-ssl.itunes.apple.com/sample.m4a").put("trackViewUrl","https://music.apple.com/br/album/example/123?i=456");}
    @Test public void keepsNumericIdAndPreviewAttribution() throws Exception {
        var values=OnlineRepository.parseCatalog(new JSONObject().put("results",new JSONArray().put(track())));
        assertEquals(1,values.size());assertEquals("123456789",values.get(0).id);assertTrue(values.get(0).isPreview());assertEquals("Chitãozinho & Xororó",values.get(0).artist);assertTrue(OnlineRepository.allowedStore(values.get(0).storeUrl));
    }
    @Test public void skipsUnavailablePreviewAndNonMusic() throws Exception {
        var rows=new JSONArray().put(track().put("previewUrl","")).put(track().put("kind","music-video"));
        assertTrue(OnlineRepository.parseCatalog(new JSONObject().put("results",rows)).isEmpty());
    }
    @Test public void rejectsOtherPreviewHosts() throws Exception {
        assertFalse(OnlineRepository.allowedPreview("https://audio-ssl.itunes.apple.com.evil.example/audio.mp3"));assertFalse(OnlineRepository.allowedPreview("http://audio-ssl.itunes.apple.com/sample.m4a"));assertFalse(OnlineRepository.allowedStore("https://example.com"));
    }
    @Test(expected=java.io.IOException.class) public void incompleteResponseIsErrorNotEmptyResults() throws Exception {OnlineRepository.parseCatalog(new JSONObject());}
    @Test public void artistMatchOutranksUnrelatedSongNamedAfterArtist(){assertTrue(SearchText.relevance("Chitaozinho e xororo","Evidências","Chitãozinho & Xororó")>SearchText.relevance("Chitaozinho e xororo","Chitãozinho e Xororó","Tonico & Tinoco"));}
}
