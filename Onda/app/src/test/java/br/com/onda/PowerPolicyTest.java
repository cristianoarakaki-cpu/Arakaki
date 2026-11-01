package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
import java.util.*;
public class PowerPolicyTest {
 @Test public void backgroundProgressDoesNotChangeForegroundResponsiveness(){assertEquals(1000,PowerPolicy.progressInterval(true));assertEquals(10000,PowerPolicy.progressInterval(false));assertEquals(15000,PowerPolicy.BACKGROUND_STATE_MS);}
 @Test public void nextVerseTracksPlaybackSpeedAndSeeking(){List<Lrc.Line> lines=Lrc.parse("[00:00]A\n[00:10]B\n[00:20]C");assertEquals(9000,PowerPolicy.lyricDelay(lines,0,1000,1,0,false));assertEquals(4500,PowerPolicy.lyricDelay(lines,0,1000,2,0,false));assertEquals(18000,PowerPolicy.lyricDelay(lines,0,1000,.5f,0,false));assertEquals(1000,PowerPolicy.lyricDelay(lines,1,19000,1,0,false));}
 @Test public void plainTextAndFinalVerseDoNotCreateAnIdleLoop(){assertEquals(-1,PowerPolicy.lyricDelay(Collections.emptyList(),-1,0,1,0,false));List<Lrc.Line> lines=Lrc.parse("[00:00]A");assertEquals(-1,PowerPolicy.lyricDelay(lines,0,2000,1,0,false));assertEquals(5000,PowerPolicy.lyricDelay(lines,0,2000,1,5000,true));}
 @Test public void manualScrollResumesWithoutWaitingForNextLongVerse(){List<Lrc.Line> lines=Lrc.parse("[00:00]A\n[02:00]B");assertEquals(5000,PowerPolicy.lyricDelay(lines,0,0,1,5000,true));assertEquals(60000,PowerPolicy.lyricDelay(lines,0,0,1,0,false));}
 @Test public void earlyBoundaryAndInvalidRateStayFinite(){List<Lrc.Line> lines=Lrc.parse("[00:10]A");assertEquals(10000,PowerPolicy.lyricDelay(lines,-1,0,Float.NaN,0,false));assertEquals(25,PowerPolicy.lyricDelay(lines,-1,10000,1,0,false));}
}
