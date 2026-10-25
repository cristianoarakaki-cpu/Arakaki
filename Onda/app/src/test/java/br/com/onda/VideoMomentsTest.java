package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
import java.util.*;
public class VideoMomentsTest {
 private VideoMoments.Moment m(long p,String label){return new VideoMoments.Moment(UUID.randomUUID().toString(),label,p);}
 @Test public void roundTripKeepsIdentityAndSortsScenes(){VideoMoments.Moment a=m(9500,"Refrão"),b=m(0,"Introdução");List<VideoMoments.Moment> restored=VideoMoments.decode(VideoMoments.encode(Arrays.asList(a,b)));assertEquals(2,restored.size());assertEquals(b.id,restored.get(0).id);assertEquals(9500,restored.get(1).position);assertEquals("Refrão",restored.get(1).label);}
 @Test public void damagedAndOversizedDataDoesNotBreakPlayer(){assertTrue(VideoMoments.decode("not JSON").isEmpty());assertTrue(VideoMoments.decode("x".repeat(65537)).isEmpty());assertTrue(VideoMoments.decode(null).isEmpty());assertTrue(VideoMoments.decode("[{\"id\":12,\"label\":\"x\",\"position\":2}]").isEmpty());}
 @Test public void rejectsInvalidLabelsAndPositions(){assertFalse(VideoMoments.valid(m(-1,"x")));assertFalse(VideoMoments.valid(m(VideoMoments.MAX_TIME+1,"x")));assertFalse(VideoMoments.valid(m(1," ")));assertFalse(VideoMoments.valid(m(1,"x".repeat(81))));assertEquals("Meu trecho",VideoMoments.label(" \nMeu\t trecho \r"));}
 @Test public void fractionalTimesAndDuplicateIdsAreRejected(){VideoMoments.Moment a=m(2,"x");String raw=VideoMoments.encode(List.of(a));assertEquals(1,VideoMoments.decode("["+raw.substring(1,raw.length()-1)+","+raw.substring(1,raw.length()-1)+"]").size());assertTrue(VideoMoments.decode(raw.replace("\"position\":2","\"position\":2.5")).isEmpty());}
 @Test public void encodingIsBoundedWithoutChangingOtherScenes(){List<VideoMoments.Moment> many=new ArrayList<>();for(int i=0;i<40;i++)many.add(m(i,"Cena "+i));assertEquals(30,VideoMoments.decode(VideoMoments.encode(many)).size());assertEquals(40,many.size());}
}
