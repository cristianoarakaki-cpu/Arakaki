package br.com.onda;
import android.content.*;
import android.net.Uri;
import android.os.*;
import androidx.media3.common.*;
import androidx.media3.session.*;
import com.google.common.util.concurrent.ListenableFuture;
import java.io.*;
import java.util.concurrent.TimeUnit;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
@androidx.media3.common.util.UnstableApi
public class SpeechPlaybackTest {
 @Test public void actualPlayerProcessesSpeechSkipsSilenceAndNeverAutoStartsFromSettings()throws Exception{
  android.app.Instrumentation ins=getInstrumentation();Context c=ins.getTargetContext();boolean oldVoice=SpeechSettings.voice(c),oldSilence=SpeechSettings.silence(c);File file=File.createTempFile("onda-speech-",".wav",c.getCacheDir());try(InputStream in=ins.getContext().getAssets().open("speech.wav");OutputStream out=new FileOutputStream(file)){byte[] b=new byte[8192];int n;while((n=in.read(b))>0)out.write(b,0,n);}
  ListenableFuture<MediaController>[] connection=new ListenableFuture[1];ins.runOnMainSync(()->connection[0]=new MediaController.Builder(c,new SessionToken(c,new ComponentName(c,PlaybackService.class))).buildAsync());MediaController player=connection[0].get(15,TimeUnit.SECONDS);ListenableFuture<SessionResult>[] result=new ListenableFuture[1];
  try{ins.runOnMainSync(()->{player.pause();player.setRepeatMode(Player.REPEAT_MODE_OFF);player.setShuffleModeEnabled(false);Bundle cancel=new Bundle();cancel.putInt("minutes",0);player.sendCustomCommand(new SessionCommand("sleep",Bundle.EMPTY),cancel);player.setMediaItem(new MediaItem.Builder().setMediaId("speech-fixture").setUri(Uri.fromFile(file)).build());player.prepare();SpeechSettings.save(c,true,true);result[0]=player.sendCustomCommand(new SessionCommand(SpeechSettings.COMMAND,Bundle.EMPTY),Bundle.EMPTY);});assertEquals(SessionResult.RESULT_SUCCESS,result[0].get(5,TimeUnit.SECONDS).resultCode);ins.runOnMainSync(()->{assertFalse(player.getPlayWhenReady());assertEquals(0,player.getCurrentPosition());});
   long started=SystemClock.elapsedRealtime();ins.runOnMainSync(player::play);boolean[] ended={false};while(SystemClock.elapsedRealtime()-started<10000){ins.runOnMainSync(()->ended[0]=player.getPlaybackState()==Player.STATE_ENDED);if(ended[0])break;Thread.sleep(100);}assertTrue("Twelve-second fixture must finish sooner by skipping its eight seconds of silence",ended[0]);assertTrue(SystemClock.elapsedRealtime()-started<10000);
   ins.runOnMainSync(()->result[0]=player.sendCustomCommand(new SessionCommand(SpeechSettings.STATUS,Bundle.EMPTY),Bundle.EMPTY));Bundle status=result[0].get(5,TimeUnit.SECONDS).extras;assertTrue(status.getBoolean("voice"));assertTrue(status.getBoolean("silence"));assertTrue("The actual AudioSink must feed PCM through the speech processor",status.getLong("frames")>0);
   ins.runOnMainSync(()->{player.pause();SpeechSettings.save(c,false,false);result[0]=player.sendCustomCommand(new SessionCommand(SpeechSettings.COMMAND,Bundle.EMPTY),Bundle.EMPTY);});Bundle off=result[0].get(5,TimeUnit.SECONDS).extras;assertFalse(off.getBoolean("voice"));assertFalse(off.getBoolean("silence"));ins.runOnMainSync(()->assertFalse(player.getPlayWhenReady()));
  }finally{ins.runOnMainSync(()->{player.pause();player.clearMediaItems();SpeechSettings.save(c,oldVoice,oldSilence);player.sendCustomCommand(new SessionCommand(SpeechSettings.COMMAND,Bundle.EMPTY),Bundle.EMPTY);MediaController.releaseFuture(connection[0]);});file.delete();}
 }
}
