package br.com.onda;
import android.content.*;
import android.os.Bundle;
import androidx.media3.common.*;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.session.SessionResult;
import com.google.common.util.concurrent.ListenableFuture;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
import java.util.*;
import java.util.concurrent.TimeUnit;

@androidx.media3.common.util.UnstableApi
public class PersonalDjTest {
 private final android.app.Instrumentation ins=getInstrumentation();
 private ListenableFuture<SessionResult> request(DjSession dj,String action){Bundle args=new Bundle();args.putString("action",action);ListenableFuture<SessionResult>[] future=new ListenableFuture[1];ins.runOnMainSync(()->future[0]=dj.request(args));return future[0];}
 @Test public void adjustingFuturePreservesCurrentPastPositionAndPausedState()throws Exception{
  Context c=ins.getTargetContext();List<MediaItem> library=LibraryStore.scan(c);library.removeIf(i->!LibraryStore.isLocal(i));assertTrue("Regression fixture needs at least four songs",library.size()>=4);
  ExoPlayer[] player={null};DjSession[] session={null};
  try{ins.runOnMainSync(()->{player[0]=new ExoPlayer.Builder(c).build();session[0]=new DjSession(c,player[0]);player[0].setMediaItems(new ArrayList<>(library.subList(0,3)),1,1234);});
   String current=library.get(1).mediaId,past=library.get(0).mediaId;
   SessionResult result=request(session[0],"variety").get(20,TimeUnit.SECONDS);assertTrue(result.extras.getString("message","").contains("ajustadas"));
   ins.runOnMainSync(()->{assertEquals(current,player[0].getCurrentMediaItem().mediaId);assertEquals(past,player[0].getMediaItemAt(0).mediaId);assertEquals(1234,player[0].getCurrentPosition());assertFalse(player[0].getPlayWhenReady());Set<String> ids=new HashSet<>();for(int i=0;i<player[0].getMediaItemCount();i++)assertTrue(ids.add(player[0].getMediaItemAt(i).mediaId));assertFalse(DjSession.reason(player[0].getMediaItemAt(2)).isEmpty());});
   SessionResult strict=request(session[0],"unique").get(20,TimeUnit.SECONDS);assertTrue(strict.extras.getString("message","").contains("ajustadas"));
   ins.runOnMainSync(()->{Set<String> artists=new HashSet<>();for(int i=0;i<player[0].getMediaItemCount();i++){String key=SearchText.normalize(player[0].getMediaItemAt(i).mediaMetadata.artist);assertTrue(artists.add(key));}assertEquals(current,player[0].getCurrentMediaItem().mediaId);assertEquals(1234,player[0].getCurrentPosition());});
   ins.runOnMainSync(()->{MediaItem currentItem=player[0].getCurrentMediaItem();player[0].setMediaItem(currentItem.buildUpon().setMediaMetadata(currentItem.mediaMetadata.buildUpon().setArtist("Artista sem outras faixas no teste").build()).build(),1234);});
   SessionResult noArtist=request(session[0],"artist").get(20,TimeUnit.SECONDS);assertTrue(noArtist.extras.getString("message","").contains("Não há outra música"));
   ins.runOnMainSync(()->{assertEquals(1,player[0].getMediaItemCount());assertEquals(1234,player[0].getCurrentPosition());assertFalse(player[0].getPlayWhenReady());});
   // This favorite is the only available artist; strict mode must not leave repeats queued.
   SharedPreferences prefs=c.getSharedPreferences("library",0);Set<String> saved=new HashSet<>(prefs.getStringSet("favorites",Collections.emptySet()));
   try{prefs.edit().putStringSet("favorites",Collections.singleton(current)).commit();ins.runOnMainSync(()->{MediaItem item=library.get(1);MediaItem marked=DjSession.explain(item,"Teste",DjPlanner.Mode.FAVORITES);player[0].setMediaItems(Arrays.asList(marked,marked),0,1234);});
    SessionResult exhausted=request(session[0],"unique").get(20,TimeUnit.SECONDS);assertTrue(exhausted.extras.getString("message","").contains("termina após"));ins.runOnMainSync(()->{assertEquals(1,player[0].getMediaItemCount());assertEquals(1234,player[0].getCurrentPosition());});
   }finally{prefs.edit().putStringSet("favorites",saved).commit();}
  }finally{ins.runOnMainSync(()->{if(session[0]!=null)session[0].close();if(player[0]!=null)player[0].release();});}
 }
 @Test public void travelExplainsChoicesAndEmptyFavoritesKeepTheQueue()throws Exception{
  Context c=ins.getTargetContext();SharedPreferences prefs=c.getSharedPreferences("library",0);Set<String> previous=new HashSet<>(prefs.getStringSet("favorites",Collections.emptySet()));ExoPlayer[] player={null};DjSession[] session={null};
  try{ins.runOnMainSync(()->{player[0]=new ExoPlayer.Builder(c).build();session[0]=new DjSession(c,player[0]);});
   SessionResult started=request(session[0],"travel").get(20,TimeUnit.SECONDS);assertTrue(started.extras.getString("message","").contains("iniciado"));List<String> before=new ArrayList<>();
   ins.runOnMainSync(()->{player[0].pause();assertTrue(player[0].getMediaItemCount()>0);assertFalse(DjSession.reason(player[0].getCurrentMediaItem()).isEmpty());for(int i=0;i<player[0].getMediaItemCount();i++)before.add(player[0].getMediaItemAt(i).mediaId);});
   SessionResult why=request(session[0],"explain").get(5,TimeUnit.SECONDS);assertFalse(why.extras.getString("message","").isEmpty());
   prefs.edit().putStringSet("favorites",new HashSet<>()).commit();SessionResult empty=request(session[0],"favorites_unique").get(20,TimeUnit.SECONDS);assertTrue(empty.extras.getString("message","").contains("mantida"));
   ins.runOnMainSync(()->{assertEquals(before.size(),player[0].getMediaItemCount());for(int i=0;i<before.size();i++)assertEquals(before.get(i),player[0].getMediaItemAt(i).mediaId);assertFalse(player[0].getPlayWhenReady());});
  }finally{prefs.edit().putStringSet("favorites",previous).commit();ins.runOnMainSync(()->{if(session[0]!=null)session[0].close();if(player[0]!=null)player[0].release();});}
 }
}
