package br.com.onda;

import android.os.*;
import android.app.PendingIntent;
import android.content.Intent;
import android.content.SharedPreferences;
import java.util.*;
import java.util.concurrent.*;
import androidx.media3.common.*;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.session.*;
import com.google.common.util.concurrent.*;

@androidx.media3.common.util.UnstableApi
public class PlaybackService extends MediaSessionService {
    private final ExecutorService resumeWorker=Executors.newSingleThreadExecutor();
    private boolean restoring=true,destroyed;
    private String savedQueue="[]";
    private final Runnable checkpoint=new Runnable(){public void run(){saveResume(false);if(player.isPlaying())timer.postDelayed(this,15000);}};
    private DjSession personalDj;private long historyDuration;private boolean completed;
    private ExoPlayer player;private MediaSession session;private SoundEffects sound;
    private final Handler timer=new Handler(Looper.getMainLooper());
    private final Runnable stop=()->{if(player!=null)player.pause();};
    private int fadeMs;private boolean outgoing,incoming,ramping,counted;
    private float baseVolume=1;private long rampStart,rampDuration,heardMs,playingSince;private float rampFrom,rampTo;
    private String heardId="";
    private final Runnable countListen=()->recordListening();
    private final Runnable startFade=()->{if(player.isPlaying()&&eligible()&&(player.hasNextMediaItem()||player.getRepeatMode()!=Player.REPEAT_MODE_OFF)){outgoing=true;android.util.Log.d("OndaFade","fade-out");ramp(player.getVolume(),0,Math.max(1,Math.min(fadeMs,(long)((player.getDuration()-player.getCurrentPosition())/player.getPlaybackParameters().speed))));}};
    private final Runnable rampStep=new Runnable(){public void run(){if(!ramping)return;long elapsed=SystemClock.elapsedRealtime()-rampStart;player.setVolume(FadeMath.gain(elapsed,rampDuration,rampFrom,rampTo));if(elapsed<rampDuration)timer.postDelayed(this,100);else ramping=false;}};
    @Override public void onCreate(){super.onCreate();sound=new SoundEffects();fadeMs=getSharedPreferences("audio",0).getInt("fade_ms",2000);
        player=new ExoPlayer.Builder(this).build();player.setAudioAttributes(new AudioAttributes.Builder().setUsage(C.USAGE_MEDIA).setContentType(C.AUDIO_CONTENT_TYPE_MUSIC).build(),true);player.setHandleAudioBecomingNoisy(true);player.setWakeMode(C.WAKE_MODE_LOCAL);
        player.addListener(new Player.Listener(){
            @Override public void onAudioSessionIdChanged(int id){applySound();}
            @Override public void onMediaItemTransition(MediaItem item,int reason){
                boolean smooth=outgoing&&(reason==Player.MEDIA_ITEM_TRANSITION_REASON_AUTO||reason==Player.MEDIA_ITEM_TRANSITION_REASON_REPEAT);cancelFade(false);incoming=smooth&&item!=null&&!item.mediaId.startsWith("catalog:");player.setVolume(incoming?0:baseVolume);
                if(reason==Player.MEDIA_ITEM_TRANSITION_REASON_AUTO||reason==Player.MEDIA_ITEM_TRANSITION_REASON_REPEAT)finishListening();resetHistory(item);String scheme=item!=null&&item.localConfiguration!=null?item.localConfiguration.uri.getScheme():null;player.setWakeMode("https".equalsIgnoreCase(scheme)||"http".equalsIgnoreCase(scheme)?C.WAKE_MODE_NETWORK:C.WAKE_MODE_LOCAL);
            }
            @Override public void onEvents(Player p,Player.Events e){
                if(e.size()==1&&e.contains(Player.EVENT_VOLUME_CHANGED))return;
                if(e.contains(Player.EVENT_PLAYBACK_STATE_CHANGED)&&p.getPlaybackState()==Player.STATE_ENDED)finishListening();
                if(restoring&&e.contains(Player.EVENT_TIMELINE_CHANGED)&&p.getMediaItemCount()>0)restoring=false;
                boolean queueChanged=e.contains(Player.EVENT_TIMELINE_CHANGED);
                if(queueChanged||e.contains(Player.EVENT_MEDIA_ITEM_TRANSITION)||e.contains(Player.EVENT_POSITION_DISCONTINUITY)||e.contains(Player.EVENT_PLAY_WHEN_READY_CHANGED)||e.contains(Player.EVENT_PLAYBACK_STATE_CHANGED)||e.contains(Player.EVENT_SHUFFLE_MODE_ENABLED_CHANGED)||e.contains(Player.EVENT_REPEAT_MODE_CHANGED))saveResume(queueChanged);
                if(e.contains(Player.EVENT_IS_PLAYING_CHANGED)){timer.removeCallbacks(checkpoint);if(p.isPlaying())timer.postDelayed(checkpoint,15000);}
                if(e.contains(Player.EVENT_IS_PLAYING_CHANGED)){sound.playing(p.isPlaying());float value=sound.headroom();if(value!=baseVolume){baseVolume=value;cancelFade(true);}}
                if(e.contains(Player.EVENT_MEDIA_ITEM_TRANSITION)||e.contains(Player.EVENT_IS_PLAYING_CHANGED)||e.contains(Player.EVENT_PLAYBACK_STATE_CHANGED)){updateListening();}
                if(e.contains(Player.EVENT_POSITION_DISCONTINUITY)&&!e.contains(Player.EVENT_MEDIA_ITEM_TRANSITION)){cancelFade(true);}
                if(!p.isPlaying()){timer.removeCallbacks(startFade);if(!p.getPlayWhenReady())cancelFade(true);return;}
                if(incoming){incoming=false;if(eligible()){android.util.Log.d("OndaFade","fade-in");ramp(0,baseVolume,fadeMs);}else player.setVolume(baseVolume);}
                scheduleFade();
            }
        });
        personalDj=new DjSession(this,player);
        session=new MediaSession.Builder(this,player).setSessionActivity(PendingIntent.getActivity(this,0,new Intent(this,MainActivity.class),PendingIntent.FLAG_IMMUTABLE|PendingIntent.FLAG_UPDATE_CURRENT)).setCallback(new MediaSession.Callback(){
            @Override public MediaSession.ConnectionResult onConnect(MediaSession s,MediaSession.ControllerInfo c){return new MediaSession.ConnectionResult.AcceptedResultBuilder(s).setAvailableSessionCommands(MediaSession.ConnectionResult.DEFAULT_SESSION_COMMANDS.buildUpon().add(new SessionCommand("sleep",Bundle.EMPTY)).add(new SessionCommand("fade",Bundle.EMPTY)).add(new SessionCommand("sound",Bundle.EMPTY)).add(new SessionCommand("sound_status",Bundle.EMPTY)).add(new SessionCommand(DjSession.COMMAND,Bundle.EMPTY)).build()).build();}
            @Override public ListenableFuture<SessionResult> onCustomCommand(MediaSession s,MediaSession.ControllerInfo c,SessionCommand command,Bundle args){
                if(command.customAction.equals(DjSession.COMMAND))return personalDj.request(args);
                if(command.customAction.equals("sound")||command.customAction.equals("sound_status")){if(command.customAction.equals("sound"))applySound();return Futures.immediateFuture(new SessionResult(SessionResult.RESULT_SUCCESS,sound.status()));}
                if(command.customAction.equals("sleep")){timer.removeCallbacks(stop);int minutes=Math.max(0,Math.min(120,args.getInt("minutes",0)));if(minutes>0)timer.postDelayed(stop,minutes*60000L);}
                else if(command.customAction.equals("fade")){fadeMs=Math.max(0,Math.min(3000,getSharedPreferences("audio",0).getInt("fade_ms",2000)));cancelFade(true);scheduleFade();}
                else return Futures.immediateFuture(new SessionResult(SessionError.ERROR_NOT_SUPPORTED));return Futures.immediateFuture(new SessionResult(SessionResult.RESULT_SUCCESS));}
        }).build();
        restoreResume();
    }
    private void saveResume(boolean rebuild){
        if(restoring||destroyed||player==null)return;
        if(rebuild){List<String> ids=new ArrayList<>();for(int i=0;i<player.getMediaItemCount();i++){MediaItem item=player.getMediaItemAt(i);if(!LibraryStore.isLocal(item)){ids.clear();break;}ids.add(item.mediaId);}savedQueue=MusicResume.encode(ids);}
        SharedPreferences.Editor edit=getSharedPreferences("music_resume",0).edit();
        if(rebuild)edit.putString("queue",savedQueue);
        edit.putInt("index",Math.max(0,player.getCurrentMediaItemIndex())).putLong("position",player.getPlaybackState()==Player.STATE_ENDED?0:Math.max(0,player.getCurrentPosition())).putBoolean("shuffle",player.getShuffleModeEnabled()).putInt("repeat",player.getRepeatMode()).apply();
    }
    private void restoreResume(){
        SharedPreferences preferences=getSharedPreferences("music_resume",0);List<String> ids=MusicResume.decode(preferences.getString("queue","[]"));
        if(ids.isEmpty()){restoring=false;return;}
        int index=preferences.getInt("index",0),repeat=Math.max(0,Math.min(2,preferences.getInt("repeat",0)));long position=preferences.getLong("position",0);boolean shuffle=preferences.getBoolean("shuffle",false);
        resumeWorker.execute(()->{try{List<MediaItem> library=LibraryStore.scan(this);Map<String,MediaItem> items=new HashMap<>();Map<String,Long> durations=new HashMap<>();for(MediaItem item:library){items.put(item.mediaId,item);durations.put(item.mediaId,LibraryStore.number(item,"durationMs"));}MusicResume.Selection chosen=MusicResume.select(ids,index,position,durations);List<MediaItem> queue=new ArrayList<>();for(String id:chosen.ids)queue.add(items.get(id));timer.post(()->{if(destroyed||!restoring)return;restoring=false;if(player.getMediaItemCount()>0)return;if(queue.isEmpty()){getSharedPreferences("music_resume",0).edit().clear().apply();return;}savedQueue=MusicResume.encode(chosen.ids);player.setPlayWhenReady(false);player.setMediaItems(queue,chosen.index,chosen.position);player.setShuffleModeEnabled(shuffle);player.setRepeatMode(repeat);android.util.Log.d("OndaResume","restored count="+queue.size()+" index="+chosen.index+" position="+chosen.position);});}catch(Exception e){timer.post(()->{if(!destroyed)restoring=false;});}});
    }
    private void applySound(){sound.apply(SoundSettings.read(this),player.getAudioSessionId(),player.isPlaying());baseVolume=sound.headroom();cancelFade(true);}
    private boolean eligible(){MediaItem item=player.getCurrentMediaItem();return fadeMs>0&&item!=null&&!item.mediaId.startsWith("catalog:")&&player.getDuration()>fadeMs*2L;}
    private void scheduleFade(){timer.removeCallbacks(startFade);if(!player.isPlaying()||outgoing||!eligible()||(!player.hasNextMediaItem()&&player.getRepeatMode()==Player.REPEAT_MODE_OFF))return;long delay=FadeMath.delay(player.getDuration(),player.getCurrentPosition(),player.getPlaybackParameters().speed,fadeMs);if(delay>=0)timer.postDelayed(startFade,delay);}
    private void ramp(float from,float to,long duration){timer.removeCallbacks(rampStep);rampFrom=from;rampTo=to;rampDuration=duration;rampStart=SystemClock.elapsedRealtime();ramping=true;player.setVolume(from);timer.post(rampStep);}
    private void cancelFade(boolean restore){timer.removeCallbacks(startFade);timer.removeCallbacks(rampStep);ramping=false;outgoing=false;if(restore){incoming=false;player.setVolume(baseVolume);}}
    private void resetHistory(MediaItem item){updateElapsed();timer.removeCallbacks(countListen);heardId=DjSession.deviceAudio(item)?item.mediaId:"";heardMs=0;playingSince=0;counted=false;completed=false;historyDuration=0;}
    private void updateElapsed(){if(playingSince>0){heardMs+=SystemClock.elapsedRealtime()-playingSince;playingSince=0;}}
    private long listenThreshold(){long duration=player.getDuration();return duration>0?Math.min(30000,Math.max(5000,duration/2)):30000;}
    private void updateListening(){updateElapsed();timer.removeCallbacks(countListen);if(heardId.isEmpty())return;if(player.getDuration()>0)historyDuration=player.getDuration();if(player.isPlaying()){playingSince=SystemClock.elapsedRealtime();if(!counted)timer.postDelayed(countListen,Math.max(0,listenThreshold()-heardMs));}}
    private void recordListening(){updateElapsed();if(!counted&&!heardId.isEmpty()&&heardMs>=listenThreshold()){LibraryStore.heard(this,heardId);counted=true;}updateListening();}
    private void finishListening(){updateElapsed();if(!completed&&!heardId.isEmpty()&&ListeningMilestones.reachedEnd(heardMs,historyDuration)){SharedPreferences p=getSharedPreferences("listening",0);String key="complete:"+heardId;p.edit().putInt(key,Math.min(1000000,p.getInt(key,0)+1)).apply();completed=true;}}
    @Override public MediaSession onGetSession(MediaSession.ControllerInfo info){return session;}
    @Override public void onDestroy(){saveResume(false);destroyed=true;if(personalDj!=null)personalDj.close();resumeWorker.shutdownNow();timer.removeCallbacksAndMessages(null);if(session!=null)session.release();if(sound!=null)sound.release();if(player!=null)player.release();super.onDestroy();}
}
