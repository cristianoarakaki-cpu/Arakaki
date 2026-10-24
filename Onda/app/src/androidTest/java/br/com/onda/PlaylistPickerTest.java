package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
import android.content.*;
import android.widget.*;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;
@androidx.media3.common.util.UnstableApi
public class PlaylistPickerTest {
 @Test public void fixedCounterAndMarksSurviveRecycledRows()throws Exception{
  android.app.Instrumentation ins=getInstrumentation();android.content.Context context=ins.getTargetContext();DownloadsActivity activity=(DownloadsActivity)ins.startActivitySync(new Intent(context,DownloadsActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));PlaylistPicker[] picker={null};AtomicInteger requested=new AtomicInteger();int[] top={0},unchecked={0};
  try{ins.runOnMainSync(()->{List<YoutubeDownloads.Entry> entries=new ArrayList<>();for(int i=0;i<100;i++)entries.add(new YoutubeDownloads.Entry("Vídeo "+i,"https://www.youtube.com/watch?v="+String.format(Locale.ROOT,"%011d",i),"",125+i));PlaylistSelection s=new PlaylistSelection(entries);picker[0]=new PlaylistPicker(activity,"Seleção de teste",s,()->{},()->requested.set(s.count()));activity.setContentView(picker[0].root);});ins.waitForIdleSync();
   ins.runOnMainSync(()->{assertEquals("Baixar (0)",picker[0].download.getText().toString());assertFalse(picker[0].download.isEnabled());picker[0].all.performClick();assertEquals(100,picker[0].selection.count());top[0]=picker[0].download.getTop();picker[0].list.setSelection(99);});ins.waitForIdleSync();
   ins.runOnMainSync(()->{unchecked[0]=picker[0].list.getFirstVisiblePosition();assertTrue(unchecked[0]>0);CheckBox box=(CheckBox)picker[0].list.getChildAt(0).findViewWithTag("playlist-check");box.performClick();assertEquals(99,picker[0].selection.count());assertEquals(top[0],picker[0].download.getTop());picker[0].list.setSelection(0);});ins.waitForIdleSync();
   ins.runOnMainSync(()->{assertFalse(picker[0].selection.contains(unchecked[0]));assertTrue(picker[0].selection.contains(0));assertEquals("Baixar (99)",picker[0].download.getText().toString());picker[0].clear.performClick();assertEquals(0,picker[0].selection.count());});ins.waitForIdleSync();
   ins.runOnMainSync(()->{CheckBox box=(CheckBox)picker[0].list.getChildAt(0).findViewWithTag("playlist-check");box.performClick();assertEquals(1,picker[0].selection.count());picker[0].download.performClick();assertEquals(1,requested.get());assertTrue(picker[0].download.getBottom()<=picker[0].root.getHeight());});
  }finally{ins.runOnMainSync(()->{if(picker[0]!=null)picker[0].close();activity.finish();});ins.waitForIdleSync();}
 }
}
