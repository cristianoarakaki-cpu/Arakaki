package br.com.onda;
import android.app.*;
import android.content.*;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.view.*;
import android.widget.*;
import androidx.media3.common.*;
import androidx.media3.session.*;
import com.google.common.util.concurrent.ListenableFuture;
import java.io.*;
import java.util.concurrent.TimeUnit;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
@androidx.media3.common.util.UnstableApi
public class AppearanceTest {
 @Test public void repaintKeepsActivitySearchAndActualPlayback()throws Exception{Instrumentation ins=getInstrumentation();Context c=ins.getTargetContext();String old=c.getSharedPreferences("appearance",0).getString("theme",null);File source=File.createTempFile("appearance-",".wav",c.getCacheDir());try(InputStream in=ins.getContext().getAssets().open("speech.wav");OutputStream out=new FileOutputStream(source)){byte[] b=new byte[8192];int n;while((n=in.read(b))!=-1)out.write(b,0,n);}Activity activity=ins.startActivitySync(new Intent(c,MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));ListenableFuture<MediaController>[] connection=new ListenableFuture[1];ins.runOnMainSync(()->connection[0]=new MediaController.Builder(c,new SessionToken(c,new ComponentName(c,PlaybackService.class))).buildAsync());MediaController player=connection[0].get(15,TimeUnit.SECONDS);try{View[] root={null};int[] padding=new int[4];ins.runOnMainSync(()->{root[0]=((ViewGroup)activity.findViewById(android.R.id.content)).getChildAt(0);padding[0]=root[0].getPaddingLeft();padding[1]=root[0].getPaddingTop();padding[2]=root[0].getPaddingRight();padding[3]=root[0].getPaddingBottom();EditText search=findSearch(root[0]);assertNotNull(search);search.setText("Tema teste");player.pause();player.setMediaItem(new MediaItem.Builder().setMediaId("appearance-fixture").setUri(Uri.fromFile(source)).build());player.prepare();});long end=System.currentTimeMillis()+10000;boolean[] ready={false};while(System.currentTimeMillis()<end){ins.runOnMainSync(()->ready[0]=player.getPlaybackState()==Player.STATE_READY);if(ready[0])break;Thread.sleep(100);}assertTrue(ready[0]);for(AppearancePalette p:AppearancePalette.ALL)ins.runOnMainSync(()->{AppearanceStyles.choose(activity,p);assertEquals(p.bg,((GradientDrawable)root[0].getBackground()).getColors()[0]);assertFalse(activity.isDestroyed());assertEquals("Tema teste",findSearch(root[0]).getText().toString());assertEquals(padding[0],root[0].getPaddingLeft());assertEquals(padding[1],root[0].getPaddingTop());assertEquals(padding[2],root[0].getPaddingRight());assertEquals(padding[3],root[0].getPaddingBottom());assertFalse(player.getPlayWhenReady());assertEquals("appearance-fixture",player.getCurrentMediaItem().mediaId);});ins.runOnMainSync(player::play);Thread.sleep(700);for(AppearancePalette p:AppearancePalette.ALL){ins.runOnMainSync(()->AppearanceStyles.choose(activity,p));Thread.sleep(120);ins.runOnMainSync(()->{assertTrue(player.isPlaying());assertEquals("appearance-fixture",player.getCurrentMediaItem().mediaId);assertEquals(1,player.getMediaItemCount());});}}finally{ins.runOnMainSync(()->{player.pause();player.clearMediaItems();AppearanceStyles.choose(activity,AppearancePalette.find(old));activity.finish();MediaController.releaseFuture(connection[0]);});SharedPreferences.Editor edit=c.getSharedPreferences("appearance",0).edit();if(old==null)edit.remove("theme");else edit.putString("theme",old);edit.commit();source.delete();}}
 private EditText findSearch(View view){if(view instanceof EditText&&"Buscar música, artista ou álbum no celular".contentEquals(view.getContentDescription()))return (EditText)view;if(view instanceof ViewGroup){ViewGroup g=(ViewGroup)view;for(int i=0;i<g.getChildCount();i++){EditText result=findSearch(g.getChildAt(i));if(result!=null)return result;}}return null;}
}
