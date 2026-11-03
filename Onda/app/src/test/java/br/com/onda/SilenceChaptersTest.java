package br.com.onda;
import org.junit.Test;
import java.util.*;
import static org.junit.Assert.*;
public class SilenceChaptersTest {
 private void sound(SilenceChapters detector,long start,long duration,double power){for(long at=start;at<start+duration;at+=100)detector.window(at,Math.min(100,start+duration-at),power);}
 @Test public void threeSongsSeparatedByPauses(){SilenceChapters d=new SilenceChapters();sound(d,0,31000,.05);sound(d,31000,1800,0);sound(d,32800,31000,.05);sound(d,63800,1800,0);sound(d,65600,31000,.05);assertEquals(Arrays.asList(0L,32650L,65450L),d.finish(96600));}
 @Test public void continuousMixDoesNotInventTracks(){SilenceChapters d=new SilenceChapters();sound(d,0,600000,.01);assertEquals(Collections.singletonList(0L),d.finish(600000));}
 @Test public void introductoryAndTrailingSilenceDoNotBecomeSongs(){SilenceChapters d=new SilenceChapters();sound(d,0,4000,0);sound(d,4000,60000,.05);sound(d,64000,5000,0);assertEquals(Collections.singletonList(0L),d.finish(69000));}
 @Test public void shortGapsAndShortTailsAreConservativelyIgnored(){SilenceChapters d=new SilenceChapters();sound(d,0,31000,.05);sound(d,31000,1000,0);sound(d,32000,31000,.05);sound(d,63000,2000,0);sound(d,65000,10000,.05);assertEquals(Collections.singletonList(0L),d.finish(75000));}
 @Test public void quietButAudibleAudioDoesNotTriggerSilence(){SilenceChapters d=new SilenceChapters();sound(d,0,35000,.05);sound(d,35000,5000,SilenceChapters.QUIET_POWER*2);sound(d,40000,35000,.05);assertEquals(1,d.finish(75000).size());}
 @Test public void timestampHolesDoNotCountAsDecodedSilence(){SilenceChapters d=new SilenceChapters();sound(d,0,35000,.05);sound(d,35000,200,0);sound(d,40000,35000,.05);assertEquals(1,d.finish(75000).size());}
 @Test public void backwardAndInvalidWindowsAreRejected(){SilenceChapters d=new SilenceChapters();d.window(1000,100,.1);try{d.window(100,100,.1);fail();}catch(IllegalArgumentException expected){}try{d.window(1200,100,Double.NaN);fail();}catch(IllegalArgumentException expected){}}
}
