package br.com.onda;
import android.content.*;
import android.os.Bundle;
import androidx.media3.common.*;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.session.*;
import com.google.common.util.concurrent.ListenableFuture;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
import java.util.*;
import java.util.concurrent.TimeUnit;

@androidx.media3.common.util.UnstableApi
public class DjMemoryIntegrationTest {
 private final android.app.Instrumentation ins=getInstrumentation();
 private ListenableFuture<SessionResult> request(DjSession dj,String action){Bundle args=new Bundle();args.putString("action",action);ListenableFuture<SessionResult>[] future=new ListenableFuture[1];ins.runOnMainSync(()->future[0]=dj.request(args));return future[0];}
 @Test public void aAvoidPreferencePreservesPlayingItemAndFavorites()throws Exception{
  Context c=ins.getTargetContext();SharedPreferences prefs=c.getSharedPreferences("dj_preferences",0),favorites=c.getSharedPreferences("library",0);Set<String> before=DjSession.avoided(c),favoriteBefore=new HashSet<>(favorites.getStringSet("favorites",Collections.emptySet()));
  List<MediaItem> library=LibraryStore.scan(c);library.removeIf(i->!LibraryStore.isLocal(i));assertTrue(library.size()>=4);ExoPlayer[] player={null};DjSession[] dj={null};String id=library.get(0).mediaId;
  try{prefs.edit().remove("avoided").commit();ins.runOnMainSync(()->{player[0]=new ExoPlayer.Builder(c).build();dj[0]=new DjSession(c,player[0]);MediaItem first=DjSession.explain(library.get(0),"Teste",DjPlanner.Mode.PERSONAL);player[0].setMediaItems(Arrays.asList(first,library.get(1),first),0,5000);});
   request(dj[0],"avoid").get(10,TimeUnit.SECONDS);assertTrue(DjSession.avoided(c).contains(id));assertEquals(favoriteBefore,favorites.getStringSet("favorites",Collections.emptySet()));
   ins.runOnMainSync(()->{assertEquals(id,player[0].getCurrentMediaItem().mediaId);assertEquals(5000,player[0].getCurrentPosition());assertFalse(player[0].getPlayWhenReady());assertEquals(2,player[0].getMediaItemCount());});
   request(dj[0],"start").get(20,TimeUnit.SECONDS);ins.runOnMainSync(()->{player[0].pause();for(int i=0;i<player[0].getMediaItemCount();i++)assertNotEquals(id,player[0].getMediaItemAt(i).mediaId);});
   request(dj[0],"reset_avoid").get(10,TimeUnit.SECONDS);assertTrue(DjSession.avoided(c).isEmpty());assertTrue(DjSession.describe(c,library).stream().anyMatch(song->song.id.equals(id)));
  }finally{prefs.edit().putStringSet("avoided",before).commit();ins.runOnMainSync(()->{if(dj[0]!=null)dj[0].close();if(player[0]!=null)player[0].release();});}
 }
 @Test public void zRealServicePersistsMixedQueueAndReasonForProcessRestart()throws Exception{
  Context c=ins.getTargetContext();List<MediaItem> local=LibraryStore.scan(c);local.removeIf(i->!LibraryStore.isLocal(i));assertFalse(local.isEmpty());MediaItem first=local.get(0);String uri=first.localConfiguration.uri.toString(),downloadId=DownloadedAudio.id(uri);
  c.getSharedPreferences("ci_dj_memory",0).edit().putString("original_documents",c.getSharedPreferences("downloaded_audio",0).getString("documents","{}")).putString("download_id",downloadId).putString("local_id",first.mediaId).commit();
  DownloadedAudio.remember(c,uri,"Retomada download CI","audio/mpeg");MediaItem download=DownloadedAudio.read(c).stream().filter(i->i.mediaId.equals(downloadId)).findFirst().get();ListenableFuture<MediaController>[] connection=new ListenableFuture[1];
  ins.runOnMainSync(()->connection[0]=new MediaController.Builder(c,new SessionToken(c,new ComponentName(c,PlaybackService.class))).buildAsync());MediaController player=connection[0].get(15,TimeUnit.SECONDS);
  try{ins.runOnMainSync(()->{player.pause();player.setShuffleModeEnabled(false);player.setRepeatMode(Player.REPEAT_MODE_OFF);player.setMediaItems(Arrays.asList(DjSession.explain(first,"Faixa local do teste",DjPlanner.Mode.TRAVEL),DjSession.explain(download,"Preferência salva no teste",DjPlanner.Mode.TRAVEL)),1,12000);});
   SharedPreferences resume=c.getSharedPreferences("music_resume",0);long deadline=System.currentTimeMillis()+10000;while(System.currentTimeMillis()<deadline&&(!MusicResume.decode(resume.getString("queue","[]")).contains(downloadId)||resume.getLong("position",0)!=12000))Thread.sleep(100);
   assertEquals(Arrays.asList(first.mediaId,downloadId),MusicResume.decode(resume.getString("queue","[]")));assertEquals(1,resume.getInt("index",-1));assertEquals(12000,resume.getLong("position",0));assertEquals("Preferência salva no teste",DjMemory.decode(resume.getString("dj_context","{}")).get(downloadId).reason);
  }finally{ins.runOnMainSync(()->MediaController.releaseFuture(connection[0]));}
 }
}
