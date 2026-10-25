package br.com.onda;
import android.content.*;
import android.net.Uri;
import android.provider.DocumentsContract;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
import java.util.*;
public class VideoMomentStoreTest {
 private final Context c=getInstrumentation().getTargetContext();
 private void restore(SharedPreferences p,Map<String,?> before){SharedPreferences.Editor e=p.edit().clear();for(Map.Entry<String,?> v:before.entrySet())if(v.getValue() instanceof String)e.putString(v.getKey(),(String)v.getValue());e.commit();}
 @Test public void scenesKeepIdsAcrossRenameAndDeletionAndNeverEvictOtherFiles(){SharedPreferences p=c.getSharedPreferences("video_moments",0);Map<String,?> before=p.getAll();try{p.edit().clear().commit();Uri uri=Uri.parse("content://fixture/video/1");VideoMoments.Moment item=VideoMomentStore.add(c,uri,"Meu trecho",5000);assertNotNull(item);assertTrue(VideoMomentStore.annotate(c,uri,item.id,"Minha anotação\nLinha 2"));assertTrue(VideoMomentStore.rename(c,uri,item.id,"Refrão"));assertEquals(item.id,VideoMomentStore.read(c,uri).get(0).id);assertEquals(5000,VideoMomentStore.read(c,uri).get(0).position);assertEquals("Minha anotação\nLinha 2",VideoMomentStore.read(c,uri).get(0).note);for(int i=1;i<30;i++)assertNotNull(VideoMomentStore.add(c,uri,"Cena "+i,i));assertNull(VideoMomentStore.add(c,uri,"Excesso",9000));assertEquals(30,VideoMomentStore.read(c,uri).size());assertTrue(VideoMomentStore.remove(c,uri,item.id));assertEquals(29,VideoMomentStore.read(c,uri).size());assertFalse(VideoMomentStore.remove(c,uri,item.id));p.edit().clear().commit();for(int i=0;i<100;i++)assertNotNull(VideoMomentStore.add(c,Uri.parse("content://fixture/video/"+i),"Abertura",0));assertNull(VideoMomentStore.add(c,Uri.parse("content://fixture/video/overflow"),"Excesso",0));assertEquals(1,VideoMomentStore.read(c,Uri.parse("content://fixture/video/0")).size());}finally{restore(p,before);}}
 @Test public void externalMediaAliasesReferToSameScenes(){SharedPreferences p=c.getSharedPreferences("video_moments",0);Map<String,?> before=p.getAll();try{p.edit().clear().commit();VideoStore.Item file=VideoStore.scan(c).stream().filter(i->i.file.endsWith(".mp4")).findFirst().orElse(null);assertNotNull("Video regression fixture missing",file);long id=ContentUris.parseId(file.uri);Uri document=Uri.parse("content://media/external_primary/video/media/"+id);VideoMoments.Moment item=VideoMomentStore.add(c,file.uri,"Cena de teste",4000);assertNotNull(item);List<VideoMoments.Moment> alias=VideoMomentStore.read(c,document);assertEquals(1,alias.size());assertEquals(item.id,alias.get(0).id);}finally{restore(p,before);}}
}
