package br.com.onda;
import android.app.*;import android.content.*;import android.content.pm.ServiceInfo;import android.content.res.AssetFileDescriptor;import android.os.*;
import java.io.*;import java.util.Set;import java.util.concurrent.*;import org.json.*;
/** Explicit local conversion, independent of screens; no automatic retry or network. */
@androidx.media3.common.util.UnstableApi
public class ChapterExportService extends Service {
 private static final String CHANNEL="onda-chapter-export",PREF="chapter-export";static final int NOTICE=907;
 interface Listener{void changed(Snapshot snapshot);}
 interface Converter{void convert(android.content.Context context,ChapterExportJob job,AssetFileDescriptor destination,ChapterExportTask.Control control)throws IOException;}
 static volatile Converter converter=ChapterExportTask::run;
 private static final Set<Listener> listeners=new CopyOnWriteArraySet<>();private static volatile Snapshot current;private static volatile ChapterExportService live;
 static final class Snapshot{
  final ChapterExportJob job;final String phase,message;final long at,total;final boolean running;
  Snapshot(ChapterExportJob job,String phase,String message,long at,long total){this.job=job;this.phase=phase;this.message=message;this.at=at;this.total=total;running="running".equals(phase)||"cancelling".equals(phase);}
  Snapshot with(String phase,String message,long at,long total){return new Snapshot(job,phase,message,at,total);}
 }
 static Snapshot state(Context c){Snapshot state=current;if(state!=null)return state;try{String text=c.getSharedPreferences(PREF,0).getString("last","");if(text.isEmpty())return null;JSONObject j=new JSONObject(text);String phase=j.getString("phase"),message=j.getString("message");if("running".equals(phase)||"cancelling".equals(phase)){phase="interrupted";message="O Android interrompeu a conversão. Confira o destino antes de tentar novamente; ele pode estar incompleto.";}state=new Snapshot(ChapterExportJob.parse(j.getJSONObject("job").toString()),phase,message,j.optLong("at"),j.optLong("total"));current=state;}catch(Exception ignored){}return state;}
 static void listen(Listener listener){listeners.add(listener);}static void unlisten(Listener listener){listeners.remove(listener);}
 static boolean start(Context c,ChapterExportJob job)throws IOException{
  Snapshot active=state(c);if(active!=null&&active.running||live!=null&&live.finished)return false;
  if(!job.valid())throw new IOException("Conversão inválida");
  // Pass an already-open write descriptor, granting only READ on the source URI.
  // This supports read-only source providers without requesting write access to the original.
  try(AssetFileDescriptor target=c.getContentResolver().openAssetFileDescriptor(job.target,"rw")){
   if(target==null)throw new IOException("Não foi possível abrir o destino");
   Intent intent=new Intent(c,ChapterExportService.class).putExtra("job",job.json().toString()).putExtra("destination",target);
   ClipData clip=ClipData.newRawUri("Destino MP3",job.target);if("content".equals(job.source.getScheme()))clip.addItem(new ClipData.Item(job.source));intent.setClipData(clip).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
   androidx.core.content.ContextCompat.startForegroundService(c,intent);return true;
  }catch(JSONException error){throw new IOException(error);}
 }
 static void cancel(Context c,Snapshot state){if(state!=null&&state.running)c.startService(new Intent(c,ChapterExportService.class).setAction("cancel").putExtra("token",state.job.token));}
 private final Handler main=new Handler(Looper.getMainLooper());private final ExecutorService worker=Executors.newSingleThreadExecutor();
 private volatile boolean cancelled,finished;private volatile Thread processing;private Snapshot job;private AssetFileDescriptor pending;private PowerManager.WakeLock wake;private long lastProgress,lastNotification;
 @Override public IBinder onBind(Intent intent){return null;}
 @Override public void onCreate(){super.onCreate();live=this;((NotificationManager)getSystemService(NOTIFICATION_SERVICE)).createNotificationChannel(new NotificationChannel(CHANNEL,"Conversão de faixas",NotificationManager.IMPORTANCE_LOW));}
 @Override public int onStartCommand(Intent intent,int flags,int startId){
  if(intent==null){if(job==null)stopSelf(startId);return START_NOT_STICKY;}
  if("cancel".equals(intent.getAction())){if(job!=null&&job.job.token.equals(intent.getStringExtra("token")))requestCancel();else if(job==null)stopSelf(startId);return START_NOT_STICKY;}
  AssetFileDescriptor descriptor=intent.getParcelableExtra("destination");if(job!=null){close(descriptor);return START_NOT_STICKY;}
  try{ChapterExportJob request=ChapterExportJob.parse(intent.getStringExtra("job"));if(descriptor==null)throw new IOException("Destino indisponível");pending=descriptor;job=new Snapshot(request,"running","Preparando a conversão. Pode minimizar o Onda.",0,request.end-request.start);
   if(Build.VERSION.SDK_INT>=35)startForeground(NOTICE,notice(job),ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROCESSING);else if(Build.VERSION.SDK_INT>=29)startForeground(NOTICE,notice(job),ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC);else startForeground(NOTICE,notice(job));
   wake=((PowerManager)getSystemService(POWER_SERVICE)).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK,"Onda:ChapterExport");wake.acquire();publish(job,true);worker.execute(this::run);
  }catch(Exception error){close(descriptor);pending=null;if(job!=null)finish(job.with("error",DownloadFailure.describe("Iniciar conversão",error),0,job.total));else stopSelf(startId);}return START_NOT_STICKY;
 }
 private Notification notice(Snapshot state){Intent open=state.job.screen(this).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP|Intent.FLAG_ACTIVITY_SINGLE_TOP);PendingIntent content=PendingIntent.getActivity(this,NOTICE,open,PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);Notification.Builder notice=new Notification.Builder(this,CHANNEL).setSmallIcon(android.R.drawable.stat_sys_download).setContentTitle("Onda • "+state.job.title).setContentText(state.message).setStyle(new Notification.BigTextStyle().bigText(state.message)).setContentIntent(content).setOnlyAlertOnce(true).setOngoing(state.running).setAutoCancel(!state.running);
  if(state.running){PendingIntent cancel=PendingIntent.getService(this,NOTICE,new Intent(this,ChapterExportService.class).setAction("cancel").putExtra("token",state.job.token),PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);notice.addAction(new Notification.Action.Builder(android.graphics.drawable.Icon.createWithResource(this,android.R.drawable.ic_menu_close_clear_cancel),"Cancelar",cancel).build());notice.setProgress(100,(int)Math.min(100,state.at*100/Math.max(1,state.total)),state.total<=0);}return notice.build();}
 private void publish(Snapshot state,boolean persist){current=state;if(persist)try{getSharedPreferences(PREF,0).edit().putString("last",new JSONObject().put("job",state.job.json()).put("phase",state.phase).put("message",state.message).put("at",state.at).put("total",state.total).toString()).apply();}catch(JSONException ignored){}for(Listener listener:listeners)try{listener.changed(state);}catch(RuntimeException ignored){}}
 private void notifyState(Snapshot state){try{((NotificationManager)getSystemService(NOTIFICATION_SERVICE)).notify(NOTICE,notice(state));}catch(RuntimeException ignored){}}
 private void check()throws IOException{if(cancelled||Thread.currentThread().isInterrupted())throw new InterruptedIOException("Conversão cancelada");}
 private void run(){processing=Thread.currentThread();Snapshot initial=job,result;AssetFileDescriptor target; synchronized(this){target=pending;pending=null;}
  try{check();converter.convert(this,initial.job,target,new ChapterExportTask.Control(){public void check()throws IOException{ChapterExportService.this.check();}public void progress(long at,long total){long now=SystemClock.elapsedRealtime();if(now-lastProgress<750&&at<total)return;lastProgress=now;Snapshot update=initial.with("running","Convertendo • "+initial.job.bitrate+" kbps. Continua com a tela apagada.",at,total);main.post(()->{if(finished||cancelled)return;publish(update,false);if(now-lastNotification>=PowerPolicy.progressInterval(OndaApplication.userVisible(ChapterExportService.this))){lastNotification=now;notifyState(update);}});}public void stage(String text){main.post(()->{if(!finished&&!cancelled){Snapshot state=current==null?initial:current;Snapshot update=state.with("running",text,state.at,state.total);publish(update,false);notifyState(update);}});}});result=initial.with("done","Faixa MP3 salva. O arquivo original foi preservado.",initial.total,initial.total);
  }catch(Exception|LinkageError error){boolean stopped=cancelled||error instanceof InterruptedIOException;result=initial.with(stopped?"cancelled":"error",stopped?"Conversão cancelada. O original foi preservado.":DownloadFailure.describe("Salvar faixa",error),0,initial.total);}
  finally{close(target);processing=null;Thread.interrupted();}Snapshot outcome=result;main.post(()->finish(outcome));
 }
 private void requestCancel(){if(job==null||finished)return;cancelled=true;Thread thread=processing;if(thread!=null)thread.interrupt();publish(job.with("cancelling","Cancelando conversão…",0,job.total),false);}
 private void finish(Snapshot state){if(finished)return;finished=true;publish(state,true);releaseWake();stopForeground("cancelled".equals(state.phase)?STOP_FOREGROUND_REMOVE:STOP_FOREGROUND_DETACH);if(!"cancelled".equals(state.phase))notifyState(state);stopSelf();}
 private void releaseWake(){if(wake!=null){if(wake.isHeld())wake.release();wake=null;}}
 private static void close(AssetFileDescriptor fd){if(fd!=null)try{fd.close();}catch(IOException ignored){}}
 @Override public void onTimeout(int startId,int type){if(job!=null&&!finished){requestCancel();finish(job.with("interrupted","O Android interrompeu a conversão. Confira o destino antes de tentar novamente.",0,job.total));}else stopSelf(startId);}
 @Override public void onDestroy(){cancelled=true;Thread thread=processing;if(thread!=null)thread.interrupt();worker.shutdownNow();synchronized(this){close(pending);pending=null;}releaseWake();if(job!=null&&!finished){finished=true;publish(job.with("interrupted","Conversão interrompida. Confira o destino antes de tentar novamente.",0,job.total),true);}if(live==this)live=null;main.removeCallbacksAndMessages(null);super.onDestroy();}
}
