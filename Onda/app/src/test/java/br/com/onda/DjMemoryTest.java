package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
import java.util.*;
public class DjMemoryTest {
 @Test public void mixedQueueKeepsDownloadsDuplicatesAndPosition(){List<String> ids=Arrays.asList("123","download:-2147483648","123");assertEquals(ids,MusicResume.decode(MusicResume.encode(ids)));MusicResume.Selection selected=MusicResume.select(ids,1,12000,Map.of("123",60000L,"download:-2147483648",0L));assertEquals(1,selected.index);assertEquals(12000,selected.position);assertEquals(ids,selected.ids);}
 @Test public void remoteAndMalformedIdsNeverBecomeResumeQueues(){for(String id:Arrays.asList("https://example.com/audio","content://provider/path","download:https://video","download:","download:123456789012345","-2"))assertTrue(MusicResume.decode(MusicResume.encode(Arrays.asList("1",id))).isEmpty());assertTrue(MusicResume.decode(null).isEmpty());}
 @Test public void recommendationReasonsAndModeSurviveRoundTrip(){Map<String,DjMemory.Cue> source=Map.of("1",new DjMemory.Cue("Está nas suas favoritas",1),"download:-7",new DjMemory.Cue("Áudio baixado no Onda",4));Map<String,DjMemory.Cue> saved=DjMemory.decode(DjMemory.encode(source));assertEquals(2,saved.size());assertEquals(4,saved.get("download:-7").mode);assertEquals("Está nas suas favoritas",saved.get("1").reason);}
 @Test public void corruptOrUnsupportedContextDoesNotBlockMusicResume(){assertTrue(DjMemory.decode("broken").isEmpty());assertTrue(DjMemory.decode("{\"1\":{\"reason\":\"x\",\"mode\":50}}").isEmpty());assertTrue(DjMemory.decode("{\"https://remote\":{\"reason\":\"x\",\"mode\":1}}").isEmpty());assertTrue(DjMemory.decode("{\"1\":{\"reason\":12,\"mode\":1}}").isEmpty());assertEquals("{}",DjMemory.encode(Map.of("1",new DjMemory.Cue("x".repeat(281),0))));}
 @Test public void unavailableDownloadDoesNotShiftAnotherSongsPosition(){MusicResume.Selection selected=MusicResume.select(Arrays.asList("download:-1","12"),1,9000,Map.of("12",60000L));assertEquals(0,selected.index);assertEquals(9000,selected.position);MusicResume.Selection missing=MusicResume.select(Arrays.asList("download:-1","12"),0,9000,Map.of("12",60000L));assertEquals(0,missing.position);}
}
