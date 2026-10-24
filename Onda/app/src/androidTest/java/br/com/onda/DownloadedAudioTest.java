package br.com.onda;
import android.app.Instrumentation;
import android.content.*;
import android.widget.*;
import androidx.media3.session.MediaController;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
import java.lang.reflect.Field;
import java.util.*;

@androidx.media3.common.util.UnstableApi
public class DownloadedAudioTest {
 private static Object field(Object object,String name)throws Exception{Field f=object.getClass().getDeclaredField(name);f.setAccessible(true);return f.get(object);}
 @Test public void legacyLastAudioRetainsFavoriteIdentityAndVideosAreExcluded(){
  Context c=getInstrumentation().getTargetContext();SharedPreferences registry=c.getSharedPreferences("downloaded_audio",0),last=c.getSharedPreferences("downloads",0);
  String documents=registry.getString("documents","{}"),uri=last.getString("last_uri",""),mime=last.getString("last_mime",""),title=last.getString("last_title","");
  try{
   registry.edit().clear().commit();last.edit().putString("last_uri","content://fixture/audio").putString("last_mime","audio/mpeg").putString("last_title","Favorita antiga").commit();
   assertEquals("download:"+"content://fixture/audio".hashCode(),DownloadedAudio.read(c).get(0).mediaId);
   DownloadedAudio.remember(c,"content://fixture/audio","Favorita antiga","audio/mpeg");assertEquals(1,DownloadedAudio.read(c).size());
   DownloadedAudio.remember(c,"https://example.org/audio","Online","audio/mpeg");DownloadedAudio.remember(c,"content://fixture/video","Vídeo","video/mp4");assertEquals(1,DownloadedAudio.read(c).size());
   last.edit().putString("last_uri","content://fixture/video").putString("last_mime","video/mp4").commit();assertEquals(1,DownloadedAudio.read(c).size());
  }finally{registry.edit().putString("documents",documents).commit();last.edit().putString("last_uri",uri).putString("last_mime",mime).putString("last_title",title).commit();}
 }
 @Test public void downloadedFavoriteAppearsAndSurvivesReopening()throws Exception{
  Instrumentation ins=getInstrumentation();Context c=ins.getTargetContext();SharedPreferences registry=c.getSharedPreferences("downloaded_audio",0),library=c.getSharedPreferences("library",0);
  String documents=registry.getString("documents","{}");Set<String> favorites=new HashSet<>(library.getStringSet("favorites",Collections.emptySet()));MainActivity activity=null;
  try{
   DownloadedAudio.remember(c,"content://fixture/favorite-test","Download favorito teste","audio/mpeg");
   library.edit().putStringSet("favorites",new HashSet<>()).commit();
   activity=(MainActivity)ins.startActivitySync(new Intent(c,MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
   final MainActivity first=activity;
   long deadline=System.currentTimeMillis()+15000;while((field(first,"player")==null||!(Boolean)field(first,"libraryReady"))&&System.currentTimeMillis()<deadline)Thread.sleep(100);
   assertNotNull(field(first,"player"));ins.runOnMainSync(()->{try{
    MediaController player=(MediaController)field(first,"player");player.pause();player.setMediaItem(DownloadedAudio.read(c).stream().filter(i->i.mediaId.equals(DownloadedAudio.id("content://fixture/favorite-test"))).findFirst().get());
    ((Button)field(first,"favorite")).performClick();((Button)field(first,"favoritesTab")).performClick();
    assertTrue(((Map<?,?>)field(first,"rowViews")).containsKey(DownloadedAudio.id("content://fixture/favorite-test")));
   }catch(Exception e){throw new RuntimeException(e);}});
   ins.runOnMainSync(first::finish);ins.waitForIdleSync();
   activity=(MainActivity)ins.startActivitySync(new Intent(c,MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));final MainActivity reopened=activity;
   deadline=System.currentTimeMillis()+15000;while(!(Boolean)field(reopened,"libraryReady")&&System.currentTimeMillis()<deadline)Thread.sleep(100);
   ins.runOnMainSync(()->{try{((Button)field(reopened,"favoritesTab")).performClick();assertTrue(((Map<?,?>)field(reopened,"rowViews")).containsKey(DownloadedAudio.id("content://fixture/favorite-test")));}catch(Exception e){throw new RuntimeException(e);}});
  }finally{if(activity!=null){MainActivity a=activity;ins.runOnMainSync(a::finish);ins.waitForIdleSync();}registry.edit().putString("documents",documents).commit();library.edit().putStringSet("favorites",favorites).commit();}
 }
}
