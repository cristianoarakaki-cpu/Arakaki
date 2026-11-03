package br.com.onda;

import android.app.Activity;
import android.content.*;
import android.os.*;
import android.webkit.WebView;
import android.widget.*;
import androidx.media3.common.*;
import androidx.media3.session.MediaController;
import androidx.media3.session.*;
import com.google.common.util.concurrent.ListenableFuture;
import java.util.concurrent.*;
import java.util.function.Supplier;

/** UI handoff to the existing music service, not a second player or a hidden WebView. */
@androidx.media3.common.util.UnstableApi
final class YouTubeAudioPlayback {
 interface Resolver {MediaItem resolve(String source)throws Exception;}
 static Resolver resolver=YoutubeDownloads::audioInfo;
 private final Activity owner;private final Supplier<String> selected;private final Supplier<WebView> browser;private final Button button;private final TextView status;
 private final Handler main=new Handler(Looper.getMainLooper());private final ExecutorService worker=Executors.newSingleThreadExecutor();
 private ListenableFuture<MediaController> connection;private MediaController player;private Future<?> task;private int generation;private boolean started,busy;
 private final Player.Listener listener=new Player.Listener(){@Override public void onEvents(Player p,Player.Events e){refresh();}};
 YouTubeAudioPlayback(Activity owner,Supplier<String> selected,Supplier<WebView> browser,Button button,TextView status){this.owner=owner;this.selected=selected;this.browser=browser;this.button=button;this.status=status;}
 void start(){if(started)return;started=true;connection=new MediaController.Builder(owner,new SessionToken(owner,new ComponentName(owner,PlaybackService.class))).buildAsync();ListenableFuture<MediaController> pending=connection;pending.addListener(()->{if(!started||connection!=pending)return;try{player=pending.get();player.addListener(listener);if(!YouTubeAudio.is(player.getCurrentMediaItem()))player.pause();refresh();}catch(Exception e){status.setText("Não foi possível conectar o tocador. Tente novamente.");}},main::post);refresh();}
 void stop(){started=false;generation++;busy=false;if(task!=null)task.cancel(true);task=null;if(player!=null)player.removeListener(listener);player=null;if(connection!=null)MediaController.releaseFuture(connection);connection=null;}
 void close(){stop();worker.shutdownNow();}
 void listenWhenConnected(){if(player!=null){toggle();return;}if(connection==null)return;ListenableFuture<MediaController> pending=connection;pending.addListener(()->{if(started&&connection==pending)toggle();},main::post);}
 void pauseMusic(){if(player!=null){player.pause();VideoBackgroundService.stopForMusic(owner);}else if(connection!=null){ListenableFuture<MediaController> pending=connection;pending.addListener(()->{if(started&&connection==pending&&player!=null)player.pause();},main::post);}}
 private String source(){String source=YouTubeAudio.canonical(selected.get());if(source.isEmpty()&&player!=null&&YouTubeAudio.is(player.getCurrentMediaItem()))source=YouTubeAudio.source(player.getCurrentMediaItem());return source;}
 void refresh(){if(!started)return;String source=source();MediaItem item=player==null?null:player.getCurrentMediaItem();boolean same=YouTubeAudio.is(item)&&source.equals(YouTubeAudio.source(item));button.setEnabled(player!=null&&!busy&&!source.isEmpty());button.setText(busy?"Preparando áudio…":same&&player.getPlayWhenReady()?"Pausar áudio do YouTube":same?"Retomar áudio do YouTube":"Ouvir com tela desligada");button.setContentDescription(button.getText());}
 void toggle(){if(!started||busy)return;if(player==null){status.setText("Tocador iniciando. Toque novamente em instantes.");return;}String source=source();if(source.isEmpty()){status.setText("Abra um vídeo antes de ouvir com a tela desligada.");return;}MediaItem item=player.getCurrentMediaItem();boolean same=YouTubeAudio.is(item)&&source.equals(YouTubeAudio.source(item));if(same&&player.getPlayWhenReady()){player.pause();status.setText("Áudio do YouTube pausado.");refresh();return;}
  if(same&&player.getPlayerError()==null&&player.getPlaybackState()!=Player.STATE_IDLE&&!YouTubeAudio.expired(item)){pauseWeb(ignored->{if(player==null||!started)return;if(player.getPlaybackState()==Player.STATE_ENDED)player.seekToDefaultPosition();player.play();status.setText("YouTube no tocador • pode desligar a tela.");});return;}
  pauseMusic();busy=true;int request=++generation;status.setText("Preparando áudio do vídeo escolhido. Aguarde antes de desligar a tela.");refresh();
  pauseWeb(position->{if(!valid(request,source))return;long resume=same?Math.max(0,player.getCurrentPosition()):position;if(resume==0&&source.equals(YouTubeAudio.saved(owner)))resume=owner.getSharedPreferences("youtube_audio",0).getLong("position",0);final long start=resume;
   task=worker.submit(()->{try{MediaItem audio=resolver.resolve(source);if(!YouTubeAudio.is(audio)||!source.equals(YouTubeAudio.source(audio)))throw new Exception("O áudio recebido não corresponde ao vídeo escolhido.");main.post(()->{if(!valid(request,source))return;busy=false;player.pause();player.setMediaItem(audio,start);player.setRepeatMode(Player.REPEAT_MODE_OFF);player.setShuffleModeEnabled(false);player.prepare();player.play();YouTubeAudio.remember(owner,audio,start);status.setText("YouTube no tocador • pode desligar a tela. O player controla este vídeo.");refresh();});}catch(Exception error){String detail=DownloadHistory.analysisFailed(owner,source,"Áudio do YouTube",error);main.post(()->{if(!valid(request,source))return;busy=false;status.setText(detail);new android.app.AlertDialog.Builder(owner).setTitle("Áudio do YouTube indisponível").setMessage(detail+"\n\nA música anterior permanece pausada. Você pode continuar assistindo na página. O erro foi salvo no relatório de downloads.").setPositiveButton("OK",null).show();refresh();});}});
  });
 }
 private boolean valid(int request,String source){boolean valid=started&&request==generation&&player!=null&&!owner.isFinishing()&&source.equals(source());if(!valid&&request==generation){busy=false;refresh();}return valid;}
 private void pauseWeb(java.util.function.LongConsumer after){WebView web=browser.get();if(web==null){after.accept(0);return;}web.evaluateJavascript("(function(){var v=document.querySelector('video');var p=v&&!v.ended?Math.max(0,v.currentTime||0):0;document.querySelectorAll('video,audio').forEach(function(m){m.pause();});return Math.floor(p*1000);})()",value->{long position=0;try{position=Math.max(0,Long.parseLong(value));}catch(Exception ignored){}after.accept(position);});}
 void restoreMusic(){if(player==null)return;generation++;busy=false;if(task!=null)task.cancel(true);player.sendCustomCommand(new SessionCommand(YouTubeAudio.RESTORE,Bundle.EMPTY),Bundle.EMPTY);owner.startActivity(new Intent(owner,MainActivity.class));status.setText("Voltando à fila de músicas, pausada.");}
}
