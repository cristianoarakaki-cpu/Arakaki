package br.com.onda;
import android.app.*;
import android.content.*;
import android.net.Uri;
import android.os.*;
import android.widget.Switch;
import androidx.media3.common.*;
import androidx.media3.common.audio.AudioProcessor;
import androidx.media3.session.MediaController;
import androidx.media3.session.*;
import com.google.common.util.concurrent.ListenableFuture;
import java.nio.*;
import java.io.*;
import java.lang.reflect.Field;
import java.util.concurrent.TimeUnit;
import org.junit.*;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
@androidx.media3.common.util.UnstableApi
public class AudioEvolutionTest {
 private final Instrumentation ins=getInstrumentation();private final Context c=ins.getTargetContext();private Activity anchor,sound;private MediaController player;private ListenableFuture<MediaController> connection;private File file;private boolean oldLevel;
 private interface Check{boolean ready()throws Exception;}
 private void waitFor(Check check)throws Exception{for(int n=0;n<300;n++){boolean[] ready={false};ins.runOnMainSync(()->{try{ready[0]=check.ready();}catch(Exception e){throw new RuntimeException(e);}});if(ready[0])return;Thread.sleep(50);}fail("Audio evolution scenario timed out");}
 @Before public void before(){oldLevel=SpeechSettings.leveling(c);}
 @After public void after(){ins.runOnMainSync(()->{SpeechSettings.leveling(c,oldLevel);if(player!=null){player.pause();player.stop();player.clearMediaItems();player.sendCustomCommand(new SessionCommand(SpeechSettings.COMMAND,Bundle.EMPTY),Bundle.EMPTY);}if(sound!=null)sound.finish();if(anchor!=null)anchor.finish();if(connection!=null)MediaController.releaseFuture(connection);});ins.waitForIdleSync();if(file!=null)file.delete();}
 @Test public void fragmentedOriginalPcmUsesBulkBypassAndLevelingCanFadeBackToOriginal()throws Exception{SpeechProcessor processor=new SpeechProcessor();processor.configure(new AudioProcessor.AudioFormat(48000,2,C.ENCODING_PCM_16BIT));processor.flush();byte[] input=new byte[4096];new java.util.Random(112).nextBytes(input);ByteArrayOutputStream out=new ByteArrayOutputStream();for(int at=0;at<input.length;){int length=Math.min(13,input.length-at);ByteBuffer b=ByteBuffer.allocateDirect(length);b.put(input,at,length).flip();processor.queueInput(b);ByteBuffer result=processor.getOutput();while(result.hasRemaining())out.write(result.get());at+=length;}processor.queueEndOfStream();ByteBuffer tail=processor.getOutput();while(tail.hasRemaining())out.write(tail.get());assertArrayEquals(input,out.toByteArray());assertEquals(input.length,processor.bypassBytes);assertEquals(0,processor.levelFrames);assertEquals(0,processor.processedFrames);assertEquals(0,processor.quietFrames);processor.flush();processor.leveling(true);ByteBuffer tone=ByteBuffer.allocateDirect(48000*4).order(ByteOrder.LITTLE_ENDIAN);for(int n=0;n<48000;n++){short v=(short)(1200*Math.sin(2*Math.PI*440*n/48000));tone.putShort(v).putShort((short)(v/2));}tone.flip();processor.queueInput(tone);assertEquals(48000,processor.levelFrames);assertEquals(48000*4,processor.getOutput().remaining());processor.leveling(false);for(int i=0;i<3;i++){ByteBuffer b=ByteBuffer.allocateDirect(4096);processor.queueInput(b);processor.getOutput();}long at=processor.bypassBytes;ByteBuffer original=ByteBuffer.allocateDirect(4096);original.put(input).flip();processor.queueInput(original);ByteBuffer actual=processor.getOutput();byte[] copy=new byte[actual.remaining()];actual.get(copy);assertArrayEquals(input,copy);assertTrue(processor.bypassBytes>at);processor.reset();}
 @Test public void soundSwitchAppliesLevelingToActualMusicSessionWithoutRestartingTrack()throws Exception{SpeechSettings.leveling(c,false);anchor=ins.startActivitySync(new Intent(c,MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));waitFor(()->anchor.hasWindowFocus());file=AudioTestFixtures.tone(c,45000);ins.runOnMainSync(()->connection=new MediaController.Builder(c,new SessionToken(c,new ComponentName(c,PlaybackService.class))).buildAsync());player=connection.get(15,TimeUnit.SECONDS);ins.runOnMainSync(()->{player.setMediaItem(new MediaItem.Builder().setMediaId("audio-leveling-fixture").setUri(Uri.fromFile(file)).build());player.prepare();player.play();});waitFor(()->player.isPlaying());sound=ins.startActivitySync(new Intent(c,SoundActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));waitFor(()->sound.hasWindowFocus());ins.runOnMainSync(()->{try{Field f=SoundActivity.class.getDeclaredField("leveling");f.setAccessible(true);((Switch)f.get(sound)).setChecked(true);}catch(Exception e){throw new RuntimeException(e);}});Bundle state=null;for(int n=0;n<80;n++){ListenableFuture<SessionResult>[] future=new ListenableFuture[1];ins.runOnMainSync(()->future[0]=player.sendCustomCommand(new SessionCommand(SpeechSettings.STATUS,Bundle.EMPTY),Bundle.EMPTY));state=future[0].get(5,TimeUnit.SECONDS).extras;if(state.getBoolean("leveling")&&state.getLong("level_frames")>1000)break;Thread.sleep(100);}assertNotNull(state);assertTrue(state.getBoolean("leveling"));assertTrue(state.getLong("level_frames")>1000);assertTrue(Float.isFinite(state.getFloat("level_gain_db")));ins.runOnMainSync(()->{assertEquals("audio-leveling-fixture",player.getCurrentMediaItem().mediaId);assertTrue(player.isPlaying());assertTrue(player.getCurrentPosition()>0);});}
}
