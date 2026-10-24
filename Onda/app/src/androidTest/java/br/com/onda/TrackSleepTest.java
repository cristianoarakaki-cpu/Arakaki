package br.com.onda;
import android.content.*;
import android.net.Uri;
import android.os.Bundle;
import androidx.media3.common.*;
import androidx.media3.session.*;
import com.google.common.util.concurrent.ListenableFuture;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
import java.io.*;
import java.util.*;
import java.util.concurrent.TimeUnit;
@androidx.media3.common.util.UnstableApi
public class TrackSleepTest {
 private final android.app.Instrumentation ins=getInstrumentation();
 private void run(int count,boolean skip)throws Exception{
  Context c=ins.getTargetContext();File file=File.createTempFile("sleep-tone-",".m4a",c.getCacheDir());try(InputStream in=ins.getContext().getAssets().open("audio.m4a");OutputStream out=new FileOutputStream(file)){byte[] b=new byte[8192];int n;while((n=in.read(b))>0)out.write(b,0,n);}
  ListenableFuture<MediaController>[] connection=new ListenableFuture[1];ins.runOnMainSync(()->connection[0]=new MediaController.Builder(c,new SessionToken(c,new ComponentName(c,PlaybackService.class))).buildAsync());MediaController player=connection[0].get(15,TimeUnit.SECONDS);
  try{ins.runOnMainSync(()->{player.pause();player.setRepeatMode(Player.REPEAT_MODE_OFF);player.setShuffleModeEnabled(false);List<MediaItem> items=new ArrayList<>();for(int i=0;i<4;i++)items.add(new MediaItem.Builder().setMediaId("8800"+i).setUri(Uri.fromFile(file)).build());player.setMediaItems(items);});
   ListenableFuture<SessionResult>[] command=new ListenableFuture[1];ins.runOnMainSync(()->{Bundle args=new Bundle();args.putInt("tracks",count);command[0]=player.sendCustomCommand(new SessionCommand("sleep",Bundle.EMPTY),args);});assertEquals(SessionResult.RESULT_SUCCESS,command[0].get(5,TimeUnit.SECONDS).resultCode);
   ins.runOnMainSync(()->{player.prepare();player.play();});Thread.sleep(500);if(skip)ins.runOnMainSync(player::seekToNextMediaItem);
   long began=System.currentTimeMillis(),deadline=began+18000;boolean[] playing={true};while(System.currentTimeMillis()<deadline){Thread.sleep(100);ins.runOnMainSync(()->playing[0]=player.getPlayWhenReady());if(!playing[0])break;}
   assertFalse("Track timer did not pause",playing[0]);assertTrue("Paused before natural ends",System.currentTimeMillis()-began>(count==1?1500:4500));ins.runOnMainSync(()->assertNull(player.getPlayerError()));
  }finally{ins.runOnMainSync(()->{Bundle cancel=new Bundle();cancel.putInt("minutes",0);player.sendCustomCommand(new SessionCommand("sleep",Bundle.EMPTY),cancel);player.pause();player.clearMediaItems();MediaController.releaseFuture(connection[0]);});file.delete();}
 }
 @Test public void stopsAfterCurrentNaturalEnd()throws Exception{run(1,false);}
 @Test public void manualSkipDoesNotConsumeRequestedCompletions()throws Exception{run(2,true);}
}
