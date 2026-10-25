package br.com.onda;

import android.app.*;
import android.content.*;
import android.content.pm.ServiceInfo;
import android.media.*;
import android.media.session.*;
import android.net.Uri;
import android.os.*;
import org.videolan.libvlc.LibVLC;
import org.videolan.libvlc.Media;
import org.videolan.libvlc.MediaPlayer;
import java.util.*;
import java.util.concurrent.*;

/** Audio-only continuation of the current local video; independent of its Activity. */
public final class VideoBackgroundService extends Service {
 static final String RETURN="br.com.onda.RETURN_VIDEO",CHANNEL="onda_video_background";private static final int NOTICE=903;
 static final class Snapshot {
  final Uri uri;final String title,file;final float rate;final int volume;final boolean software;final VideoLoop loop;
  long position,duration;boolean playing;
  Snapshot(Uri u,String t,String f,long p,long d,float r,int v,boolean s,VideoLoop l,boolean play){uri=u;title=t;file=f;position=Math.max(0,p);duration=Math.max(0,d);rate=r;volume=v;software=s;loop=l;playing=play;}
 }
 private static VideoBackgroundService instance;private static Snapshot pending;
 static boolean active(){return instance!=null&&instance.state!=null||pending!=null;}
 static void start(Context context,Snapshot state){pending=state;Intent intent=new Intent(context,VideoBackgroundService.class).setAction("start");if("content".equals(state.uri.getScheme()))intent.setData(state.uri).setClipData(ClipData.newRawUri("Vídeo",state.uri)).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);try{androidx.core.content.ContextCompat.startForegroundService(context,intent);}catch(RuntimeException e){pending=null;throw e;}}
 static Snapshot take(Context context){VideoBackgroundService service=instance;Snapshot result=service!=null&&service.state!=null?service.snapshot():pending;pending=null;if(service!=null){service.returning=true;service.remember();service.pause();service.state=null;service.stopForeground(STOP_FOREGROUND_REMOVE);service.stopSelf();}context.stopService(new Intent(context,VideoBackgroundService.class));return result;}
 static void stopForMusic(Context context){pending=null;VideoBackgroundService service=instance;if(service!=null){service.remember();service.returning=true;service.pause();service.state=null;service.stopForeground(STOP_FOREGROUND_REMOVE);service.stopSelf();}context.stopService(new Intent(context,VideoBackgroundService.class));}
 private final Handler main=new Handler(Looper.getMainLooper());private final ExecutorService worker=Executors.newSingleThreadExecutor();
 private LibVLC engine;private MediaPlayer player;private ParcelFileDescriptor descriptor;private AudioManager audio;private AudioFocusRequest focus;private MediaSession session;private PowerManager.WakeLock wake;
 private Snapshot state;private boolean wanted,destroyed,returning,ducked,errored;private int generation;private long seekTarget=-1,lastState,lastSaved;
 private final BroadcastReceiver noisy=new BroadcastReceiver(){public void onReceive(Context c,Intent i){pause();}};
 @Override public void onCreate(){super.onCreate();instance=this;NotificationManager manager=(NotificationManager)getSystemService(NOTIFICATION_SERVICE);manager.createNotificationChannel(new NotificationChannel(CHANNEL,"Vídeo em segundo plano",NotificationManager.IMPORTANCE_LOW));
  session=new MediaSession(this,"Onda vídeo");session.setCallback(new MediaSession.Callback(){@Override public void onPlay(){play();}@Override public void onPause(){pause();}@Override public void onStop(){stopSelf();}@Override public void onSeekTo(long position){if(state!=null&&player.isSeekable()){seekTarget=Math.max(0,Math.min(position,Math.max(0,player.getLength()-500)));applySeek();publish();}}},main);session.setActive(true);foreground();
  audio=(AudioManager)getSystemService(AUDIO_SERVICE);focus=new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN).setAudioAttributes(new AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_MOVIE).build()).setOnAudioFocusChangeListener(change->{if(change==AudioManager.AUDIOFOCUS_GAIN){ducked=false;volume();}else if(change==AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK){ducked=true;volume();}else pause();},main).build();
  wake=((PowerManager)getSystemService(POWER_SERVICE)).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK,"onda:video-audio");wake.setReferenceCounted(false);
  engine=new LibVLC(getApplicationContext(),new ArrayList<>(Arrays.asList("--no-video","--no-spu","--no-video-title-show","--no-stats")));player=new MediaPlayer(engine);player.setEventListener(event->{if(destroyed||state==null)return;switch(event.type){
   case MediaPlayer.Event.Playing:player.setRate(state.rate);volume();lock(wanted);publish();break;
   case MediaPlayer.Event.TimeChanged:if(!applySeek()&&wanted&&state.loop!=null&&state.loop.active()){long at=state.loop.correct(player.getTime(),SystemClock.elapsedRealtime());if(at==VideoLoop.DONE||at==VideoLoop.FAILED)pause();else if(at>=0)player.setTime(at);}long now=SystemClock.elapsedRealtime();if(now-lastState>1500){lastState=now;publishState();android.util.Log.d("OndaVideoBg","position "+player.getTime()+" playing "+player.isPlaying());}if(now-lastSaved>15000){lastSaved=now;remember();}break;
   case MediaPlayer.Event.LengthChanged:publish();break;
   case MediaPlayer.Event.Paused:lock(false);remember();publish();break;
   case MediaPlayer.Event.EndReached:if(wanted&&state.loop!=null&&state.loop.active()){long at=state.loop.atEnd(SystemClock.elapsedRealtime());if(at>=0){state.position=at;open();break;}}state.position=0;VideoProgressStore.clear(this,state.uri);wanted=false;lock(false);audio.abandonAudioFocusRequest(focus);publish();break;
   case MediaPlayer.Event.EncounteredError:errored=true;wanted=false;lock(false);remember();audio.abandonAudioFocusRequest(focus);publish();break;
   default:break;
  }});
  IntentFilter filter=new IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY);androidx.core.content.ContextCompat.registerReceiver(this,noisy,filter,androidx.core.content.ContextCompat.RECEIVER_NOT_EXPORTED);
 }
 @Override public int onStartCommand(Intent intent,int flags,int id){foreground();String action=intent==null?"":intent.getAction();if("start".equals(action)){Snapshot next=pending;pending=null;if(next==null){stopSelf();return START_NOT_STICKY;}remember();state=next;returning=false;errored=false;wanted=true;if(state.loop!=null)state.loop.continuePlayback();open();}else if("toggle".equals(action)){if(wanted)pause();else play();}else if("stop".equals(action))stopSelf();else if(state==null)stopSelf();return START_NOT_STICKY;}
 private void open(){if(state==null)return;int request=++generation;player.stop();closeDescriptor();seekTarget=state.position;wanted=true;lock(true);publish();Uri owner=state.uri;worker.execute(()->{ParcelFileDescriptor fd=null;try{fd=getContentResolver().openFileDescriptor(owner,"r");if(fd==null)throw new java.io.IOException();ParcelFileDescriptor ready=fd;main.post(()->{if(destroyed||request!=generation){try{ready.close();}catch(Exception ignored){}return;}descriptor=ready;Media media=new Media(engine,ready.getFileDescriptor());try{media.addOption(":no-video");media.addOption(":no-spu");player.setMedia(media);}finally{media.release();}if(wanted&&gainFocus())player.play();else pause();});}catch(Exception e){if(fd!=null)try{fd.close();}catch(Exception ignored){}main.post(()->{if(!destroyed&&request==generation){errored=true;pause();}});}});}
 private boolean applySeek(){if(seekTarget>=0&&player.getLength()>0&&player.getTime()>0){long at=Math.min(seekTarget,Math.max(0,player.getLength()-500));seekTarget=-1;if(player.isSeekable()&&at>0)player.setTime(at);return true;}return false;}
 private boolean gainFocus(){return audio.requestAudioFocus(focus)==AudioManager.AUDIOFOCUS_REQUEST_GRANTED;}
 private void play(){if(state==null)return;if(errored){errored=false;open();return;}if(!gainFocus()){pause();return;}wanted=true;lock(true);if(player.getLength()>0&&player.getTime()>=player.getLength()-500){state.position=0;open();}else player.play();publish();}
 private void pause(){android.util.Log.d("OndaVideoBg","paused");wanted=false;if(player!=null)player.pause();lock(false);remember();if(audio!=null&&focus!=null)audio.abandonAudioFocusRequest(focus);publish();}
 private void volume(){if(player!=null&&state!=null)player.setVolume(ducked?Math.round(state.volume*.25f):state.volume);}
 private void lock(boolean value){if(wake==null)return;if(value&&!wake.isHeld())wake.acquire();else if(!value&&wake.isHeld())wake.release();}
 private Snapshot snapshot(){long at=seekTarget>=0?seekTarget:Math.max(0,player.getTime());long length=Math.max(state.duration,Math.max(0,player.getLength()));return new Snapshot(state.uri,state.title,state.file,at,length,state.rate,state.volume,state.software,state.loop,wanted);}
 private void remember(){if(state!=null&&player!=null){long duration=Math.max(state.duration,Math.max(0,player.getLength()));long at=seekTarget>=0?seekTarget:Math.max(0,player.getTime());if(duration>0)VideoProgressStore.save(this,state.uri,at,duration);}}
 private void publishState(){if(session==null)return;long at=state==null?0:seekTarget>=0?seekTarget:Math.max(0,player==null?0:player.getTime());long actions=PlaybackState.ACTION_PLAY|PlaybackState.ACTION_PAUSE|PlaybackState.ACTION_PLAY_PAUSE|PlaybackState.ACTION_STOP;if(player!=null&&player.isSeekable())actions|=PlaybackState.ACTION_SEEK_TO;session.setPlaybackState(new PlaybackState.Builder().setActions(actions).setState(errored?PlaybackState.STATE_ERROR:wanted?PlaybackState.STATE_PLAYING:PlaybackState.STATE_PAUSED,at,state==null?1:state.rate,SystemClock.elapsedRealtime()).build());}
 private void publish(){if(session==null)return;publishState();session.setMetadata(new MediaMetadata.Builder().putString(MediaMetadata.METADATA_KEY_TITLE,state==null?"Vídeo do Onda":state.title).putString(MediaMetadata.METADATA_KEY_ARTIST,"Áudio do vídeo em segundo plano").putLong(MediaMetadata.METADATA_KEY_DURATION,state==null?0:Math.max(state.duration,Math.max(0,player==null?0:player.getLength()))).build());((NotificationManager)getSystemService(NOTIFICATION_SERVICE)).notify(NOTICE,notice());}
 private Notification notice(){Intent back=new Intent(this,VideoActivity.class).setAction(RETURN).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP|Intent.FLAG_ACTIVITY_SINGLE_TOP);if(state!=null&&"content".equals(state.uri.getScheme()))back.setData(state.uri).setClipData(ClipData.newRawUri("Vídeo",state.uri)).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);PendingIntent content=PendingIntent.getActivity(this,940,back,PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);PendingIntent toggle=PendingIntent.getService(this,941,new Intent(this,VideoBackgroundService.class).setAction("toggle"),PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);PendingIntent stop=PendingIntent.getService(this,942,new Intent(this,VideoBackgroundService.class).setAction("stop"),PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
  return new Notification.Builder(this,CHANNEL).setSmallIcon(android.R.drawable.ic_media_play).setContentTitle(state==null?"Onda • vídeo em segundo plano":state.title).setContentText(errored?"Arquivo indisponível • toque para voltar ao vídeo":wanted?"Áudio do vídeo • toque para voltar":"Vídeo pausado • toque para voltar").setContentIntent(content).setDeleteIntent(stop).setOnlyAlertOnce(true).setOngoing(wanted).setVisibility(Notification.VISIBILITY_PUBLIC).setStyle(new Notification.MediaStyle().setMediaSession(session.getSessionToken()).setShowActionsInCompactView(0,1)).addAction(new Notification.Action.Builder(android.graphics.drawable.Icon.createWithResource(this,wanted?android.R.drawable.ic_media_pause:android.R.drawable.ic_media_play),wanted?"Pausar":"Reproduzir",toggle).build()).addAction(new Notification.Action.Builder(android.graphics.drawable.Icon.createWithResource(this,android.R.drawable.ic_menu_close_clear_cancel),"Parar",stop).build()).build();
 }
 private void foreground(){if(Build.VERSION.SDK_INT>=29)startForeground(NOTICE,notice(),ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK);else startForeground(NOTICE,notice());}
 private void closeDescriptor(){if(descriptor!=null){try{descriptor.close();}catch(Exception ignored){}descriptor=null;}}
 @Override public IBinder onBind(Intent intent){return null;}
 @Override public void onDestroy(){destroyed=true;generation++;pending=null;if(!returning)remember();stopForeground(STOP_FOREGROUND_REMOVE);lock(false);if(audio!=null&&focus!=null)audio.abandonAudioFocusRequest(focus);unregisterReceiver(noisy);if(player!=null){player.setEventListener(null);player.stop();player.release();}closeDescriptor();if(engine!=null)engine.release();if(session!=null){session.setActive(false);session.release();}worker.shutdownNow();main.removeCallbacksAndMessages(null);if(instance==this)instance=null;super.onDestroy();}
}
