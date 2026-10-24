package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
import java.util.*;
public class PlaylistSelectionTest {
 private PlaylistSelection model(){return new PlaylistSelection(Arrays.asList(new YoutubeDownloads.Entry("A","https://youtu.be/aqz-KE-bpKQ","https://i.ytimg.com/vi/aqz-KE-bpKQ/mqdefault.jpg",125),new YoutubeDownloads.Entry("B","https://youtu.be/qHZiIxprsrs"),new YoutubeDownloads.Entry("C","https://youtu.be/00000000001")));}
 @Test public void explicitSelectionPreservesPlaylistOrder(){PlaylistSelection s=model();assertEquals(0,s.count());s.set(2,true);s.set(0,true);assertEquals("A",s.chosen().get(0).title);assertEquals("C",s.chosen().get(1).title);s.all(true);assertEquals(3,s.count());s.set(1,false);assertEquals(2,s.count());s.all(false);assertEquals(0,s.count());}
 @Test public void restoreKeepsMarksAndMetadata()throws Exception{PlaylistSelection s=model();s.set(0,true);s.set(2,true);PlaylistSelection restored=PlaylistSelection.decode(s.encode());assertEquals(2,restored.count());assertTrue(restored.contains(0));assertFalse(restored.contains(1));assertEquals(125,restored.items.get(0).duration);assertEquals("https://i.ytimg.com/vi/aqz-KE-bpKQ/mqdefault.jpg",restored.items.get(0).thumbnail);assertEquals(2,DownloadQueue.validate(DownloadQueue.encode(restored.chosen())).length());}
 @Test public void durationLabels(){assertEquals("",PlaylistSelection.duration(0));assertEquals("",PlaylistSelection.duration(-1));assertEquals("2:05",PlaylistSelection.duration(125));assertEquals("1:00:00",PlaylistSelection.duration(3600));}
 @Test public void artworkAllowsOnlyPublicHttpsThumbnailHosts(){assertFalse(PlaylistSelection.artwork("https://i.ytimg.com/a.jpg").isEmpty());for(String s:new String[]{"http://i.ytimg.com/a.jpg","https://i.ytimg.com.evil.test/a.jpg","https://i.ytimg.com@evil.test/a.jpg","file:///x","https://localhost/a.jpg"})assertEquals("",PlaylistSelection.artwork(s));}
 @Test public void rejectsDuplicateSavedEntries()throws Exception{String json="[{\"title\":\"A\",\"url\":\"https://www.youtube.com/watch?v=aqz-KE-bpKQ\"},{\"title\":\"B\",\"url\":\"https://www.youtube.com/watch?v=aqz-KE-bpKQ\"}]";try{PlaylistSelection.decode(json);fail();}catch(org.json.JSONException expected){}}
}
