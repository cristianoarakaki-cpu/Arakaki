package br.com.onda;


import android.app.*;

import android.content.*;

import android.net.Uri;

import android.os.*;

import android.view.View;

import android.widget.Button;

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
public class ListeningModesTest {
    private final Instrumentation ins=getInstrumentation();
private final Context c=ins.getTargetContext();

    private Activity anchor,sound;
private MediaController player;
private ListenableFuture<MediaController> connection;
private File file;

    private boolean oldLevel;
private int oldFade,oldQuiet;
private boolean oldVoice,oldSilence;

    private interface Check{boolean ready()throws Exception;
}
    private void waitFor(Check check)throws Exception{for(int n=0;
n<300;
n++){boolean[] done={false};
ins.runOnMainSync(()->{try{done[0]=check.ready();
}catch(Exception e){throw new RuntimeException(e);
}});
if(done[0])return;
Thread.sleep(50);
}fail("Listening mode scenario timed out");
}
    @Before public void before()throws Exception{oldLevel=SpeechSettings.leveling(c);
oldFade=ListeningModes.fade(c);
oldQuiet=SpeechSettings.quiet(c);
oldVoice=SpeechSettings.voice(c);
oldSilence=SpeechSettings.silence(c);
YouTubeAudio.clear(c);
anchor=ins.startActivitySync(new Intent(c,MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
waitFor(()->anchor.hasWindowFocus());
ins.runOnMainSync(()->connection=new MediaController.Builder(c,new SessionToken(c,new ComponentName(c,PlaybackService.class))).buildAsync());
player=connection.get(15,TimeUnit.SECONDS);
ins.runOnMainSync(()->{player.pause();
player.clearMediaItems();
player.setShuffleModeEnabled(false);
player.setRepeatMode(Player.REPEAT_MODE_OFF);
player.setPlaybackParameters(PlaybackParameters.DEFAULT);
player.sendCustomCommand(new SessionCommand("sleep",Bundle.EMPTY),Bundle.EMPTY);
SpeechSettings.save(c,false,false);
SpeechSettings.quiet(c,0);
});
file=AudioTestFixtures.tone(c,14000);
}
    private MediaItem item(String id){return new MediaItem.Builder().setMediaId(id).setUri(Uri.fromFile(file)).build();
}
    private Bundle command(String name,Bundle args)throws Exception{ListenableFuture<SessionResult>[] future=new ListenableFuture[1];
ins.runOnMainSync(()->future[0]=player.sendCustomCommand(new SessionCommand(name,Bundle.EMPTY),args));
SessionResult result=future[0].get(5,TimeUnit.SECONDS);
assertEquals(SessionResult.RESULT_SUCCESS,result.resultCode);
return result.extras;
}
    private void apply(int mode)throws Exception{ins.runOnMainSync(()->ListeningModes.apply(c,mode));
command("sound",Bundle.EMPTY);
}
    private void play()throws Exception{ins.runOnMainSync(()->{player.setMediaItems(Arrays.asList(item("audio-listening-first"),item("audio-listening-second")));
player.prepare();
player.play();
});
waitFor(()->player.isPlaying());
}
    @After public void after()throws Exception{try(InputStream in=new ParcelFileDescriptor.AutoCloseInputStream(ins.getUiAutomation().executeShellCommand("input keyevent 224"))){while(in.read()!=-1){}}try(InputStream in=new ParcelFileDescriptor.AutoCloseInputStream(ins.getUiAutomation().executeShellCommand("wm dismiss-keyguard"))){while(in.read()!=-1){}}ins.runOnMainSync(()->{SpeechSettings.leveling(c,oldLevel);
SpeechSettings.quiet(c,oldQuiet);
SpeechSettings.save(c,oldVoice,oldSilence);
ListeningModes.fade(c,oldFade);
if(player!=null){player.pause();
player.stop();
player.clearMediaItems();
player.setPlaybackParameters(PlaybackParameters.DEFAULT);
player.sendCustomCommand(new SessionCommand("sleep",Bundle.EMPTY),Bundle.EMPTY);
player.sendCustomCommand(new SessionCommand("sound",Bundle.EMPTY),Bundle.EMPTY);
}if(sound!=null)sound.finish();
if(anchor!=null)anchor.finish();
if(connection!=null)MediaController.releaseFuture(connection);
});
ins.waitForIdleSync();
if(file!=null)file.delete();
}
    @Test public void modesPreserveOtherSoundSettingsAndNeverStartPlayback()throws Exception{SoundProfile before=SoundSettings.readGlobal(c);
SpeechSettings.quiet(c,1);
SpeechSettings.save(c,true,true);
for(int i=0;
i<3;
i++){apply(i);
assertEquals(i,ListeningModes.current(c));
assertEquals(1,SpeechSettings.quiet(c));
assertTrue(SpeechSettings.voice(c));
assertTrue(SpeechSettings.silence(c));
assertEquals(before.bass,SoundSettings.readGlobal(c).bass);
for(int b=0;
b<5;
b++)assertEquals(before.gain(b),SoundSettings.readGlobal(c).gain(b));
ins.runOnMainSync(()->assertFalse(player.getPlayWhenReady()));
}ListeningModes.fade(c,2000);
assertEquals(-1,ListeningModes.current(c));
assertTrue(ListeningModes.summary(c).contains("Personalizado"));
}
    @Test public void smoothTransitionRunsAtDoubleSpeedAndPauseRestoresGain()throws Exception{apply(2);
play();
ins.runOnMainSync(()->{player.setPlaybackParameters(new PlaybackParameters(2f));
player.seekTo(8500);
});
waitFor(()->player.getVolume()<.85f);
ins.runOnMainSync(player::pause);
Bundle state=command("sound_status",Bundle.EMPTY);
assertFalse(state.getBoolean("fade_active"));
ins.runOnMainSync(()->assertEquals(SoundSettings.read(c).headroom(state.getBoolean("equalizer"),state.getBoolean("bass")),player.getVolume(),.001));
apply(0);
assertEquals(0,command("sound_status",Bundle.EMPTY).getInt("fade_ms"));
}
    @Test public void selectedChaptersRadioAndRemotePagesDoNotFade()throws Exception{apply(2);
MediaItem local=item("audio-chapter-mode");
AudioChapterStore.Data data=new AudioChapterStore.Data(14000,Arrays.asList(new AudioChapterStore.Chapter(0,"A"),new AudioChapterStore.Chapter(7000,"B")));
MediaItem selected=AudioChapterPlayback.configure(AudioChapterPlayback.select(local,data,1,"fixture"),true);
assertFalse(PlaybackService.localFadeItem(selected));
assertFalse(PlaybackService.localFadeItem(new MediaItem.Builder().setMediaId("remote").setUri("https://example.org/music.mp3").build()));
assertTrue(PlaybackService.localFadeItem(local));
ins.runOnMainSync(()->{player.setMediaItem(selected);
player.setRepeatMode(Player.REPEAT_MODE_ONE);
player.prepare();
player.play();
});
waitFor(()->player.isPlaying());
assertFalse(command("sound_status",Bundle.EMPTY).getBoolean("fade_eligible"));
}
    @Test public void screenOffPlaybackContinuesAndTrackSleepDisablesTransitions()throws Exception{apply(1);
play();
Bundle args=new Bundle();
args.putInt("tracks",1);
command("sleep",args);
assertFalse(command("sound_status",Bundle.EMPTY).getBoolean("fade_eligible"));
try(InputStream in=new ParcelFileDescriptor.AutoCloseInputStream(ins.getUiAutomation().executeShellCommand("input keyevent 223"))){while(in.read()!=-1){}}long[] at={0};
ins.runOnMainSync(()->at[0]=player.getCurrentPosition());
Thread.sleep(1500);
ins.runOnMainSync(()->{assertTrue("Player must remain playing",player.isPlaying());
assertTrue(player.getCurrentPosition()>at[0]+800);
});
command("sleep",Bundle.EMPTY);
assertTrue(command("sound_status",Bundle.EMPTY).getBoolean("fade_eligible"));
}
    @Test public void screenModesAndTransitionsApplyToCurrentTrack()throws Exception{apply(0);
play();
sound=ins.startActivitySync(new Intent(c,SoundActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
waitFor(()->sound.hasWindowFocus());
ins.runOnMainSync(()->{try{java.lang.reflect.Field f=SoundActivity.class.getDeclaredField("listeningMode");
f.setAccessible(true);
((Button)f.get(sound)).performClick();
}catch(Exception e){throw new RuntimeException(e);
}});
ins.waitForIdleSync();
ins.runOnMainSync(()->{try{java.lang.reflect.Field f=SoundActivity.class.getDeclaredField("listeningMode");
f.setAccessible(true);
View v=(View)f.get(sound);
assertTrue("Mode selector must be visible",v.isShown());
}catch(Exception e){throw new RuntimeException(e);
}});
ins.runOnMainSync(()->{try{java.lang.reflect.Field f=SoundActivity.class.getDeclaredField("modeDialog");
f.setAccessible(true);
AlertDialog dialog=(AlertDialog)f.get(sound);
assertNotNull("Mode dialog must exist",dialog);
assertTrue("Mode dialog must be visible",dialog.isShowing());
android.widget.ListView list=dialog.getListView();
assertEquals(3,list.getAdapter().getCount());
assertTrue("Mode selection must dispatch its real click listener",list.performItemClick(list.getChildAt(1),1,list.getAdapter().getItemId(1)));
}catch(Exception e){throw new RuntimeException(e);}});
waitFor(()->ListeningModes.current(c)==1);
ins.waitForIdleSync();
Bundle state=command("sound_status",Bundle.EMPTY);
for(int n=0;n<100&&state.getInt("fade_ms")!=1000;n++){Thread.sleep(50);state=command("sound_status",Bundle.EMPTY);}
assertTrue("Selected mode must enable leveling: "+state,state.getBoolean("leveling"));
assertEquals(1000,state.getInt("fade_ms"));
waitFor(()->player.getCurrentPosition()>800);
ins.runOnMainSync(()->{assertEquals("audio-listening-first",player.getCurrentMediaItem().mediaId);
assertTrue("Player must remain playing",player.isPlaying());
});
ins.waitForIdleSync();
Thread.sleep(250);
android.graphics.Bitmap shot=ins.getUiAutomation().takeScreenshot();
assertNotNull(shot);
try(OutputStream out=new FileOutputStream(new File(c.getFilesDir(),"listening-modes.png"))){shot.compress(android.graphics.Bitmap.CompressFormat.PNG,100,out);
}finally{shot.recycle();
}}
}
