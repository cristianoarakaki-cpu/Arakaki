package br.com.onda;

import android.app.*;import android.content.*;import android.net.Uri;import android.os.*;import android.service.notification.StatusBarNotification;import android.widget.*;
import androidx.media3.common.*;import androidx.media3.session.MediaController;import androidx.media3.session.SessionToken;
import com.google.common.util.concurrent.ListenableFuture;
import java.io.*;import java.util.*;import java.util.concurrent.*;import java.util.concurrent.atomic.AtomicInteger;
import org.junit.*;import static org.junit.Assert.*;import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;

/** Gates startup only, then runs the real PCM decoder while the Activity is stopped/destroyed. */
@androidx.media3.common.util.UnstableApi
public class ChapterBackgroundTest {
    private final Instrumentation ins=getInstrumentation();private final Context c=ins.getTargetContext();
    private Activity anchor;private AudioChaptersActivity screen;private MediaController player;private ListenableFuture<MediaController> connection;
    private File source,other;private Uri uri;private String stamp;private final CountDownLatch entered=new CountDownLatch(1),release=new CountDownLatch(1);private final AtomicInteger calls=new AtomicInteger();
    private interface Check {boolean ready()throws Exception;}
    private void waitFor(Check check)throws Exception{for(int i=0;i<400;i++){boolean[] yes={false};ins.runOnMainSync(()->{try{yes[0]=check.ready();}catch(Exception error){throw new RuntimeException(error);}});if(yes[0])return;Thread.sleep(50);}ChapterScanService.Snapshot state=ChapterScanService.state(c);fail("Timed out: "+(state==null?"no scan":state.phase+" "+state.message));}
    private Object field(Object target,String name)throws Exception{java.lang.reflect.Field f=target.getClass().getDeclaredField(name);f.setAccessible(true);return f.get(target);}
    private ChapterScanService service()throws Exception{java.lang.reflect.Field f=ChapterScanService.class.getDeclaredField("live");f.setAccessible(true);return (ChapterScanService)f.get(null);}
    private void shell(String command)throws Exception{try(ParcelFileDescriptor p=ins.getUiAutomation().executeShellCommand(command);InputStream in=new ParcelFileDescriptor.AutoCloseInputStream(p)){while(in.read()!=-1){}}}
    private StatusBarNotification notification(){for(StatusBarNotification n:((NotificationManager)c.getSystemService(Context.NOTIFICATION_SERVICE)).getActiveNotifications())if(n.getId()==ChapterScanService.NOTICE)return n;return null;}
    private MediaItem item(String id,File file){return new MediaItem.Builder().setMediaId(id).setUri(Uri.fromFile(file)).setMediaMetadata(new MediaMetadata.Builder().setTitle(id).build()).build();}
    @Before public void before()throws Exception{
        YouTubeAudio.clear(c);source=AudioTestFixtures.collection(c);other=AudioTestFixtures.tone(c,10000);uri=Uri.fromFile(source);stamp=AudioChapterStore.stamp(c,uri);
        AudioChapterStore.save(c,uri,stamp,new AudioChapterStore.Data(96600,Collections.singletonList(new AudioChapterStore.Chapter(0,"Divisões anteriores"))));
        anchor=ins.startActivitySync(new Intent(c,MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
        ins.runOnMainSync(()->connection=new MediaController.Builder(c,new SessionToken(c,new ComponentName(c,PlaybackService.class))).buildAsync());player=connection.get(10,TimeUnit.SECONDS);
        ins.runOnMainSync(()->{player.setRepeatMode(Player.REPEAT_MODE_OFF);player.setMediaItems(Arrays.asList(item("Coletânea em análise",source),item("Outro áudio",other)));player.prepare();player.pause();});waitFor(()->player.getPlaybackState()==Player.STATE_READY);
        ChapterScanService.scanner=(context,sourceUri,control)->{calls.incrementAndGet();entered.countDown();try{if(!release.await(20,TimeUnit.SECONDS))throw new IOException("Test gate timed out");}catch(InterruptedException error){Thread.currentThread().interrupt();throw new InterruptedIOException("Cancelado");}control.check();return AudioChapterScanner.scan(context,sourceUri,control);};
    }
    private void start()throws Exception{
        screen=(AudioChaptersActivity)ins.startActivitySync(new Intent(c,AudioChaptersActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));waitFor(()->field(screen,"data")!=null&&((Button)field(screen,"analyze")).isEnabled());
        ins.runOnMainSync(()->{try{assertTrue(((Button)field(screen,"analyze")).performClick());}catch(Exception error){throw new RuntimeException(error);}});
        assertTrue(entered.await(10,TimeUnit.SECONDS));waitFor(()->service()!=null&&ChapterScanService.state(c).running&&notification()!=null);
    }
    @After public void after()throws Exception{
        release.countDown();shell("input keyevent 224");shell("wm dismiss-keyguard");
        ins.runOnMainSync(()->{c.stopService(new Intent(c,ChapterScanService.class));if(screen!=null)screen.finish();if(player!=null){player.pause();player.stop();player.clearMediaItems();}if(anchor!=null)anchor.finish();if(connection!=null)MediaController.releaseFuture(connection);});
        waitFor(()->service()==null);ChapterScanService.scanner=AudioChapterScanner::scan;((NotificationManager)c.getSystemService(Context.NOTIFICATION_SERVICE)).cancel(ChapterScanService.NOTICE);c.getSharedPreferences("music_resume",0).edit().clear().commit();source.delete();other.delete();ins.waitForIdleSync();
    }
    @Test public void homeScreenOffAndDestroyedActivityStillFinishRealAnalysis()throws Exception{
        byte[] original=java.nio.file.Files.readAllBytes(source.toPath());start();PowerManager.WakeLock held=(PowerManager.WakeLock)field(service(),"wake");assertTrue(held.isHeld());
        assertTrue((notification().getNotification().flags&Notification.FLAG_ONGOING_EVENT)!=0);
        if(Build.VERSION.SDK_INT>=29){int type=service().getForegroundServiceType();assertEquals(Build.VERSION.SDK_INT>=35?android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROCESSING:android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,type);}
        shell("input keyevent 3");waitFor(()->!(Boolean)field(screen,"started"));shell("input keyevent 223");
        ins.runOnMainSync(()->screen.finish());waitFor(()->screen.isDestroyed());assertTrue(ChapterScanService.state(c).running);assertTrue(held.isHeld());assertFalse(((PowerManager)c.getSystemService(Context.POWER_SERVICE)).isInteractive());
        release.countDown();waitFor(()->"done".equals(ChapterScanService.state(c).phase)&&service()==null);assertFalse(held.isHeld());
        AudioChapterStore.Data saved=AudioChapterStore.load(c,uri,stamp,96600);assertEquals(3,saved.chapters.size());assertEquals(32650,saved.chapters.get(1).start,300);assertArrayEquals(original,java.nio.file.Files.readAllBytes(source.toPath()));assertEquals(1,calls.get());
        shell("input keyevent 224");shell("wm dismiss-keyguard");ins.runOnMainSync(()->anchor.finish());waitFor(()->anchor.isDestroyed());anchor=ins.startActivitySync(new Intent(c,MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
        Instrumentation.ActivityMonitor monitor=ins.addMonitor(AudioChaptersActivity.class.getName(),null,false);notification().getNotification().contentIntent.send();screen=(AudioChaptersActivity)monitor.waitForActivityWithTimeout(10000);ins.removeMonitor(monitor);assertNotNull(screen);
        waitFor(()->field(screen,"data")!=null&&!(Boolean)field(screen,"loading")&&screen.hasWindowFocus());ins.waitForIdleSync();Thread.sleep(250);ins.runOnMainSync(()->{try{assertEquals(3,((ListView)field(screen,"list")).getCount());assertFalse((Boolean)field(screen,"busy"));assertEquals("Coletânea em análise",player.getCurrentMediaItem().mediaId);assertFalse(player.getPlayWhenReady());assertEquals(2,player.getMediaItemCount());}catch(Exception error){throw new RuntimeException(error);}});
        android.graphics.Bitmap bitmap=ins.getUiAutomation().takeScreenshot();try(OutputStream out=new FileOutputStream(new File(c.getFilesDir(),"chapter-background.png"))){assertNotNull(bitmap);bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG,100,out);}finally{if(bitmap!=null)bitmap.recycle();}
    }
    @Test public void notificationCancellationPreservesSavedMarkersAndReleasesWake()throws Exception{
        start();PowerManager.WakeLock held=(PowerManager.WakeLock)field(service(),"wake");shell("input keyevent 3");waitFor(()->!(Boolean)field(screen,"started"));assertTrue(ChapterScanService.state(c).running);
        Notification notification=notification().getNotification();assertEquals("Cancelar",notification.actions[0].title.toString());notification.actions[0].actionIntent.send();
        waitFor(()->"cancelled".equals(ChapterScanService.state(c).phase)&&service()==null);assertFalse(held.isHeld());AudioChapterStore.Data saved=AudioChapterStore.load(c,uri,stamp,96600);assertEquals(1,saved.chapters.size());assertEquals("Divisões anteriores",saved.chapters.get(0).title);
    }
    @Test public void changingCurrentAudioDoesNotApplyResultToWrongFileOrStartDuplicate()throws Exception{
        Uri otherUri=Uri.fromFile(other);String otherStamp=AudioChapterStore.stamp(c,otherUri);AudioChapterStore.save(c,otherUri,otherStamp,new AudioChapterStore.Data(10000,Collections.singletonList(new AudioChapterStore.Chapter(0,"Outro preservado"))));start();
        ins.runOnMainSync(()->player.seekToDefaultPosition(1));waitFor(()->otherUri.equals(field(screen,"owner"))&&!(Boolean)field(screen,"loading"));
        ins.runOnMainSync(()->{try{assertFalse(((Button)field(screen,"analyze")).isEnabled());}catch(Exception error){throw new RuntimeException(error);}ChapterScanService.start(c,otherUri,"Outro áudio","Outro áudio",10000);});
        shell("input keyevent 3");release.countDown();waitFor(()->"done".equals(ChapterScanService.state(c).phase)&&service()==null);assertEquals(1,calls.get());assertEquals(3,AudioChapterStore.load(c,uri,stamp,96600).chapters.size());assertEquals("Outro preservado",AudioChapterStore.load(c,otherUri,otherStamp,10000).chapters.get(0).title);ins.runOnMainSync(()->{assertEquals("Outro áudio",player.getCurrentMediaItem().mediaId);assertFalse(player.getPlayWhenReady());});
    }
    @Test public void systemStopDoesNotRestartOrReplacePreviousMarkers()throws Exception{
        start();PowerManager.WakeLock held=(PowerManager.WakeLock)field(service(),"wake");ins.runOnMainSync(()->c.stopService(new Intent(c,ChapterScanService.class)));waitFor(()->service()==null&&"interrupted".equals(ChapterScanService.state(c).phase));assertFalse(held.isHeld());assertEquals("Divisões anteriores",AudioChapterStore.load(c,uri,stamp,96600).chapters.get(0).title);assertEquals(1,calls.get());
    }
}
