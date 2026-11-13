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
    private boolean restoring=true,destroyed,youtubeSession,chapterUpdating;
    private String savedQueue="[]";private final ShelfCheckpoint shelfCheckpoint=new ShelfCheckpoint();
    private final Runnable checkpoint=new Runnable(){public void run(){if(player==null||RadioMedia.is(player.getCurrentMediaItem()))return;saveResume(false);if(player.isPlaying())timer.postDelayed(this,15000);}};
    private DjSession personalDj;private long historyDuration;private boolean completed;
    private final TrackSleep trackSleep=new TrackSleep();
    private final SpeechProcessor speech=new SpeechProcessor();
    private PlaybackParameters beforeRadioSpeed;private ExoPlayer player;private MediaSession session;private SoundEffects sound;private SoundRoutes soundRoutes;
    private final Handler timer=new Handler(Looper.getMainLooper());
    private final Runnable stop=()->{if(player!=null)player.pause();};
    private int fadeMs;private boolean outgoing,incoming,ramping,counted;
    private float baseVolume=1;private long rampStart,rampDuration,heardMs,playingSince;private float rampFrom,rampTo;
    private String heardId="";
    private final Runnable countListen=()->recordListening();
    private final Runnable startFade=()->{if(player.isPlaying()&&eligible()&&(player.hasNextMediaItem()||player.getRepeatMode()!=Player.REPEAT_MODE_OFF)){outgoing=true;android.util.Log.d("OndaFade","fade-out");ramp(player.getVolume(),0,Math.max(1,Math.min(fadeMs,(long)((player.getDuration()-player.getCurrentPosition())/player.getPlaybackParameters().speed))));}};
    private final Runnable rampStep=new Runnable(){public void run(){if(!ramping)return;long elapsed=SystemClock.elapsedRealtime()-rampStart;player.setVolume(FadeMath.gain(elapsed,rampDuration,rampFrom,rampTo));if(elapsed<rampDuration)timer.postDelayed(this,100);else ramping=false;}};
    private void applyRadioData(){if(player==null)return;boolean low=RadioMedia.is(player.getCurrentMediaItem())&&getSharedPreferences("radio",0).getBoolean(RadioData.KEY,true);player.setTrackSelectionParameters(player.getTrackSelectionParameters().buildUpon().setMaxAudioBitrate(low?RadioData.ADAPTIVE_MAX:Integer.MAX_VALUE).setForceLowestBitrate(low).build());}
    @Override public void onCreate(){super.onCreate();sound=new SoundEffects();fadeMs=getSharedPreferences("audio",0).getInt("fade_ms",2000);
        soundRoutes=new SoundRoutes(()->{if(player!=null&&!destroyed)applySound();},speech);
        player=new ExoPlayer.Builder(this,soundRoutes.renderers(this)).setMediaSourceFactory(new androidx.media3.exoplayer.source.DefaultMediaSourceFactory(new androidx.media3.datasource.ResolvingDataSource.Factory(new androidx.media3.datasource.DefaultDataSource.Factory(this),spec->{String host=spec.uri.getHost();if(host==null||!(host.equals("googlevideo.com")||host.endsWith(".googlevideo.com")))return spec;Map<String,String> headers=new HashMap<>(spec.httpRequestHeaders);headers.put("User-Agent",ExtractorHttp.AGENT);headers.put("Referer","https://www.youtube.com/");return spec.withRequestHeaders(headers);}))).build();player.setTrackSelectionParameters(player.getTrackSelectionParameters().buildUpon().setTrackTypeDisabled(C.TRACK_TYPE_VIDEO,true).build());player.setAudioAttributes(new AudioAttributes.Builder().setUsage(C.USAGE_MEDIA).setContentType(C.AUDIO_CONTENT_TYPE_MUSIC).build(),true);player.setHandleAudioBecomingNoisy(true);player.setWakeMode(C.WAKE_MODE_LOCAL);applySpeech();player.setPlaybackParameters(new PlaybackParameters(AudioPlaybackOptions.SPEEDS[AudioPlaybackOptions.saved(this)],1f));
        player.addListener(new Player.Listener(){
            @Override public void onPlayerError(PlaybackException error){MediaItem item=player.getCurrentMediaItem();if(YouTubeAudio.is(item)){player.pause();YouTubeAudio.remember(PlaybackService.this,item,player.getCurrentPosition(),player.getRepeatMode());DownloadHistory.analysisFailed(PlaybackService.this,YouTubeAudio.source(item),"Reprodução do YouTube",error);return;}if(RadioMedia.is(item)){player.pause();return;}if(error.errorCode==PlaybackException.ERROR_CODE_DECODING_FORMAT_UNSUPPORTED&&item!=null&&!RadioMedia.is(item)&&item.localConfiguration!=null)HiddenMedia.hide(PlaybackService.this,"audio",item.localConfiguration.uri);}
            @Override public void onPlayWhenReadyChanged(boolean ready,int reason){if(ready&&RadioMedia.is(player.getCurrentMediaItem())&&player.getPlaybackState()==Player.STATE_IDLE){player.seekToDefaultPosition();player.prepare();return;}if(!ready&&reason!=Player.PLAY_WHEN_READY_CHANGE_REASON_END_OF_MEDIA_ITEM&&RadioMedia.is(player.getCurrentMediaItem())&&player.getPlaybackState()!=Player.STATE_IDLE){player.stop();return;}if(!ready&&reason==Player.PLAY_WHEN_READY_CHANGE_REASON_END_OF_MEDIA_ITEM&&trackSleep.remaining()>0){if(trackSleep.completed()){player.setPauseAtEndOfMediaItems(false);android.util.Log.d("OndaSleep","track timer complete");}else player.play();}}
            @Override public void onPositionDiscontinuity(Player.PositionInfo oldPosition,Player.PositionInfo newPosition,int reason){
                MediaItem old=oldPosition.mediaItem,next=newPosition.mediaItem;
                if(DjSession.deviceAudio(old)&&old.localConfiguration!=null&&(next==null||!old.mediaId.equals(next.mediaId)))ShelfStore.remember(PlaybackService.this,"audio",old.localConfiguration.uri.toString(),String.valueOf(old.mediaMetadata.title),reason==Player.DISCONTINUITY_REASON_AUTO_TRANSITION?0:AudioChapterPlayback.absolute(old,oldPosition.positionMs),AudioChapterPlayback.duration(old,0));
            }
            @Override public void onAudioSessionIdChanged(int id){applySound();}
            @Override public void onMediaItemTransition(MediaItem item,int reason){applyRadioData();player.setWakeMode(RadioMedia.is(item)?C.WAKE_MODE_NETWORK:C.WAKE_MODE_LOCAL);if(RadioMedia.is(item)||YouTubeAudio.is(item)){if(beforeRadioSpeed==null)beforeRadioSpeed=player.getPlaybackParameters();player.setPlaybackParameters(PlaybackParameters.DEFAULT);}else if(beforeRadioSpeed!=null){PlaybackParameters restore=beforeRadioSpeed;beforeRadioSpeed=null;player.setPlaybackParameters(restore);}
                boolean smooth=outgoing&&(reason==Player.MEDIA_ITEM_TRANSITION_REASON_AUTO||reason==Player.MEDIA_ITEM_TRANSITION_REASON_REPEAT);cancelFade(false);incoming=smooth&&item!=null&&!item.mediaId.startsWith("catalog:");player.setVolume(incoming?0:baseVolume);
                if(reason==Player.MEDIA_ITEM_TRANSITION_REASON_AUTO||reason==Player.MEDIA_ITEM_TRANSITION_REASON_REPEAT)finishListening();resetHistory(item);String scheme=item!=null&&item.localConfiguration!=null?item.localConfiguration.uri.getScheme():null;player.setWakeMode("https".equalsIgnoreCase(scheme)||"http".equalsIgnoreCase(scheme)?C.WAKE_MODE_NETWORK:C.WAKE_MODE_LOCAL);
            }
            @Override public void onEvents(Player p,Player.Events e){
                if(e.size()==1&&e.contains(Player.EVENT_VOLUME_CHANGED))return;
                if(syncChapter())return;
                if(e.contains(Player.EVENT_PLAYBACK_STATE_CHANGED)&&p.getPlaybackState()==Player.STATE_ENDED){finishListening();if(trackSleep.remaining()>0){trackSleep.arm(0);player.setPauseAtEndOfMediaItems(false);player.pause();}}
                if(restoring&&e.contains(Player.EVENT_TIMELINE_CHANGED)&&p.getMediaItemCount()>0)restoring=false;
                boolean queueChanged=e.contains(Player.EVENT_TIMELINE_CHANGED);
                if(queueChanged||e.contains(Player.EVENT_MEDIA_ITEM_TRANSITION)||e.contains(Player.EVENT_POSITION_DISCONTINUITY)||e.contains(Player.EVENT_PLAY_WHEN_READY_CHANGED)||e.contains(Player.EVENT_PLAYBACK_STATE_CHANGED)||e.contains(Player.EVENT_SHUFFLE_MODE_ENABLED_CHANGED)||e.contains(Player.EVENT_REPEAT_MODE_CHANGED))saveResume(queueChanged);
                if(e.contains(Player.EVENT_IS_PLAYING_CHANGED)){if(p.isPlaying())VideoBackgroundService.stopForMusic(PlaybackService.this);timer.removeCallbacks(checkpoint);if(p.isPlaying()&&!RadioMedia.is(p.getCurrentMediaItem()))timer.postDelayed(checkpoint,15000);}
                if(e.contains(Player.EVENT_IS_PLAYING_CHANGED)){soundRoutes.refresh();sound.playing(p.isPlaying());float value=sound.headroom();if(value!=baseVolume){baseVolume=value;cancelFade(true);}}
                if(e.contains(Player.EVENT_MEDIA_ITEM_TRANSITION)||e.contains(Player.EVENT_IS_PLAYING_CHANGED)||e.contains(Player.EVENT_PLAYBACK_STATE_CHANGED)){updateListening();}
                if(e.contains(Player.EVENT_POSITION_DISCONTINUITY)&&!e.contains(Player.EVENT_MEDIA_ITEM_TRANSITION)){cancelFade(true);}
                if(!p.isPlaying()){timer.removeCallbacks(startFade);if(!p.getPlayWhenReady())cancelFade(true);return;}
                if(incoming){incoming=false;if(eligible()){android.util.Log.d("OndaFade","fade-in");ramp(0,baseVolume,fadeMs);}else player.setVolume(baseVolume);}
                scheduleFade();
            }
        });
        personalDj=new DjSession(this,player);
        session=new MediaSession.Builder(this,player).setSessionActivity(PendingIntent.getActivity(this,0,new Intent(this,MainActivity.class),PendingIntent.FLAG_IMMUTABLE|PendingIntent.FLAG_UPDATE_CURRENT)).setCallback(new MediaSession.Callback(){
            @Override public MediaSession.ConnectionResult onConnect(MediaSession s,MediaSession.ControllerInfo c){return new MediaSession.ConnectionResult.AcceptedResultBuilder(s).setAvailableSessionCommands(MediaSession.ConnectionResult.DEFAULT_SESSION_COMMANDS.buildUpon().add(new SessionCommand(YouTubeAudio.RESTORE,Bundle.EMPTY)).add(new SessionCommand(AudioChapterPlayback.SELECT,Bundle.EMPTY)).add(new SessionCommand("sleep",Bundle.EMPTY)).add(new SessionCommand("fade",Bundle.EMPTY)).add(new SessionCommand("radio_data",Bundle.EMPTY)).add(new SessionCommand("sound",Bundle.EMPTY)).add(new SessionCommand("sound_status",Bundle.EMPTY)).add(new SessionCommand(SpeechSettings.COMMAND,Bundle.EMPTY)).add(new SessionCommand(SpeechSettings.STATUS,Bundle.EMPTY)).add(new SessionCommand(DjSession.COMMAND,Bundle.EMPTY)).add(new SessionCommand(QueueEdit.COMMAND,Bundle.EMPTY)).build()).build();}
            @Override public ListenableFuture<SessionResult> onCustomCommand(MediaSession s,MediaSession.ControllerInfo c,SessionCommand command,Bundle args){
                if(command.customAction.equals("radio_data")){applyRadioData();return Futures.immediateFuture(new SessionResult(SessionResult.RESULT_SUCCESS));}
                if(command.customAction.equals(YouTubeAudio.RESTORE)){restoring=true;youtubeSession=false;YouTubeAudio.clear(PlaybackService.this);player.pause();player.stop();player.clearMediaItems();restoreResume();return Futures.immediateFuture(new SessionResult(SessionResult.RESULT_SUCCESS));}
                if(command.customAction.equals(AudioChapterPlayback.SELECT)){
                    try{Bundle data=args.getBundle("item");MediaItem chosen=data==null?null:MediaItem.fromBundle(data),current=player.getCurrentMediaItem();
                        if(!AudioChapterPlayback.selected(chosen)||current==null||current.localConfiguration==null||!current.mediaId.equals(chosen.mediaId)||!current.localConfiguration.uri.equals(chosen.localConfiguration.uri))return Futures.immediateFuture(new SessionResult(SessionError.ERROR_BAD_VALUE));
                        MediaItem next=AudioChapterPlayback.configure(chosen,player.getRepeatMode()==Player.REPEAT_MODE_ONE);
                        replaceChapter(next,AudioChapterPlayback.start(next));player.prepare();player.play();
                        return Futures.immediateFuture(new SessionResult(SessionResult.RESULT_SUCCESS));
                    }catch(RuntimeException error){return Futures.immediateFuture(new SessionResult(SessionError.ERROR_BAD_VALUE));}
                }
                if(command.customAction.equals(DjSession.COMMAND))return personalDj.request(args);
                if(command.customAction.equals(QueueEdit.COMMAND))return Futures.immediateFuture(QueueEdit.handle(player,args));
                if(command.customAction.equals(SpeechSettings.COMMAND)||command.customAction.equals(SpeechSettings.STATUS)){if(command.customAction.equals(SpeechSettings.COMMAND))applySpeech();return Futures.immediateFuture(new SessionResult(SessionResult.RESULT_SUCCESS,speechStatus()));}
                if(command.customAction.equals("sound")||command.customAction.equals("sound_status")){if(command.customAction.equals("sound")){applySound();applySpeech();}Bundle state=sound.status();state.putInt("quiet",SpeechSettings.quiet(PlaybackService.this));state.putLong("quiet_frames",speech.quietFrames);state.putBoolean("leveling",SpeechSettings.leveling(PlaybackService.this));state.putFloat("level_gain_db",speech.levelGainDb);state.putBoolean("speech",SpeechSettings.voice(PlaybackService.this)||SpeechSettings.silence(PlaybackService.this)||SpeechSettings.quiet(PlaybackService.this)>0);return Futures.immediateFuture(new SessionResult(SessionResult.RESULT_SUCCESS,state));}
                if(command.customAction.equals("sleep")){timer.removeCallbacks(stop);trackSleep.arm(0);player.setPauseAtEndOfMediaItems(false);
                    int tracks=Math.max(0,Math.min(20,args.getInt("tracks",0)));if(tracks>0){if(player.getMediaItemCount()==0||player.getPlaybackState()==Player.STATE_ENDED)return Futures.immediateFuture(new SessionResult(SessionError.ERROR_BAD_VALUE));trackSleep.arm(tracks);player.setPauseAtEndOfMediaItems(true);return Futures.immediateFuture(new SessionResult(SessionResult.RESULT_SUCCESS));}int minutes=Math.max(0,Math.min(120,args.getInt("minutes",0)));if(minutes>0)timer.postDelayed(stop,minutes*60000L);}
                else if(command.customAction.equals("fade")){fadeMs=Math.max(0,Math.min(3000,getSharedPreferences("audio",0).getInt("fade_ms",2000)));cancelFade(true);scheduleFade();}
                else return Futures.immediateFuture(new SessionResult(SessionError.ERROR_NOT_SUPPORTED));return Futures.immediateFuture(new SessionResult(SessionResult.RESULT_SUCCESS));}
        }).build();
        restoreResume();
    }
    private void saveResume(boolean rebuild){
        if(restoring||destroyed||player==null)return;
        MediaItem now=player.getCurrentMediaItem();
        if(YouTubeAudio.is(now)){youtubeSession=true;YouTubeAudio.remember(this,now,PlaybackContinuity.resume(player.getCurrentPosition(),player.getDuration(),player.getPlaybackState()==Player.STATE_ENDED),player.getRepeatMode());return;}
        if(youtubeSession&&now==null)return;
        if(youtubeSession){youtubeSession=false;YouTubeAudio.clear(this);rebuild=true;}
        if(rebuild){List<String> ids=new ArrayList<>();for(int i=0;i<player.getMediaItemCount();i++){MediaItem item=player.getMediaItemAt(i);if(!DjSession.deviceAudio(item)){ids.clear();break;}ids.add(item.mediaId);}savedQueue=MusicResume.encode(ids);}
        MediaItem current=player.getCurrentMediaItem();if(DjSession.deviceAudio(current)&&current.localConfiguration!=null){String uri=current.localConfiguration.uri.toString(),title=String.valueOf(current.mediaMetadata.title);long pos=AudioChapterPlayback.bookmark(current,player.getCurrentPosition(),player.getPlaybackState()==Player.STATE_ENDED),duration=AudioChapterPlayback.duration(current,player.getDuration());if(shelfCheckpoint.save(uri+"\n"+title,pos,duration,SystemClock.elapsedRealtime()))ShelfStore.remember(this,"audio",uri,title,pos,duration);}
        SharedPreferences.Editor edit=getSharedPreferences("music_resume",0).edit();
        if(rebuild){List<MediaItem> queue=new ArrayList<>();if(!savedQueue.equals("[]"))for(int i=0;i<player.getMediaItemCount();i++)queue.add(player.getMediaItemAt(i));edit.putString("queue",savedQueue).putString("dj_context",DjSession.remember(queue));}
        edit.putInt("index",Math.max(0,player.getCurrentMediaItemIndex())).putLong("position",AudioChapterPlayback.bookmark(current,player.getCurrentPosition(),player.getPlaybackState()==Player.STATE_ENDED)).putString("chapter",AudioChapterPlayback.encode(current)).putBoolean("shuffle",player.getShuffleModeEnabled()).putInt("repeat",player.getRepeatMode()).apply();
    }
    /** Recreate native sources: metadata-only replacement may retain an unclipped source. */
    private void replaceChapter(MediaItem next,long absolute){
        int index=player.getCurrentMediaItemIndex();List<MediaItem> queue=QueueEdit.snapshot(player);queue.set(index,next);
        Timeline timeline=player.getCurrentTimeline();int[] order=new int[queue.size()];boolean[] used=new boolean[queue.size()];
        boolean valid=timeline.getWindowCount()==queue.size();int at=valid?timeline.getFirstWindowIndex(true):C.INDEX_UNSET;
        for(int i=0;valid&&i<order.length;i++){
            if(at<0||at>=order.length||used[at]){valid=false;break;}
            order[i]=at;used[at]=true;at=timeline.getNextWindowIndex(at,Player.REPEAT_MODE_OFF,true);
        }
        boolean prepared=player.getPlaybackState()!=Player.STATE_IDLE,ready=player.getPlayWhenReady();
        chapterUpdating=true;
        try{
            player.setMediaItems(queue,index,AudioChapterPlayback.position(next,absolute));
            if(valid)player.setShuffleOrder(new androidx.media3.exoplayer.source.ShuffleOrder.DefaultShuffleOrder(order,System.nanoTime()));
            if(prepared)player.prepare();player.setPlayWhenReady(ready);
        }finally{chapterUpdating=false;}
    }
    private boolean syncChapter(){
        if(chapterUpdating||player==null)return false;
        MediaItem current=player.getCurrentMediaItem();boolean repeat=player.getRepeatMode()==Player.REPEAT_MODE_ONE;
        if(AudioChapterPlayback.configured(current,repeat))return false;
        long absolute=AudioChapterPlayback.absolute(current,player.getCurrentPosition());
        replaceChapter(AudioChapterPlayback.configure(current,repeat),absolute);
        return true;
    }
    private void restoreResume(){
        if(YouTubeAudio.active(this)){youtubeSession=true;restoring=false;return;}
        SharedPreferences preferences=getSharedPreferences("music_resume",0);List<String> ids=MusicResume.decode(preferences.getString("queue","[]"));
        if(ids.isEmpty()){restoring=false;return;}
        Map<String,DjMemory.Cue> context=DjMemory.decode(preferences.getString("dj_context","{}"));
        int index=preferences.getInt("index",0),repeat=Math.max(0,Math.min(2,preferences.getInt("repeat",0)));long position=preferences.getLong("position",0);boolean shuffle=preferences.getBoolean("shuffle",false);String chapter=preferences.getString("chapter","");
        resumeWorker.execute(()->{try{
            List<MediaItem> library=LibraryStore.scan(this);Map<String,MediaItem> items=new HashMap<>();Map<String,Long> durations=new HashMap<>();
            for(MediaItem item:library){items.put(item.mediaId,item);durations.put(item.mediaId,LibraryStore.number(item,"durationMs"));}
            MusicResume.Selection chosen=MusicResume.select(ids,index,position,durations);List<MediaItem> queue=new ArrayList<>();
            for(String id:chosen.ids)queue.add(DjSession.restore(items.get(id),context));
            if(!queue.isEmpty()&&!chapter.isEmpty())queue.set(chosen.index,AudioChapterPlayback.restore(this,queue.get(chosen.index),chapter));
            boolean selected=!queue.isEmpty()&&AudioChapterPlayback.selected(queue.get(chosen.index));
            int mode=!chapter.isEmpty()&&!selected&&repeat==Player.REPEAT_MODE_ONE?Player.REPEAT_MODE_OFF:repeat;
            if(selected)queue.set(chosen.index,AudioChapterPlayback.configure(queue.get(chosen.index),mode==Player.REPEAT_MODE_ONE));
            long at=queue.isEmpty()?0:AudioChapterPlayback.position(queue.get(chosen.index),chosen.position);
            timer.post(()->{if(destroyed||!restoring)return;restoring=false;if(player.getMediaItemCount()>0)return;
                if(queue.isEmpty()){getSharedPreferences("music_resume",0).edit().clear().apply();return;}
                savedQueue=MusicResume.encode(chosen.ids);player.setPlayWhenReady(false);player.setMediaItems(queue,chosen.index,at);player.setShuffleModeEnabled(shuffle);player.setRepeatMode(mode);
                android.util.Log.d("OndaResume","restored count="+queue.size()+" index="+chosen.index+" position="+at);
            });
        }catch(Exception e){timer.post(()->{if(!destroyed)restoring=false;});}});
    }
    private void applySpeech(){speech.enabled(SpeechSettings.voice(this));speech.leveling(SpeechSettings.leveling(this));speech.quiet(SpeechSettings.quiet(this));player.setSkipSilenceEnabled(SpeechSettings.silence(this));}
    private Bundle speechStatus(){Bundle b=new Bundle();b.putBoolean("voice",SpeechSettings.voice(this));b.putBoolean("silence",player.getSkipSilenceEnabled());b.putBoolean("playing",player.isPlaying());b.putBoolean("compatible",speech.rate>0&&speech.channels>0);b.putLong("frames",speech.processedFrames);b.putInt("quiet",SpeechSettings.quiet(this));b.putLong("quiet_frames",speech.quietFrames);b.putBoolean("leveling",SpeechSettings.leveling(this));b.putLong("level_frames",speech.levelFrames);b.putLong("bypass_bytes",speech.bypassBytes);b.putFloat("level_gain_db",speech.levelGainDb);return b;}
    private void applySound(){sound.apply(SoundSettings.read(this),player.getAudioSessionId(),player.isPlaying());baseVolume=sound.headroom();cancelFade(true);}
    private boolean eligible(){MediaItem item=player.getCurrentMediaItem();return fadeMs>0&&item!=null&&!YouTubeAudio.is(item)&&!item.mediaId.startsWith("catalog:")&&player.getDuration()>fadeMs*2L;}
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
    @Override public void onDestroy(){saveResume(false);destroyed=true;if(personalDj!=null)personalDj.close();resumeWorker.shutdownNow();timer.removeCallbacksAndMessages(null);if(session!=null)session.release();if(soundRoutes!=null)soundRoutes.close();if(sound!=null)sound.release();if(player!=null)player.release();super.onDestroy();}
}
