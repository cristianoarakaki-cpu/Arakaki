package br.com.onda;
import android.content.*;
import android.os.Bundle;
import androidx.media3.common.*;
import androidx.media3.session.*;
import com.google.common.util.concurrent.ListenableFuture;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
import java.util.*;
import java.util.concurrent.TimeUnit;
@androidx.media3.common.util.UnstableApi
public class QueueActivityTest {
 private final android.app.Instrumentation ins=getInstrumentation();
 private MediaController player;private ListenableFuture<MediaController> connection;
 private void connect()throws Exception{Context c=ins.getTargetContext();ins.runOnMainSync(()->connection=new MediaController.Builder(c,new SessionToken(c,new ComponentName(c,PlaybackService.class))).buildAsync());player=connection.get(15,TimeUnit.SECONDS);ins.runOnMainSync(()->{player.pause();List<MediaItem> items=new ArrayList<>();for(int i=0;i<4;i++)items.add(new MediaItem.Builder().setMediaId("7700"+i).setUri("file:///queue-test-"+i+".m4a").setMediaMetadata(new MediaMetadata.Builder().setTitle("Faixa "+i).build()).build());player.setMediaItems(items,1,12000);player.setRepeatMode(Player.REPEAT_MODE_ALL);player.setShuffleModeEnabled(false);});Thread.sleep(300);}
 private int send(Bundle b)throws Exception{ListenableFuture<SessionResult>[] f=new ListenableFuture[1];ins.runOnMainSync(()->f[0]=player.sendCustomCommand(new SessionCommand(QueueEdit.COMMAND,Bundle.EMPTY),b));int code=f[0].get(5,TimeUnit.SECONDS).resultCode;Thread.sleep(200);return code;}
 private Bundle request(int index,String action){Bundle[] b=new Bundle[1];ins.runOnMainSync(()->b[0]=QueueEdit.request(QueueEdit.snapshot(player),player.getCurrentMediaItemIndex(),index,action));return b[0];}
 private void close(){ins.runOnMainSync(()->{player.pause();player.clearMediaItems();player.setRepeatMode(Player.REPEAT_MODE_OFF);MediaController.releaseFuture(connection);});}
 @Test public void screenReordersAndClearsWithoutInterruptingCurrent()throws Exception{connect();QueueActivity screen=null;try{screen=(QueueActivity)ins.startActivitySync(new Intent(ins.getTargetContext(),QueueActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));QueueActivity a=screen;long until=System.currentTimeMillis()+10000;boolean[] ready={false};while(System.currentTimeMillis()<until){ins.runOnMainSync(()->ready[0]=a.player!=null&&a.list.getAdapter().getCount()==4);if(ready[0])break;Thread.sleep(100);}assertTrue(ready[0]);ins.runOnMainSync(()->{a.edit(3);a.activeDialog.getListView().performItemClick(null,1,1);});Thread.sleep(500);ins.runOnMainSync(()->{assertEquals("77001",player.getCurrentMediaItem().mediaId);assertEquals("77003",player.getMediaItemAt(2).mediaId);assertEquals(12000,player.getCurrentPosition());assertFalse(player.getPlayWhenReady());a.clear.performClick();a.activeDialog.getButton(android.app.AlertDialog.BUTTON_POSITIVE).performClick();});Thread.sleep(500);ins.runOnMainSync(()->{assertEquals(2,player.getMediaItemCount());assertEquals("77001",player.getCurrentMediaItem().mediaId);assertEquals(12000,player.getCurrentPosition());assertFalse(player.getPlayWhenReady());assertEquals(Player.REPEAT_MODE_OFF,player.getRepeatMode());});}finally{if(screen!=null){QueueActivity a=screen;ins.runOnMainSync(a::finish);}close();}}
 @Test public void staleCommandsCannotRemoveNewCurrentAndAddingStaysPaused()throws Exception{connect();try{Bundle stale=request(2,"remove");ins.runOnMainSync(()->player.seekTo(2,9000));Thread.sleep(300);assertEquals(SessionError.ERROR_BAD_VALUE,send(stale));ins.runOnMainSync(()->{assertEquals(4,player.getMediaItemCount());assertEquals("77002",player.getCurrentMediaItem().mediaId);});assertEquals(SessionError.ERROR_BAD_VALUE,send(request(2,"remove")));Bundle add=new Bundle();add.putString("action","add_next");add.putBundle("item",new MediaItem.Builder().setMediaId("77999").setUri("file:///queue-extra.m4a").build().toBundleIncludeLocalConfiguration());assertEquals(SessionResult.RESULT_SUCCESS,send(add));ins.runOnMainSync(()->{assertEquals(5,player.getMediaItemCount());assertEquals("77999",player.getMediaItemAt(3).mediaId);assertEquals("77002",player.getCurrentMediaItem().mediaId);assertEquals(9000,player.getCurrentPosition());assertFalse(player.getPlayWhenReady());});}finally{close();}}
}
