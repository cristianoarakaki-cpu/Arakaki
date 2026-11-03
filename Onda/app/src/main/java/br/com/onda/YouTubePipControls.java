package br.com.onda;

import android.app.*;
import android.content.*;
import android.graphics.drawable.Icon;
import android.media.MediaMetadata;
import android.media.session.*;
import android.net.Uri;
import android.os.*;
import android.webkit.WebView;
import androidx.core.content.ContextCompat;
import androidx.media3.session.MediaController;
import androidx.media3.session.SessionToken;
import com.google.common.util.concurrent.ListenableFuture;
import java.util.*;
import java.util.function.*;

/** Activity-scoped transport: PiP/hardware commands belong to this web video, never the music queue. */
@androidx.media3.common.util.UnstableApi
final class YouTubePipControls {
    private static final String PLAY="br.com.onda.musica.YOUTUBE_PIP_PLAY",PAUSE="br.com.onda.musica.YOUTUBE_PIP_PAUSE";
    private final Activity owner;
    private final Supplier<WebView> browser;
    private final BooleanSupplier visibleVideo;
    private final Handler main=new Handler(Looper.getMainLooper());
    private final String instance=UUID.randomUUID().toString();
    private final ArrayList<RemoteAction> actions=new ArrayList<>();
    private MediaSession session;
    private MediaController music;
    private ListenableFuture<MediaController> connection;
    private int generation;
    private String token="";
    private boolean registered;
    private final BroadcastReceiver receiver=new BroadcastReceiver(){@Override public void onReceive(Context c,Intent i){if(!owner.isInPictureInPictureMode()||!token.equals(i.getStringExtra("owner"))||token.isEmpty())return;if(PLAY.equals(i.getAction()))control(true);else if(PAUSE.equals(i.getAction()))control(false);}};
    YouTubePipControls(Activity owner,Supplier<WebView> browser,BooleanSupplier visibleVideo){this.owner=owner;this.browser=browser;this.visibleVideo=visibleVideo;IntentFilter filter=new IntentFilter(PLAY);filter.addAction(PAUSE);filter.addDataScheme("onda-youtube-pip");ContextCompat.registerReceiver(owner,receiver,filter,ContextCompat.RECEIVER_NOT_EXPORTED);registered=true;}
    private boolean active(){return session!=null&&visibleVideo.getAsBoolean()&&browser.get()!=null&&!owner.isDestroyed();}
    void enable(){
        if(session!=null){refresh();return;}
        token=instance+"-"+(++generation);
        session=new MediaSession(owner,"OndaYouTubeVideo");
        session.setFlags(MediaSession.FLAG_HANDLES_MEDIA_BUTTONS|MediaSession.FLAG_HANDLES_TRANSPORT_CONTROLS);
        session.setCallback(new MediaSession.Callback(){@Override public void onPlay(){control(true);}@Override public void onPause(){control(false);}@Override public void onStop(){control(false);}},main);
        state(false);session.setActive(true);
        for(boolean playing:new boolean[]{true,false}){String action=playing?PLAY:PAUSE,label=playing?"Reproduzir YouTube":"Pausar YouTube";Intent intent=new Intent(action).setPackage(owner.getPackageName()).setData(Uri.parse("onda-youtube-pip://"+token+"/"+(playing?"play":"pause"))).putExtra("owner",token);PendingIntent pending=PendingIntent.getBroadcast(owner,playing?741:742,intent,PendingIntent.FLAG_IMMUTABLE|PendingIntent.FLAG_UPDATE_CURRENT);actions.add(new RemoteAction(Icon.createWithResource(owner,playing?android.R.drawable.ic_media_play:android.R.drawable.ic_media_pause),label,label,pending));}
        // Explicit pause clears Media3's playWhenReady, so releasing web audio focus cannot resume old music.
        VideoBackgroundService.stopForMusic(owner);
        connection=new MediaController.Builder(owner,new SessionToken(owner,new ComponentName(owner,PlaybackService.class))).buildAsync();
        pauseMusic(this::refresh);refresh();
    }
    List<RemoteAction> actions(){return new ArrayList<>(actions);}
    private void pauseMusic(Runnable after){final int request=generation;if(connection==null){if(active())after.run();return;}connection.addListener(()->{if(request!=generation||!active())return;try{music=connection.get();music.pause();}catch(Exception ignored){}if(request==generation&&active())after.run();},main::post);}
    private void state(boolean playing){if(session==null)return;session.setPlaybackState(new PlaybackState.Builder().setActions(PlaybackState.ACTION_PLAY|PlaybackState.ACTION_PAUSE|PlaybackState.ACTION_PLAY_PAUSE|PlaybackState.ACTION_STOP).setState(playing?PlaybackState.STATE_PLAYING:PlaybackState.STATE_PAUSED,PlaybackState.PLAYBACK_POSITION_UNKNOWN,playing?1f:0f).build());WebView web=browser.get();String title=web==null?null:web.getTitle();session.setMetadata(new MediaMetadata.Builder().putString(MediaMetadata.METADATA_KEY_TITLE,title==null||title.isEmpty()?"YouTube no Onda":title).build());}
    void refresh(){if(!active())return;WebView web=browser.get();int request=generation;web.evaluateJavascript("(function(){var v=document.querySelector('video');return !!v&&!v.paused&&!v.ended;})()",value->{if(request==generation&&active()&&browser.get()==web)state("true".equals(value));});}
    private void control(boolean play){if(!active())return;Runnable command=()->{if(!active())return;WebView web=browser.get();int request=generation;String script=play?"(function(){var v=document.querySelector('video');if(!v)return false;try{var p=v.play();if(p&&p.catch)p.catch(function(){});}catch(e){}return !v.paused;})()":"(function(){var v=document.querySelector('video');if(!v)return false;v.pause();return true;})()";web.evaluateJavascript(script,ignored->{if(request==generation&&active()&&browser.get()==web)refresh();});main.postDelayed(()->{if(request==generation&&active())refresh();},500);};if(play)pauseMusic(command);else command.run();}
    void disable(){generation++;main.removeCallbacksAndMessages(null);if(session!=null){session.setActive(false);session.release();session=null;}for(RemoteAction action:actions)action.getActionIntent().cancel();actions.clear();token="";music=null;if(connection!=null){MediaController.releaseFuture(connection);connection=null;}}
    void release(){disable();if(registered){owner.unregisterReceiver(receiver);registered=false;}}
}
