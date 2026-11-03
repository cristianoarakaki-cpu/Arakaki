package br.com.onda;
import android.app.*;
import android.content.*;
import android.net.Uri;
import android.os.*;
import android.widget.*;
import androidx.media3.common.*;
import androidx.media3.session.MediaController;
import androidx.media3.session.*;
import com.google.common.util.concurrent.ListenableFuture;
import java.io.*;
import java.lang.reflect.Field;
import java.util.concurrent.TimeUnit;
import org.junit.*;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;

/** Deterministic real decoder/service tests. Provider extraction availability is not simulated as success. */
@androidx.media3.common.util.UnstableApi
public class YouTubeAudioTest {
 private final Instrumentation ins=getInstrumentation();private final Context c=ins.getTargetContext();
 private static final String SOURCE="https://www.youtube.com/watch?v=aqz-KE-bpKQ";
 private YouTubeActivity activity;private MediaController player;private ListenableFuture<MediaController> connection;private File audio;private YouTubeAudioPlayback.Resolver original;
 private Object field(String name)throws Exception{Field f=YouTubeActivity.class.getDeclaredField(name);f.setAccessible(true);return f.get(activity);}
 private interface Check{boolean ready()throws Exception;}
 private void waitFor(Check check)throws Exception{for(int n=0;n<300;n++){boolean[] ok={false};ins.runOnMainSync(()->{try{ok[0]=check.ready();}catch(Exception e){throw new RuntimeException(e);}});if(ok[0])return;Thread.sleep(50);}fail("Native YouTube audio did not reach expected state");}
 private void shell(String command)throws Exception{try(ParcelFileDescriptor p=ins.getUiAutomation().executeShellCommand(command);InputStream in=new ParcelFileDescriptor.AutoCloseInputStream(p)){while(in.read()!=-1){}}}
 @Before public void setup()throws Exception{original=YouTubeAudioPlayback.resolver;YouTubeAudio.clear(c);audio=AudioTestFixtures.tone(c,45000);ins.runOnMainSync(()->connection=new MediaController.Builder(c,new SessionToken(c,new ComponentName(c,PlaybackService.class))).buildAsync());player=connection.get(15,TimeUnit.SECONDS);ins.runOnMainSync(()->{player.setMediaItem(new MediaItem.Builder().setMediaId("previous-local-fixture").setUri(Uri.fromFile(audio)).build());player.prepare();player.play();});waitFor(()->player.isPlaying());}
 private void launch()throws Exception{activity=(YouTubeActivity)ins.startActivitySync(new Intent(c,YouTubeActivity.class).putExtra(YouTubeFavorites.EXTRA,SOURCE).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));waitFor(()->field("web")!=null&&((Button)field("listenAudio")).isEnabled());ins.runOnMainSync(()->((android.webkit.WebView)unchecked("web")).stopLoading());}
 private Object unchecked(String name){try{return field(name);}catch(Exception e){throw new RuntimeException(e);}}
 private void click(){ins.runOnMainSync(()->((Button)unchecked("listenAudio")).performClick());}
 @After public void after()throws Exception{shell("input keyevent 224");shell("wm dismiss-keyguard");ins.runOnMainSync(()->{if(activity!=null)activity.finish();if(player!=null){player.pause();player.stop();player.clearMediaItems();}if(connection!=null)MediaController.releaseFuture(connection);});ins.waitForIdleSync();YouTubeAudio.clear(c);c.getSharedPreferences("music_resume",0).edit().clear().commit();YouTubeAudioPlayback.resolver=original;if(audio!=null)audio.delete();}
 @Test public void selectedAudioKeepsPlayingScreenOffAndControlsNeverResumeOldMusic()throws Exception{
  YouTubeAudioPlayback.resolver=source->YouTubeAudio.item(source,"YouTube audio fixture",Uri.fromFile(audio).toString(),"audio/wav");launch();waitFor(()->!player.getPlayWhenReady());
  c.getSharedPreferences("music_resume",0).edit().putString("queue","[\"42\"]").putLong("position",12345).commit();click();waitFor(()->YouTubeAudio.is(player.getCurrentMediaItem())&&player.isPlaying()&&player.getCurrentPosition()>250);
  ins.runOnMainSync(()->{assertEquals(SOURCE,YouTubeAudio.source(player.getCurrentMediaItem()));assertEquals(1,player.getMediaItemCount());assertEquals("[\"42\"]",c.getSharedPreferences("music_resume",0).getString("queue",""));assertEquals(12345,c.getSharedPreferences("music_resume",0).getLong("position",0));});
  long[] at={0};ins.runOnMainSync(()->at[0]=player.getCurrentPosition());shell("input keyevent 223");Thread.sleep(2200);ins.runOnMainSync(()->{assertFalse(((PowerManager)c.getSystemService(Context.POWER_SERVICE)).isInteractive());assertTrue(player.isPlaying());assertTrue(player.getCurrentPosition()>at[0]+1000);assertTrue(YouTubeAudio.is(player.getCurrentMediaItem()));assertFalse(activity.isInPictureInPictureMode());assertNull(unchecked("web"));player.pause();});waitFor(()->!player.isPlaying());ins.runOnMainSync(()->player.play());waitFor(()->player.isPlaying());ins.runOnMainSync(()->assertEquals(SOURCE,YouTubeAudio.source(player.getCurrentMediaItem())));
  assertFalse(c.getSharedPreferences("youtube_audio",0).getAll().toString().contains(audio.getAbsolutePath()));
  try(OutputStream out=new FileOutputStream(new File(c.getFilesDir(),"youtube-native-audio.json"))){out.write("{\"realDecoderAndService\":true,\"screenOffContinues\":true,\"sameVideoAfterTransportPlay\":true,\"localQueuePreserved\":true,\"webViewDestroyed\":true,\"noAutomaticPip\":true,\"providerAvailabilityTested\":false}".getBytes("UTF-8"));}
 }
 @Test public void extractionFailureLeavesOldMusicPausedAndWritesReport()throws Exception{YouTubeAudioPlayback.resolver=source->{throw new IOException("Áudio indisponível na origem");};launch();waitFor(()->!player.getPlayWhenReady());click();waitFor(()->((TextView)field("status")).getText().toString().contains("Áudio indisponível na origem"));ins.runOnMainSync(()->{assertFalse(player.getPlayWhenReady());assertFalse(player.isPlaying());assertEquals("previous-local-fixture",player.getCurrentMediaItem().mediaId);});assertTrue(DownloadHistory.report(c).contains("Áudio indisponível na origem"));}
 @Test public void publicIdentityPersistsWithoutTemporaryStreamAndReturnCommandClearsMode()throws Exception{YouTubeAudioPlayback.resolver=source->YouTubeAudio.item(source,"YouTube audio fixture",Uri.fromFile(audio).toString(),"audio/wav");launch();click();waitFor(()->YouTubeAudio.is(player.getCurrentMediaItem())&&player.isPlaying());assertTrue(YouTubeAudio.active(c));assertEquals(SOURCE,YouTubeAudio.saved(c));ins.runOnMainSync(()->player.sendCustomCommand(new SessionCommand(YouTubeAudio.RESTORE,Bundle.EMPTY),Bundle.EMPTY));waitFor(()->!YouTubeAudio.active(c)&&!player.getPlayWhenReady()&&!YouTubeAudio.is(player.getCurrentMediaItem()));ins.runOnMainSync(()->assertFalse(YouTubeAudio.is(player.getCurrentMediaItem())));}
}
