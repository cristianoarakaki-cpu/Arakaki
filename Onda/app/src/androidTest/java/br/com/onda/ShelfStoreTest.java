package br.com.onda;
import android.content.*;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
public class ShelfStoreTest {
 @Test public void collectionAndNoteSurviveRepeatedPlaybackWrites(){Context c=getInstrumentation().getTargetContext();SharedPreferences p=c.getSharedPreferences("media_shelf",0);String previous=p.getString("data",null);try{p.edit().clear().commit();final String[] ids=new String[2];assertTrue(ShelfStore.edit(c,s->{MediaShelf.Item item=s.touch("video","content://shelf/test","Aula",6000,60000,1);MediaShelf.Collection group=s.create("Curso");ids[0]=item.id;ids[1]=group.id;return s.add(group.id,item.id)&&s.note(item.id,"",6000,"Preservar");}));for(int i=0;i<20;i++)ShelfStore.remember(c,"video","content://shelf/test","",7000+i,60000);MediaShelf s=ShelfStore.read(c);assertEquals("Aula",s.items.get(ids[0]).title);assertEquals(7019,s.items.get(ids[0]).position);assertEquals(6000,s.items.get(ids[0]).notes.get(0).at);assertEquals("Preservar",s.items.get(ids[0]).notes.get(0).text);assertTrue(s.collections.get(ids[1]).items.contains(ids[0]));}finally{SharedPreferences.Editor e=p.edit();if(previous==null)e.remove("data");else e.putString("data",previous);e.commit();}}
}
