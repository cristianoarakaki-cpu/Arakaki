package br.com.onda;
import org.junit.Test;
import java.util.*;
import static org.junit.Assert.*;
public class PlaylistStoreTest {
 @Test public void roundTripPreservesNamesAndOrder(){
  PlaylistStore.Entry e=new PlaylistStore.Entry("stable-id","Sertanejo 🎵");e.songs.addAll(Arrays.asList("32","5","99"));
  List<PlaylistStore.Entry> read=PlaylistStore.decode(PlaylistStore.encode(Arrays.asList(e)));
  assertEquals("stable-id",read.get(0).id);assertEquals(e.name,read.get(0).name);assertEquals(e.songs,read.get(0).songs);
 }
 @Test public void excludesInvalidIdsAndDuplicatesWithoutReordering(){
  List<PlaylistStore.Entry> read=PlaylistStore.decode("[{\"id\":\"a\",\"name\":\"Treino\",\"songs\":[\"3\",\"3\",\"https://bad\",\"2\"]},{\"id\":\"a\",\"name\":\"Duplicada\"},{\"id\":\"b\",\"name\":\"\"}]");
  assertEquals(1,read.size());assertEquals(Arrays.asList("3","2"),read.get(0).songs);
 }
 @Test public void malformedDataDoesNotCrash(){assertTrue(PlaylistStore.decode("broken").isEmpty());}
}
