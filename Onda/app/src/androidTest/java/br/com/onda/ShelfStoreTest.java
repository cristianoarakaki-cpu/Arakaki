package br.com.onda;
import android.content.*;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
@androidx.media3.common.util.UnstableApi
public class ShelfStoreTest {
 @Test public void collectionAndNoteSurviveRepeatedPlaybackWrites(){Context c=getInstrumentation().getTargetContext();SharedPreferences p=c.getSharedPreferences("media_shelf",0);String previous=p.getString("data",null);try{p.edit().clear().commit();final String[] ids=new String[2];assertTrue(ShelfStore.edit(c,s->{MediaShelf.Item item=s.touch("video","content://shelf/test","Aula",6000,60000,1);MediaShelf.Collection group=s.create("Curso");ids[0]=item.id;ids[1]=group.id;return s.add(group.id,item.id)&&s.note(item.id,"",6000,"Preservar");}));for(int i=0;i<20;i++)ShelfStore.remember(c,"video","content://shelf/test","",7000+i,60000);MediaShelf s=ShelfStore.read(c);assertEquals("Aula",s.items.get(ids[0]).title);assertEquals(7019,s.items.get(ids[0]).position);assertEquals(6000,s.items.get(ids[0]).notes.get(0).at);assertEquals("Preservar",s.items.get(ids[0]).notes.get(0).text);assertTrue(s.collections.get(ids[1]).items.contains(ids[0]));}finally{SharedPreferences.Editor e=p.edit();if(previous==null)e.remove("data");else e.putString("data",previous);e.commit();}}
 @Test public void naturallyCompletedAudioRestartsAtZeroInTheJournal()throws Exception{
  android.app.Instrumentation ins=getInstrumentation();Context c=ins.getTargetContext();SharedPreferences prefs=c.getSharedPreferences("media_shelf",0);String previous=prefs.getString("data",null);
  com.google.common.util.concurrent.ListenableFuture<androidx.media3.session.MediaController> future=new androidx.media3.session.MediaController.Builder(c,new androidx.media3.session.SessionToken(c,new ComponentName(c,PlaybackService.class))).buildAsync();
  androidx.media3.session.MediaController player=future.get(15,java.util.concurrent.TimeUnit.SECONDS);
  try{java.util.List<androidx.media3.common.MediaItem> library=LibraryStore.scan(c);androidx.media3.common.MediaItem first=library.stream().filter(i->"Onda-Audio".contentEquals(i.mediaMetadata.title)).findFirst().get(),second=library.stream().filter(i->"DJ-2".contentEquals(i.mediaMetadata.title)).findFirst().get();
   ins.runOnMainSync(()->{player.setShuffleModeEnabled(false);player.setRepeatMode(androidx.media3.common.Player.REPEAT_MODE_OFF);android.os.Bundle cancel=new android.os.Bundle();cancel.putInt("minutes",0);player.sendCustomCommand(new androidx.media3.session.SessionCommand("sleep",android.os.Bundle.EMPTY),cancel);player.setMediaItems(java.util.Arrays.asList(first,second),0,Math.max(0,LibraryStore.number(first,"durationMs")-3000));player.prepare();player.play();});
   boolean[] advanced={false};long end=System.currentTimeMillis()+12000;while(System.currentTimeMillis()<end){ins.runOnMainSync(()->advanced[0]=player.getCurrentMediaItem()!=null&&second.mediaId.equals(player.getCurrentMediaItem().mediaId));if(advanced[0])break;Thread.sleep(100);}assertTrue("Real audio did not advance to the next track",advanced[0]);
   MediaShelf.Item entry=ShelfStore.read(c).items.values().stream().filter(i->i.type.equals("audio")&&i.uri.equals(first.localConfiguration.uri.toString())).findFirst().get();assertEquals("Completed files must restart instead of retaining their last checkpoint",0,entry.position);
  }finally{ins.runOnMainSync(()->{player.pause();player.clearMediaItems();});ins.waitForIdleSync();androidx.media3.session.MediaController.releaseFuture(future);SharedPreferences.Editor edit=prefs.edit();if(previous==null)edit.remove("data");else edit.putString("data",previous);edit.commit();}
 }
}
