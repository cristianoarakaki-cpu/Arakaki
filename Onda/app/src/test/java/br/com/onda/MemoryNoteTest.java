package br.com.onda;import org.junit.Test;import static org.junit.Assert.*;
public class MemoryNoteTest {
 @Test public void fractionalRangesAreExactAndBounded(){MemoryText.Cue cue=MemoryNote.cue(" Solo de guitarra ",-1,"0:10.125","0:12,375",30000);assertEquals("Solo de guitarra",cue.text);assertEquals(10125,cue.start);assertEquals(12375,cue.end);for(String end:new String[]{"0:10.125","0:09.000","1:00.000"})try{MemoryNote.cue("Solo",-1,"0:10.125",end,30000);fail();}catch(IllegalArgumentException expected){}}
 @Test public void pdfPageAndTextValidation(){assertEquals(1,MemoryNote.cue("Capítulo",1,"","",2).page);try{MemoryNote.cue("Capítulo",2,"","",2);fail();}catch(IllegalArgumentException expected){}for(String text:new String[]{" ",new String(new char[501]).replace('\0','x')})try{MemoryNote.text(text);fail();}catch(IllegalArgumentException expected){}}
 @Test public void defaultRangeNeverOverflowsOrExceedsEnd(){assertEquals(0,MemoryNote.start(-1,30000));assertEquals(29999,MemoryNote.start(40000,30000));assertEquals(30000,MemoryNote.end(29000,30000));assertEquals(Long.MAX_VALUE,MemoryNote.end(Long.MAX_VALUE-1,Long.MAX_VALUE));}
}
