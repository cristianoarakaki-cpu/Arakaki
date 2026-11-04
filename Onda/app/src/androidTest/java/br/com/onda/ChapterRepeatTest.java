package br.com.onda;

import android.app.*;
import android.content.*;
import android.net.Uri;
import android.os.*;
import android.provider.MediaStore;
import android.widget.*;
import androidx.media3.common.*;
import androidx.media3.session.*;
import androidx.media3.session.MediaController;
import com.google.common.util.concurrent.ListenableFuture;
import java.io.*;
import java.util.*;
import java.util.concurrent.TimeUnit;
import org.junit.*;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;

@androidx.media3.common.util.UnstableApi
public class ChapterRepeatTest {
    private final Instrumentation ins=getInstrumentation();
    private final Context c=ins.getTargetContext();
    private Activity anchor;
    private AudioChaptersActivity screen;
    private MediaController player;
    private ListenableFuture<MediaController> connection;
    private File file;
    private Uri stored;
    private AudioChapterStore.Data markers;
    private interface Check{boolean ready()throws Exception;}
    private void waitFor(Check check)throws Exception{
        for(int n=0;n<400;n++){
            boolean[] ready={false};
            ins.runOnMainSync(()->{try{ready[0]=check.ready();}catch(Exception error){throw new RuntimeException(error);}});
            if(ready[0])return;
            Thread.sleep(50);
        }
        String[] state={"disconnected"};
        ins.runOnMainSync(()->{if(player!=null&&player.isConnected()){MediaItem item=player.getCurrentMediaItem();state[0]="state="+player.getPlaybackState()+" playing="+player.isPlaying()+" ready="+player.getPlayWhenReady()+" repeat="+player.getRepeatMode()+" position="+player.getCurrentPosition()+" duration="+player.getDuration()+" selected="+AudioChapterPlayback.selected(item)+" clipped="+AudioChapterPlayback.clipped(item)+" start="+AudioChapterPlayback.start(item)+" end="+AudioChapterPlayback.end(item)+" error="+player.getPlayerError();}});
        fail("Chapter repeat scenario timed out: "+state[0]);
    }
    private Object field(Object target,String name)throws Exception{
        java.lang.reflect.Field f=target.getClass().getDeclaredField(name);f.setAccessible(true);return f.get(target);
    }
    private void shell(String command)throws Exception{
        try(ParcelFileDescriptor p=ins.getUiAutomation().executeShellCommand(command);
            InputStream in=new ParcelFileDescriptor.AutoCloseInputStream(p)){while(in.read()!=-1){}}
    }
    private void connect()throws Exception{
        anchor=ins.startActivitySync(new Intent(c,MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
        waitFor(()->anchor.hasWindowFocus());
        ins.runOnMainSync(()->connection=new MediaController.Builder(c,new SessionToken(c,new ComponentName(c,PlaybackService.class))).buildAsync());
        player=connection.get(15,TimeUnit.SECONDS);
    }
    @Before public void before()throws Exception{
        YouTubeAudio.clear(c);file=AudioTestFixtures.collection(c);
        markers=new AudioChapterStore.Data(96600,Arrays.asList(new AudioChapterStore.Chapter(0,"Primeira"),new AudioChapterStore.Chapter(32650,"Segunda"),new AudioChapterStore.Chapter(65450,"Última")));
        AudioChapterStore.save(c,Uri.fromFile(file),AudioChapterStore.stamp(c,Uri.fromFile(file)),markers);
        connect();
    }
    @After public void after()throws Exception{
        shell("input keyevent 224");shell("wm dismiss-keyguard");
        ins.runOnMainSync(()->{
            if(screen!=null)screen.finish();
            if(player!=null&&player.isConnected()){player.pause();player.stop();player.clearMediaItems();player.setRepeatMode(Player.REPEAT_MODE_OFF);}
            if(anchor!=null)anchor.finish();
            if(connection!=null)MediaController.releaseFuture(connection);
        });
        ins.waitForIdleSync();c.getSharedPreferences("music_resume",0).edit().clear().commit();
        if(stored!=null)c.getContentResolver().delete(stored,null,null);
        if(file!=null)file.delete();
    }
    private MediaItem item(String id,Uri uri){return new MediaItem.Builder().setMediaId(id).setUri(uri)
            .setMediaMetadata(new MediaMetadata.Builder().setTitle("Coletânea teste").build()).build();}
    private void choose(int index)throws Exception{
        screen=(AudioChaptersActivity)ins.startActivitySync(new Intent(c,AudioChaptersActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
        waitFor(()->screen.hasWindowFocus()&&field(screen,"data")!=null&&!(Boolean)field(screen,"loading"));
        ins.runOnMainSync(()->{try{ListView list=(ListView)field(screen,"list");list.performItemClick(list.getAdapter().getView(index,null,list),index,index);}catch(Exception error){throw new RuntimeException(error);}});
        waitFor(()->AudioChapterPlayback.selected(player.getCurrentMediaItem())&&AudioChapterPlayback.start(player.getCurrentMediaItem())==markers.chapters.get(index).start);
        ins.runOnMainSync(()->screen.finish());waitFor(()->anchor.hasWindowFocus());
    }
    private void repeat()throws Exception{
        ins.runOnMainSync(()->{try{Button button=(Button)field(anchor,"repeat");assertTrue(button.isEnabled());assertTrue(button.performClick());}catch(Exception error){throw new RuntimeException(error);}});
    }
    @Test public void realMusicButtonLoopsMiddleAndLastChapterScreenOffWithoutChangingOriginalOrQueue()throws Exception{
        Uri uri=Uri.fromFile(file);byte[] original=java.nio.file.Files.readAllBytes(file.toPath());
        ins.runOnMainSync(()->{player.setRepeatMode(Player.REPEAT_MODE_OFF);player.setMediaItems(Arrays.asList(item("701",uri),item("702",uri)));player.prepare();});
        waitFor(()->player.getPlaybackState()==Player.STATE_READY);choose(1);
        waitFor(()->player.isPlaying()&&player.getCurrentPosition()>=32650);repeat();
        waitFor(()->player.isPlaying()&&AudioChapterPlayback.clipped(player.getCurrentMediaItem())&&player.getDuration()==32800);
        shell("input keyevent 223");ins.runOnMainSync(()->player.seekTo(player.getDuration()-150));
        waitFor(()->player.isPlaying()&&player.getCurrentPosition()>500&&player.getCurrentPosition()<4000);
        ins.runOnMainSync(()->{assertFalse(((PowerManager)c.getSystemService(Context.POWER_SERVICE)).isInteractive());assertEquals(32650,AudioChapterPlayback.start(player.getCurrentMediaItem()));assertEquals(0,player.getCurrentMediaItemIndex());assertEquals(2,player.getMediaItemCount());});
        shell("input keyevent 224");shell("wm dismiss-keyguard");waitFor(()->anchor.hasWindowFocus());choose(2);
        waitFor(()->player.isPlaying()&&AudioChapterPlayback.clipped(player.getCurrentMediaItem())&&player.getDuration()==31150);
        ins.runOnMainSync(()->player.seekTo(player.getDuration()-100));
        waitFor(()->player.isPlaying()&&player.getCurrentPosition()>300&&player.getCurrentPosition()<4000);
        ins.runOnMainSync(()->{assertEquals(65450,AudioChapterPlayback.start(player.getCurrentMediaItem()));assertEquals(uri,player.getCurrentMediaItem().localConfiguration.uri);});
        repeat();waitFor(()->player.getRepeatMode()==Player.REPEAT_MODE_OFF&&!AudioChapterPlayback.clipped(player.getCurrentMediaItem())&&player.getDuration()==96600&&player.getCurrentPosition()>=65450);
        waitFor(()->c.getSharedPreferences("music_resume",0).getLong("position",0)>=65450);
        assertEquals("[\"701\",\"702\"]",c.getSharedPreferences("music_resume",0).getString("queue",""));
        assertArrayEquals(original,java.nio.file.Files.readAllBytes(file.toPath()));
    }
    @Test public void restoreRequiresMatchingOriginalAndCurrentMarkerBoundaries()throws Exception{
        Uri uri=Uri.fromFile(file);MediaItem base=item("701",uri);
        MediaItem chosen=AudioChapterPlayback.configure(AudioChapterPlayback.select(base,markers,1,AudioChapterStore.stamp(c,uri)),true);
        assertEquals(33150,AudioChapterPlayback.absolute(chosen,500));
        assertEquals(500,AudioChapterPlayback.position(chosen,33150));
        assertEquals(0,AudioChapterPlayback.position(chosen,100));
        String encoded=AudioChapterPlayback.encode(chosen);
        assertTrue(AudioChapterPlayback.selected(AudioChapterPlayback.restore(c,base,encoded)));
        assertFalse(AudioChapterPlayback.selected(AudioChapterPlayback.restore(c,item("702",uri),encoded)));
        assertFalse(AudioChapterPlayback.selected(AudioChapterPlayback.restore(c,base,"broken JSON")));
        AudioChapterStore.save(c,uri,AudioChapterStore.stamp(c,uri),new AudioChapterStore.Data(96600,Arrays.asList(new AudioChapterStore.Chapter(0,"Inteiro"))));
        assertFalse(AudioChapterPlayback.selected(AudioChapterPlayback.restore(c,base,encoded)));
    }
    @Test public void actualServiceRestartRestoresSelectedChapterWithAbsoluteBookmark()throws Exception{
        ContentValues values=new ContentValues();values.put(MediaStore.Audio.Media.DISPLAY_NAME,"onda-chapter-repeat-"+System.nanoTime()+".wav");values.put(MediaStore.Audio.Media.MIME_TYPE,"audio/wav");values.put(MediaStore.Audio.Media.RELATIVE_PATH,"Music/OndaTests");values.put(MediaStore.Audio.Media.IS_PENDING,1);values.put(MediaStore.Audio.Media.IS_MUSIC,1);values.put(MediaStore.Audio.Media.DURATION,96600);
        stored=c.getContentResolver().insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,values);assertNotNull(stored);
        try(InputStream in=new FileInputStream(file);OutputStream out=c.getContentResolver().openOutputStream(stored)){byte[] buffer=new byte[8192];int n;while((n=in.read(buffer))!=-1)out.write(buffer,0,n);}
        values.clear();values.put(MediaStore.Audio.Media.IS_PENDING,0);c.getContentResolver().update(stored,values,null,null);
        String id=String.valueOf(ContentUris.parseId(stored));waitFor(()->LibraryStore.scan(c).stream().anyMatch(m->m.mediaId.equals(id)));
        String stamp=AudioChapterStore.stamp(c,stored);AudioChapterStore.save(c,stored,stamp,markers);
        MediaItem selected=AudioChapterPlayback.configure(AudioChapterPlayback.select(item(id,stored),markers,1,stamp),true);
        ins.runOnMainSync(()->{player.setRepeatMode(Player.REPEAT_MODE_ONE);player.setMediaItem(selected,900);player.prepare();player.play();});
        waitFor(()->player.isPlaying()&&player.getCurrentPosition()>1000);ins.runOnMainSync(()->player.pause());
        waitFor(()->c.getSharedPreferences("music_resume",0).getLong("position",0)>33650&&!c.getSharedPreferences("music_resume",0).getString("chapter","").isEmpty());
        long absolute=c.getSharedPreferences("music_resume",0).getLong("position",0);
        ins.runOnMainSync(()->{anchor.finish();MediaController.releaseFuture(connection);});ins.waitForIdleSync();player=null;connection=null;anchor=null;
        c.stopService(new Intent(c,PlaybackService.class));
        waitFor(()->((ActivityManager)c.getSystemService(Context.ACTIVITY_SERVICE)).getRunningServices(Integer.MAX_VALUE).stream().noneMatch(s->s.service.getClassName().equals(PlaybackService.class.getName())));
        connect();waitFor(()->player.getCurrentMediaItem()!=null&&player.getCurrentMediaItem().mediaId.equals(id)&&player.getRepeatMode()==Player.REPEAT_MODE_ONE&&AudioChapterPlayback.clipped(player.getCurrentMediaItem()));
        ins.runOnMainSync(()->{assertFalse(player.getPlayWhenReady());assertEquals(absolute,AudioChapterPlayback.absolute(player.getCurrentMediaItem(),player.getCurrentPosition()),500);player.prepare();player.play();});
        waitFor(()->player.isPlaying()&&player.getDuration()==32800);
        ins.runOnMainSync(()->assertEquals(stored,player.getCurrentMediaItem().localConfiguration.uri));
    }
}
