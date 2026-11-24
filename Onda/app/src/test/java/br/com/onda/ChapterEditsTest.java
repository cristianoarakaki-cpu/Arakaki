package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
import java.util.Arrays;
public class ChapterEditsTest {
    private AudioChapterStore.Data collection(){return new AudioChapterStore.Data(96600,Arrays.asList(new AudioChapterStore.Chapter(0,"A"),new AudioChapterStore.Chapter(32650,"B"),new AudioChapterStore.Chapter(65450,"C")));}
    @Test public void fractionalMarkersRoundTrip(){for(long n:new long[]{0,32650,65450,96600,3661001})assertEquals(n,ChapterEdits.parse(ChapterEdits.format(n)));assertEquals(32650,ChapterEdits.parse("32,650"));assertEquals(3661001,ChapterEdits.parse("1:01:01.001"));}
    @Test public void rejectsMalformedAndOverflow(){for(String s:new String[]{"-1","1:60","1:01:60","NaN","","1.0000","1:1:1:1","99999999999999999999999"}){try{ChapterEdits.parse(s);fail(s);}catch(IllegalArgumentException expected){}}}
    @Test public void movingBothLimitsChangesAdjacentTracksWithoutMutatingOriginal(){AudioChapterStore.Data original=collection(),edited=ChapterEdits.update(original,1,"Nova",33000,65000);assertEquals(33000,edited.chapters.get(1).start);assertEquals(65000,edited.chapters.get(2).start);assertEquals("Nova",edited.chapters.get(1).title);assertEquals("C",edited.chapters.get(2).title);assertEquals(32650,original.chapters.get(1).start);assertEquals(65450,original.chapters.get(2).start);}
    @Test public void cannotMoveOutsideNeighborBounds(){for(long[] bounds:new long[][]{{0,65000},{33000,96600},{66000,65000},{-1,65000}}){try{ChapterEdits.update(collection(),1,"B",bounds[0],bounds[1]);fail();}catch(IllegalArgumentException expected){}}try{ChapterEdits.update(collection(),0,"A",1,32000);fail();}catch(IllegalArgumentException expected){}try{ChapterEdits.update(collection(),2,"C",65000,96000);fail();}catch(IllegalArgumentException expected){}}
    @Test public void manualAdditionAndRemovalKeepFullCoverage(){AudioChapterStore.Data original=ChapterEdits.full(96600),edited=ChapterEdits.add(original,32650,"Segunda");assertEquals(1,original.chapters.size());assertEquals(2,edited.chapters.size());assertEquals(0,edited.chapters.get(0).start);assertEquals(96600,edited.duration);assertEquals(1,ChapterEdits.remove(edited,1).chapters.size());}
    @Test public void duplicateOrEndpointBoundaryIsRejected(){for(long n:new long[]{0,32650,96600,-1})try{ChapterEdits.add(collection(),n,"");fail();}catch(IllegalArgumentException expected){}try{ChapterEdits.remove(collection(),0);fail();}catch(IllegalArgumentException expected){}}
}
