package br.com.onda;
import android.app.*;
import android.content.*;
import android.graphics.*;
import android.net.Uri;
import android.view.*;
import android.widget.*;
import androidx.media3.common.*;
import androidx.media3.session.*;
import androidx.media3.session.MediaController;
import com.google.common.util.concurrent.ListenableFuture;
import java.io.*;
import java.lang.reflect.Field;
import java.util.*;
import java.util.concurrent.TimeUnit;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
@androidx.media3.common.util.UnstableApi
public class AutomationTest {
 private final Instrumentation ins=getInstrumentation();private final Context context=ins.getTargetContext();private interface Check{boolean ready()throws Exception;}
 private void waitFor(Check check)throws Exception{for(int i=0;i<200;i++){boolean[] ok={false};ins.runOnMainSync(()->{try{ok[0]=check.ready();}catch(Exception e){throw new RuntimeException(e);}});if(ok[0])return;Thread.sleep(50);}fail("Automation state did not become ready");}
 private TextView find(View v,String description){if(v instanceof TextView&&description.contentEquals(v.getContentDescription()==null?"":v.getContentDescription()))return (TextView)v;if(v instanceof ViewGroup)for(int i=0;i<((ViewGroup)v).getChildCount();i++){TextView result=find(((ViewGroup)v).getChildAt(i),description);if(result!=null)return result;}return null;}
 private Object field(Object owner,String name)throws Exception{Field field=owner.getClass().getDeclaredField(name);field.setAccessible(true);return field.get(owner);}
 private void capture(String name)throws Exception{Bitmap bitmap=ins.getUiAutomation().takeScreenshot();assertNotNull(bitmap);try(OutputStream out=new FileOutputStream(new File(context.getFilesDir(),name))){bitmap.compress(Bitmap.CompressFormat.PNG,100,out);}finally{bitmap.recycle();}}
 @Test public void interpretationOnlyPreviewsAndEditingInvalidatesExecution()throws Exception{AutomationActivity screen=(AutomationActivity)ins.startActivitySync(new Intent(context,AutomationActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));try{ins.waitForIdleSync();ins.runOnMainSync(()->{View root=screen.getWindow().getDecorView();EditText input=(EditText)find(root,"Pedido para a central inteligente");Button execute=(Button)find(root,"Executar plano revisado");assertFalse(execute.isEnabled());input.setText("toque minhas favoritas em ordem aleatória e pare em 30 minutos");find(root,"Interpretar pedido sem executar").performClick();assertTrue(execute.isEnabled());String summary=find(root,"Etapas da automação").getText().toString();assertTrue(summary,summary.contains("favoritas"));assertTrue(summary,summary.contains("aleatório"));assertTrue(summary,summary.contains("30 minutos"));input.setText("exclua todos os arquivos");assertFalse(execute.isEnabled());find(root,"Interpretar pedido sem executar").performClick();assertFalse(execute.isEnabled());input.setText("imagens de boa noite");find(root,"Interpretar pedido sem executar").performClick();assertTrue(execute.isEnabled());assertTrue(find(root,"Etapas da automação").getText().toString().contains("boa noite"));});capture("automation-central.png");}finally{ins.runOnMainSync(screen::finish);}}
 @Test public void actualRoutineSelectsFavoritesAndKeepsPlaybackWhileRecoloring()throws Exception{
  String oldTheme=context.getSharedPreferences("appearance",0).getString("theme",null);boolean oldVivid=Ui.VIVID;File source=File.createTempFile("automation-",".wav",context.getCacheDir());try(InputStream in=ins.getContext().getAssets().open("speech.wav");OutputStream out=new FileOutputStream(source)){byte[] b=new byte[8192];int n;while((n=in.read(b))!=-1)out.write(b,0,n);}
  MainActivity screen=(MainActivity)ins.startActivitySync(new Intent(context,MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));ListenableFuture<MediaController>[] future=new ListenableFuture[1];ins.runOnMainSync(()->future[0]=new MediaController.Builder(context,new SessionToken(context,new ComponentName(context,PlaybackService.class))).buildAsync());MediaController player=future[0].get(15,TimeUnit.SECONDS);
  try{waitFor(()->(Boolean)field(screen,"libraryReady")&&field(screen,"player")!=null);ins.runOnMainSync(()->{try{ArrayList<MediaItem> songs=(ArrayList<MediaItem>)field(screen,"songs");songs.clear();for(int i=0;i<2;i++)songs.add(new MediaItem.Builder().setMediaId("automation-"+i).setUri(Uri.fromFile(source)).setMediaMetadata(new MediaMetadata.Builder().setTitle("Rotina "+i).setArtist("Onda").build()).build());Set<String> favorites=(Set<String>)field(screen,"favorites");favorites.clear();player.pause();player.setShuffleModeEnabled(false);player.setRepeatMode(Player.REPEAT_MODE_OFF);player.setMediaItem(new MediaItem.Builder().setMediaId("sentinel").setUri(Uri.fromFile(source)).build());player.prepare();screen.onNewIntent(new Intent(context,MainActivity.class).putExtra("automation_request","toque minhas favoritas; ative o modo aleatório; repita esta faixa"));assertEquals("sentinel",player.getCurrentMediaItem().mediaId);assertFalse(player.getShuffleModeEnabled());assertEquals(Player.REPEAT_MODE_OFF,player.getRepeatMode());favorites.add("automation-0");favorites.add("automation-1");screen.onNewIntent(new Intent(context,MainActivity.class).putExtra("automation_request","toque minhas favoritas; ative o modo aleatório; repita esta faixa"));}catch(Exception e){throw new RuntimeException(e);}});
   waitFor(player::isPlaying);ins.runOnMainSync(()->{assertEquals(2,player.getMediaItemCount());assertTrue(player.getShuffleModeEnabled());assertEquals(Player.REPEAT_MODE_ONE,player.getRepeatMode());Ui.VIVID=true;AppearanceStyles.choose(screen,AppearancePalette.find("festival"));assertTrue(player.isPlaying());});ins.waitForIdleSync();capture("automation-color-player.png");ins.runOnMainSync(()->{Ui.VIVID=false;((OndaApplication)screen.getApplication()).refreshAll();assertTrue(player.isPlaying());assertEquals(2,player.getMediaItemCount());assertTrue(player.getShuffleModeEnabled());assertEquals(Player.REPEAT_MODE_ONE,player.getRepeatMode());});
  }finally{ins.runOnMainSync(()->{player.pause();player.clearMediaItems();player.setShuffleModeEnabled(false);player.setRepeatMode(Player.REPEAT_MODE_OFF);Ui.VIVID=oldVivid;AppearanceStyles.choose(screen,AppearancePalette.find(oldTheme));screen.finish();MediaController.releaseFuture(future[0]);});SharedPreferences.Editor edit=context.getSharedPreferences("appearance",0).edit();if(oldTheme==null)edit.remove("theme");else edit.putString("theme",oldTheme);edit.commit();source.delete();}
 }
}
