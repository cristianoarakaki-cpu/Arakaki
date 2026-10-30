package br.com.onda;

import android.app.*;
import android.content.*;
import android.net.Uri;
import android.os.*;
import android.view.*;
import android.widget.*;
import androidx.media3.common.*;
import androidx.media3.session.MediaController;
import org.junit.*;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
import java.io.*;
import java.lang.reflect.*;
import java.util.*;

@androidx.media3.common.util.UnstableApi
public class LightweightTest {
 private final Instrumentation ins=getInstrumentation();private final Context c=ins.getTargetContext();private Activity activity;private final Map<String,Map<String,?>> saved=new HashMap<>();private File audio;
 private Object get(Object o,String name)throws Exception{Field f=o.getClass().getDeclaredField(name);f.setAccessible(true);return f.get(o);}
 private void set(Object o,String name,Object value)throws Exception{Field f=o.getClass().getDeclaredField(name);f.setAccessible(true);f.set(o,value);}
 private void render()throws Exception{Method m=MainActivity.class.getDeclaredMethod("render");m.setAccessible(true);m.invoke(activity);}
 private interface Check {boolean ok()throws Exception;}
 private void waitFor(Check check)throws Exception{long end=SystemClock.elapsedRealtime()+15000;while(SystemClock.elapsedRealtime()<end){boolean[] ready={false};ins.runOnMainSync(()->{try{ready[0]=check.ok();}catch(Exception e){throw new RuntimeException(e);}});if(ready[0])return;Thread.sleep(100);}throw new AssertionError("Timed out waiting for native UI");}
 @Before public void before(){for(String name:Arrays.asList("library","downloads"))saved.put(name,c.getSharedPreferences(name,0).getAll());c.getSharedPreferences("library",0).edit().putInt("sort_order",0).putBoolean("downloads_only",false).putStringSet("favorites",new HashSet<>(Collections.singletonList("light-2999"))).commit();}
 @After public void after(){if(activity!=null)ins.runOnMainSync(()->{try{if(activity instanceof MainActivity){MediaController p=(MediaController)get(activity,"player");if(p!=null){p.pause();p.clearMediaItems();}}}catch(Exception ignored){}activity.finish();});ins.waitForIdleSync();if(audio!=null)audio.delete();for(Map.Entry<String,Map<String,?>> entry:saved.entrySet()){SharedPreferences.Editor e=c.getSharedPreferences(entry.getKey(),0).edit().clear();for(Map.Entry<String,?> item:entry.getValue().entrySet()){Object v=item.getValue();String k=item.getKey();if(v instanceof String)e.putString(k,(String)v);else if(v instanceof Boolean)e.putBoolean(k,(Boolean)v);else if(v instanceof Integer)e.putInt(k,(Integer)v);else if(v instanceof Long)e.putLong(k,(Long)v);else if(v instanceof Float)e.putFloat(k,(Float)v);else if(v instanceof Set)e.putStringSet(k,new HashSet<>((Set<String>)v));}e.commit();}}
 @Test public void largeLibraryRecyclesCardsAndPreservesSearchFavoritesGroupingAndPlayback()throws Exception{
  audio=File.createTempFile("onda-light-",".m4a",c.getCacheDir());try(InputStream in=ins.getContext().getAssets().open("audio.m4a");OutputStream out=new FileOutputStream(audio)){byte[] b=new byte[8192];int n;while((n=in.read(b))!=-1)out.write(b,0,n);}
  activity=ins.startActivitySync(new Intent(c,MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));waitFor(()->(Boolean)get(activity,"libraryReady")&&get(activity,"player")!=null);
  ins.runOnMainSync(()->{try{List<MediaItem> songs=(List<MediaItem>)get(activity,"songs");songs.clear();for(int i=0;i<3000;i++)songs.add(new MediaItem.Builder().setMediaId("light-"+i).setUri(Uri.fromFile(audio)).setMediaMetadata(new MediaMetadata.Builder().setTitle(String.format(Locale.ROOT,"Faixa leve %05d",i)).setArtist("Artista "+i%7).setAlbumTitle("Álbum "+i%3).build()).build());render();}catch(Exception e){throw new RuntimeException(e);}});
  waitFor(()->((ListView)get(activity,"libraryList")).getChildCount()>0);int[] attached={0};ins.runOnMainSync(()->{try{ListView list=(ListView)get(activity,"libraryList");assertTrue(list.getAdapter().getCount()>=3000);attached[0]=list.getChildCount();assertTrue("All songs were materialized",attached[0]<50);list.setSelection(list.getAdapter().getCount()-1);}catch(Exception e){throw new RuntimeException(e);}});waitFor(()->{ListView list=(ListView)get(activity,"libraryList");return list.getLastVisiblePosition()==list.getAdapter().getCount()-1;});
  ins.runOnMainSync(()->{try{EditText search=(EditText)get(activity,"localSearch");search.setText("leve 02999");List<MediaItem> filtered=(List<MediaItem>)get(activity,"visibleSongs");assertEquals(1,filtered.size());assertEquals("light-2999",filtered.get(0).mediaId);search.setText("");set(activity,"libraryOrder",1);render();ListView list=(ListView)get(activity,"libraryList");assertTrue(list.getAdapter().getCount()>3000);assertEquals(1,list.getAdapter().getItemViewType(0));((Button)get(activity,"favoritesTab")).performClick();filtered=(List<MediaItem>)get(activity,"visibleSongs");assertEquals(1,filtered.size());assertEquals("light-2999",filtered.get(0).mediaId);set(activity,"libraryOrder",0);render();}catch(Exception e){throw new RuntimeException(e);}});
  waitFor(()->{ListView list=(ListView)get(activity,"libraryList");if(list.getChildCount()==0||list.getAdapter().getCount()!=1||!(list.getChildAt(0) instanceof FrameLayout))return false;FrameLayout row=(FrameLayout)list.getChildAt(0);return row.getChildCount()>0&&row.getChildAt(0).getContentDescription()!=null&&row.getChildAt(0).getContentDescription().toString().contains("Faixa leve 02999");});ins.runOnMainSync(()->{try{ListView list=(ListView)get(activity,"libraryList");FrameLayout wrapper=(FrameLayout)list.getChildAt(0);assertTrue(wrapper.getChildAt(0).getContentDescription().toString().contains("Faixa leve 02999"));wrapper.getChildAt(0).performClick();}catch(Exception e){throw new RuntimeException(e);}});waitFor(()->{MediaController player=(MediaController)get(activity,"player");return player.getCurrentMediaItem()!=null&&player.getCurrentMediaItem().mediaId.equals("light-2999")&&player.getPlaybackState()==Player.STATE_READY;});ins.runOnMainSync(()->{try{MediaController player=(MediaController)get(activity,"player");assertEquals(1,player.getMediaItemCount());player.pause();}catch(Exception e){throw new RuntimeException(e);}});
  try(OutputStream out=new FileOutputStream(new File(c.getFilesDir(),"lightweight-tests.json"))){out.write(("{\"songs\":3000,\"attachedCards\":"+attached[0]+",\"lastItemReachable\":true,\"search\":true,\"favorites\":true,\"artistGroups\":true,\"actualAudioQueue\":true}").getBytes(java.nio.charset.StandardCharsets.UTF_8));}
 }
 @Test public void downloadsStopsPollingWhileIdleButStillObservesStatusAndResumes()throws Exception{
  assertFalse(MediaDownloadService.activeDownload);activity=ins.startActivitySync(new Intent(c,DownloadsActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));ins.waitForIdleSync();waitFor(()->!((Handler)get(activity,"handler")).hasCallbacks((Runnable)get(activity,"refresh")));
  c.getSharedPreferences("downloads",0).edit().putString("status","Verificação leve atualizada").apply();waitFor(()->((TextView)get(activity,"status")).getText().toString().equals("Verificação leve atualizada"));ins.runOnMainSync(()->{try{assertFalse(((Handler)get(activity,"handler")).hasCallbacks((Runnable)get(activity,"refresh")));ins.callActivityOnPause(activity);ins.callActivityOnStop(activity);}catch(Exception e){throw new RuntimeException(e);}});
  c.getSharedPreferences("downloads",0).edit().putString("status","Atualização fora da tela").apply();ins.waitForIdleSync();ins.runOnMainSync(()->{try{assertFalse(((Handler)get(activity,"handler")).hasCallbacks((Runnable)get(activity,"refresh")));assertEquals("Verificação leve atualizada",((TextView)get(activity,"status")).getText().toString());ins.callActivityOnStart(activity);ins.callActivityOnResume(activity);}catch(Exception e){throw new RuntimeException(e);}});waitFor(()->((TextView)get(activity,"status")).getText().toString().equals("Atualização fora da tela"));
 }
}
