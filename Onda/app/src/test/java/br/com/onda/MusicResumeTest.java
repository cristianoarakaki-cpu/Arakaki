package br.com.onda;
import org.junit.Test;
import java.util.*;
import static org.junit.Assert.*;
public class MusicResumeTest {
 @Test public void keepsQueueIncludingRepeatedSongs(){List<String> q=Arrays.asList("1","2","1");assertEquals(q,MusicResume.decode(MusicResume.encode(q)));MusicResume.Selection s=MusicResume.select(q,2,9000,Map.of("1",60000L,"2",60000L));assertEquals(2,s.index);assertEquals(9000,s.position);}
 @Test public void missingCurrentStartsNextAvailableAtZero(){MusicResume.Selection s=MusicResume.select(Arrays.asList("1","2","3"),1,9000,Map.of("1",60000L,"3",60000L));assertEquals(Arrays.asList("1","3"),s.ids);assertEquals(1,s.index);assertEquals(0,s.position);}
 @Test public void missingEarlierTrackDoesNotShiftCurrent(){MusicResume.Selection s=MusicResume.select(Arrays.asList("1","2","3"),2,9000,Map.of("2",60000L,"3",60000L));assertEquals(1,s.index);assertEquals(9000,s.position);}
 @Test public void invalidPositionAndEmptyLibraryAreSafe(){assertEquals(0,MusicResume.select(Arrays.asList("1"),0,70000,Map.of("1",60000L)).position);assertTrue(MusicResume.select(Arrays.asList("1"),0,2000,Collections.emptyMap()).ids.isEmpty());assertTrue(MusicResume.decode("broken").isEmpty());assertTrue(MusicResume.decode("[\"https://temporary\"]").isEmpty());}
}
