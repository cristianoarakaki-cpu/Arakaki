package br.com.onda;

import android.content.*;
import android.media.AudioDeviceInfo;
import android.net.Uri;
import android.os.Bundle;
import androidx.media3.common.*;
import androidx.media3.session.*;
import com.google.common.util.concurrent.ListenableFuture;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
import java.io.*;
import java.util.*;
import java.util.concurrent.TimeUnit;

@androidx.media3.common.util.UnstableApi
public class SoundRoutesTest {
 private final android.app.Instrumentation ins=getInstrumentation();
 private void restore(SharedPreferences prefs,Map<String,?> values){SharedPreferences.Editor e=prefs.edit().clear();for(Map.Entry<String,?> row:values.entrySet()){Object v=row.getValue();if(v instanceof Boolean)e.putBoolean(row.getKey(),(Boolean)v);else if(v instanceof Integer)e.putInt(row.getKey(),(Integer)v);else if(v instanceof String)e.putString(row.getKey(),(String)v);}assertTrue(e.commit());}
 @Test public void profilesStaySeparateAndDisablingRestoresLegacy(){
  Context c=ins.getTargetContext();SharedPreferences legacy=c.getSharedPreferences("sound",0),profiles=c.getSharedPreferences("sound_profiles",0);Map<String,?> old=legacy.getAll(),saved=profiles.getAll();String route=SoundSettings.current();
  try{profiles.edit().clear().commit();SoundSettings.save(c,SoundProfile.preset(3,true));SoundSettings.route("speaker");SoundSettings.automatic(c,true);
   assertEquals("Rock",SoundSettings.read(c).presetName());SoundSettings.saveProfile(c,"bluetooth",SoundProfile.preset(7,true));
   SoundSettings.route("bluetooth");assertEquals("Fones voz nítida",SoundSettings.read(c).presetName());
   SoundSettings.rename(c,"bluetooth","  Meu\nfone  ");assertEquals("Meu fone",SoundSettings.name(c,"bluetooth"));
   SoundSettings.route("usb");assertFalse(SoundSettings.read(c).enabled);SoundSettings.route("");assertFalse(SoundSettings.read(c).enabled);
   SoundSettings.automatic(c,false);assertEquals("Rock",SoundSettings.read(c).presetName());assertTrue(SoundSettings.read(c).enabled);
   SoundSettings.automatic(c,true);SoundSettings.route("bluetooth");assertEquals("Fones voz nítida",SoundSettings.read(c).presetName());
   SoundSettings.saveProfile(c,"bluetooth",SoundProfile.preset(0,false));SoundSettings.route("speaker");assertEquals("Rock",SoundSettings.read(c).presetName());
   assertFalse(profiles.contains("current"));
  }finally{restore(legacy,old);restore(profiles,saved);SoundSettings.route(route);}
 }
 @Test public void groupsActualDeviceTypesWithoutTreatingUnknownAsSpeaker(){
  assertEquals("speaker",SoundRoutes.kind(AudioDeviceInfo.TYPE_BUILTIN_SPEAKER));assertEquals("wired",SoundRoutes.kind(AudioDeviceInfo.TYPE_WIRED_HEADPHONES));
  assertEquals("bluetooth",SoundRoutes.kind(AudioDeviceInfo.TYPE_BLUETOOTH_A2DP));assertEquals("bluetooth",SoundRoutes.kind(26));
  assertEquals("usb",SoundRoutes.kind(AudioDeviceInfo.TYPE_USB_HEADSET));assertEquals("hdmi",SoundRoutes.kind(AudioDeviceInfo.TYPE_HDMI));assertEquals("other",SoundRoutes.kind(999));
 }
 @Test public void actualExoPlayerTrackIdentifiesRouteAndProfileChangesDoNotStartPlayback()throws Exception{
  Context c=ins.getTargetContext();SharedPreferences profiles=c.getSharedPreferences("sound_profiles",0);Map<String,?> saved=profiles.getAll();
  File file=File.createTempFile("sound-route-",".m4a",c.getCacheDir());try(InputStream in=ins.getContext().getAssets().open("audio.m4a");OutputStream out=new FileOutputStream(file)){byte[] b=new byte[8192];int n;while((n=in.read(b))>0)out.write(b,0,n);}
  ListenableFuture<MediaController>[] connection=new ListenableFuture[1];ins.runOnMainSync(()->connection[0]=new MediaController.Builder(c,new SessionToken(c,new ComponentName(c,PlaybackService.class))).buildAsync());MediaController player=connection[0].get(15,TimeUnit.SECONDS);
  try{ins.runOnMainSync(()->{SoundSettings.route("");SoundSettings.automatic(c,true);player.pause();player.setRepeatMode(Player.REPEAT_MODE_OFF);player.setMediaItem(new MediaItem.Builder().setMediaId("889901").setUri(Uri.fromFile(file)).build());player.prepare();player.play();});
   long deadline=System.currentTimeMillis()+10000;while(SoundSettings.current().isEmpty()&&System.currentTimeMillis()<deadline)Thread.sleep(100);
   assertEquals("Actual emulator AudioTrack must report speaker","speaker",SoundSettings.current());
   ListenableFuture<SessionResult>[] command=new ListenableFuture[1];ins.runOnMainSync(()->{SoundSettings.saveProfile(c,"speaker",SoundProfile.preset(1,true));command[0]=player.sendCustomCommand(new SessionCommand("sound",Bundle.EMPTY),Bundle.EMPTY);});
   SessionResult result=command[0].get(5,TimeUnit.SECONDS);assertEquals(SessionResult.RESULT_SUCCESS,result.resultCode);assertTrue("Identified speaker uses its profile",result.extras.getBoolean("enabled"));
   ins.runOnMainSync(player::pause);ins.waitForIdleSync();
   // AudioRouting.getRoutedDevice may return null while paused. Compare the paused
   // state before/after editing another profile, rather than assuming a live route.
   ins.runOnMainSync(()->command[0]=player.sendCustomCommand(new SessionCommand("sound",Bundle.EMPTY),Bundle.EMPTY));
   Bundle paused=command[0].get(5,TimeUnit.SECONDS).extras;assertFalse(paused.getBoolean("playing"));
   ins.runOnMainSync(()->assertFalse(player.getPlayWhenReady()));
   ins.runOnMainSync(()->{SoundSettings.saveProfile(c,"bluetooth",SoundProfile.preset(0,false));command[0]=player.sendCustomCommand(new SessionCommand("sound",Bundle.EMPTY),Bundle.EMPTY);});
   Bundle after=command[0].get(5,TimeUnit.SECONDS).extras;
   assertEquals("Editing Bluetooth preserves paused effects",paused.getBoolean("enabled"),after.getBoolean("enabled"));
   assertFalse(after.getBoolean("playing"));assertEquals("Voz",SoundSettings.readProfile(c,"speaker").presetName());
   ins.runOnMainSync(()->assertFalse(player.getPlayWhenReady()));
  }finally{ins.runOnMainSync(()->{player.pause();player.clearMediaItems();restore(profiles,saved);player.sendCustomCommand(new SessionCommand("sound",Bundle.EMPTY),Bundle.EMPTY);MediaController.releaseFuture(connection[0]);});file.delete();}
 }
}
