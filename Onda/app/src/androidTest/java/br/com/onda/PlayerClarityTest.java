package br.com.onda;

import android.app.*;
import android.content.*;
import android.graphics.*;
import android.net.Uri;
import android.view.*;
import android.view.accessibility.AccessibilityNodeInfo;
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
public class PlayerClarityTest {
    private final Instrumentation ins=getInstrumentation();private final Context c=ins.getTargetContext();
    private MainActivity main;private MediaController player;private ListenableFuture<MediaController> connection;
    private File audio;private AlertDialog dialog;private Activity opened;private Set<String> oldShortcuts;
    private interface Check{boolean ready()throws Exception;}
    private Object field(String name)throws Exception{java.lang.reflect.Field f=MainActivity.class.getDeclaredField(name);f.setAccessible(true);return f.get(main);}
    private void waitFor(Check check)throws Exception{for(int n=0;n<300;n++){boolean[] ready={false};ins.runOnMainSync(()->{try{ready[0]=check.ready();}catch(Exception e){throw new RuntimeException(e);}});if(ready[0])return;Thread.sleep(50);}fail("Player clarity UI did not reach expected state");}
    private String label()throws Exception{return ((TextView)field("repeatState")).getText().toString();}
    @Before public void before()throws Exception{
        SharedPreferences prefs=c.getSharedPreferences(QuickAccess.PREF,0);oldShortcuts=prefs.contains(QuickAccess.KEY)?new HashSet<>(prefs.getStringSet(QuickAccess.KEY,Collections.emptySet())):null;prefs.edit().remove(QuickAccess.KEY).commit();
        main=(MainActivity)ins.startActivitySync(new Intent(c,MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));waitFor(()->main.hasWindowFocus());
        ins.runOnMainSync(()->connection=new MediaController.Builder(c,new SessionToken(c,new ComponentName(c,PlaybackService.class))).buildAsync());player=connection.get(15,TimeUnit.SECONDS);
    }
    @After public void after(){capture();ins.runOnMainSync(()->{if(dialog!=null)dialog.dismiss();if(opened!=null)opened.finish();if(player!=null){player.pause();player.stop();player.clearMediaItems();player.setRepeatMode(Player.REPEAT_MODE_OFF);}if(main!=null)main.finish();if(connection!=null)MediaController.releaseFuture(connection);});ins.waitForIdleSync();SharedPreferences.Editor edit=c.getSharedPreferences(QuickAccess.PREF,0).edit();if(oldShortcuts==null)edit.remove(QuickAccess.KEY);else edit.putStringSet(QuickAccess.KEY,oldShortcuts);edit.commit();if(audio!=null)audio.delete();}
    private void capture(){try{Bitmap shot=ins.getUiAutomation().takeScreenshot();if(shot!=null){try(OutputStream out=new FileOutputStream(new File(c.getFilesDir(),"player-clarity-last.png"))){shot.compress(Bitmap.CompressFormat.PNG,100,out);}finally{shot.recycle();}}}catch(Exception ignored){}}
    private void tapNode(String text,boolean checkbox)throws Exception{
        AccessibilityNodeInfo target=null;
        for(int n=0;n<160&&target==null;n++){AccessibilityNodeInfo root=ins.getUiAutomation().getRootInActiveWindow();if(root!=null)for(AccessibilityNodeInfo node:root.findAccessibilityNodeInfosByText(text))if(text.equals(String.valueOf(node.getText()))&&node.isVisibleToUser()){target=node;break;}if(target==null)Thread.sleep(50);}
        assertNotNull("Visible control missing: "+text,target);Rect bounds=new Rect();target.getBoundsInScreen(bounds);assertFalse("Control has no touch bounds: "+text,bounds.isEmpty());long down=android.os.SystemClock.uptimeMillis();android.view.MotionEvent press=android.view.MotionEvent.obtain(down,down,android.view.MotionEvent.ACTION_DOWN,bounds.exactCenterX(),bounds.exactCenterY(),0),release=android.view.MotionEvent.obtain(down,down+80,android.view.MotionEvent.ACTION_UP,bounds.exactCenterX(),bounds.exactCenterY(),0);try{ins.sendPointerSync(press);ins.sendPointerSync(release);}finally{press.recycle();release.recycle();}ins.waitForIdleSync();
    }
    private void repeat(){ins.runOnMainSync(()->{try{((Button)field("repeat")).performClick();}catch(Exception e){throw new RuntimeException(e);}});}
    @Test public void existingRepeatModesAndChapterBoundsAreVisibleWithoutCoveringLibrary()throws Exception{
        audio=AudioTestFixtures.tone(c,45000);MediaItem item=new MediaItem.Builder().setMediaId("clarity-audio").setUri(Uri.fromFile(audio)).setMediaMetadata(new MediaMetadata.Builder().setTitle("Coletânea de teste").build()).build();
        ins.runOnMainSync(()->{player.setRepeatMode(Player.REPEAT_MODE_OFF);player.setMediaItem(item);player.prepare();});waitFor(()->label().equals("Repetição desligada"));
        repeat();waitFor(()->player.getRepeatMode()==Player.REPEAT_MODE_ONE&&label().equals("Repetindo esta música"));repeat();waitFor(()->player.getRepeatMode()==Player.REPEAT_MODE_ALL&&label().equals("Repetindo a fila"));repeat();waitFor(()->label().equals("Repetição desligada"));
        AudioChapterStore.Data data=new AudioChapterStore.Data(45000,Arrays.asList(new AudioChapterStore.Chapter(0,"Primeira"),new AudioChapterStore.Chapter(10000,"Trecho escolhido"),new AudioChapterStore.Chapter(20000,"Última")));
        MediaItem selected=AudioChapterPlayback.configure(AudioChapterPlayback.select(item,data,1,AudioChapterStore.stamp(c,Uri.fromFile(audio))),true);
        ins.runOnMainSync(()->{player.setRepeatMode(Player.REPEAT_MODE_ONE);player.setMediaItem(selected);player.prepare();player.play();});
        waitFor(()->player.isPlaying()&&label().contains("Trecho escolhido")&&((TextView)field("chapterRange")).getText().toString().equals("0:10 → 0:20"));
        ins.runOnMainSync(()->{try{TextView range=(TextView)field("chapterRange");Rect visible=new Rect();assertTrue("Chapter bounds were not visible",range.getGlobalVisibleRect(visible));assertEquals("Chapter bounds were clipped",range.getHeight(),visible.height());assertEquals("Início: 0:10 • Fim: 0:20",range.getContentDescription());assertTrue("Library must retain a usable touch area",((View)((View)field("libraryList")).getParent()).getHeight()>=Math.round(48*c.getResources().getDisplayMetrics().density));Toast toast=(Toast)field("repeatToast");if(toast!=null)toast.cancel();player.pause();}catch(Exception e){throw new RuntimeException(e);}});
        ins.waitForIdleSync();Bitmap screenshot=ins.getUiAutomation().takeScreenshot();assertNotNull(screenshot);try(OutputStream out=new FileOutputStream(new File(c.getFilesDir(),"player-clarity.png"))){screenshot.compress(Bitmap.CompressFormat.PNG,100,out);}finally{screenshot.recycle();}
    }
    @Test public void shortcutCancelPreservesSelectionSavePersistsAndChosenScreenActuallyOpens()throws Exception{
        Set<String> before=new HashSet<>(QuickAccess.read(c));assertEquals(3,before.size());
        ins.runOnMainSync(()->dialog=QuickAccess.choose(main));ins.waitForIdleSync();
        tapNode("Atualizações",true);waitFor(()->dialog.getListView().isItemChecked(4));assertEquals("Draft changes must not be saved",before,QuickAccess.read(c));ins.runOnMainSync(()->dialog.getButton(AlertDialog.BUTTON_NEGATIVE).performClick());assertEquals(before,QuickAccess.read(c));
        ins.runOnMainSync(()->dialog=QuickAccess.choose(main));ins.waitForIdleSync();
        tapNode("Atualizações",true);waitFor(()->dialog.getListView().isItemChecked(4));ins.runOnMainSync(()->dialog.getButton(AlertDialog.BUTTON_POSITIVE).performClick());ins.waitForIdleSync();waitFor(()->QuickAccess.read(c).contains("OPEN_UPDATES"));assertTrue("Saved shortcut missing: "+QuickAccess.read(c),QuickAccess.read(c).contains("OPEN_UPDATES"));assertTrue("Other choices changed",QuickAccess.read(c).containsAll(before));
        Instrumentation.ActivityMonitor monitor=ins.addMonitor(UpdateActivity.class.getName(),null,false);
        try{
            ins.runOnMainSync(()->QuickAccess.menu(main,main.getWindow().getDecorView()));
            AccessibilityNodeInfo[] target={null};
            for(int n=0;n<160&&target[0]==null;n++){AccessibilityNodeInfo root=ins.getUiAutomation().getRootInActiveWindow();if(root!=null)for(AccessibilityNodeInfo node:root.findAccessibilityNodeInfosByText("Atualizações"))if("Atualizações".contentEquals(node.getText())&&node.isClickable()){target[0]=node;break;}if(target[0]==null)Thread.sleep(50);}
            assertNotNull("Chosen shortcut was not visible",target[0]);
            assertTrue(target[0].performAction(AccessibilityNodeInfo.ACTION_CLICK));opened=ins.waitForMonitorWithTimeout(monitor,8000);assertNotNull(opened);assertEquals(UpdateActivity.class,opened.getClass());
        }finally{ins.removeMonitor(monitor);}
        ins.runOnMainSync(()->opened.finish());waitFor(()->main.hasWindowFocus());
        ins.runOnMainSync(()->{dialog=QuickAccess.help(main);TextView message=dialog.findViewById(android.R.id.message);assertNotNull(message);assertTrue(message.getText().toString().contains("último botão à direita"));assertTrue(message.getText().toString().contains("abrir YouTube"));});
    }
}
