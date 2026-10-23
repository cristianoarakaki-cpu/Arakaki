package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
public class VideoProgressTest {
 @Test public void resumeRequiresUsefulUnfinishedPosition(){assertEquals(6000,VideoProgress.resume(6000,20000,20000));assertEquals(0,VideoProgress.resume(2000,20000,20000));assertEquals(0,VideoProgress.resume(19000,20000,20000));assertEquals(0,VideoProgress.resume(1000,0,0));assertEquals(6000,VideoProgress.resume(6000,20000,0));}
 @Test public void replacedOrCompletedFilesDoNotResumeAtOldPosition(){assertEquals(0,VideoProgress.resume(10000,20000,40000));assertEquals(0,VideoProgress.resume(60000,60000,60000));assertEquals(30000,VideoProgress.resume(30000,60000,61000));assertEquals(0,VideoProgress.resume(-1,60000,60000));}
 @Test public void gesturesAreBoundedAndUseRelativeStartingValues(){assertEquals(0,VideoProgress.volume(50,-2));assertEquals(100,VideoProgress.volume(50,2));assertEquals(75,VideoProgress.volume(50,.25f));assertEquals(.02,VideoProgress.brightness(.5f,-2),.0001);assertEquals(1,VideoProgress.brightness(.5f,2),.0001);assertEquals(.75,VideoProgress.brightness(.5f,.25f),.0001);}
}
