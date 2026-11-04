package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
public class PlaybackContinuityTest {
 @Test public void completedAndOldEndBookmarksRestartButMiddlePositionIsPreserved(){assertEquals(0,PlaybackContinuity.resume(45000,45000,true));assertEquals(0,PlaybackContinuity.resume(44990,45000,false));assertEquals(12000,PlaybackContinuity.resume(12000,45000,false));assertEquals(12000,PlaybackContinuity.resume(12000,-9223372036854775807L,false));assertEquals(0,PlaybackContinuity.resume(-100,45000,false));}
 @Test public void collapsesDuplicateCallbacksButAlwaysSavesRealMovementAndNewSource(){ShelfCheckpoint gate=new ShelfCheckpoint();assertTrue(gate.save("a",100,1000,1000));assertFalse(gate.save("a",100,1000,1010));assertTrue(gate.save("a",200,1000,1020));assertTrue(gate.save("b",200,1000,1030));assertTrue(gate.save("b",200,2000,1040));assertFalse(gate.save("b",200,2000,1050));assertTrue(gate.save("b",200,2000,2100));}
}
