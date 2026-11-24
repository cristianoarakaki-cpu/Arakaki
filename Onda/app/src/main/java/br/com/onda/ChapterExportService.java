package br.com.onda;
import android.app.*;import android.net.Uri;import android.provider.DocumentsContract;import android.content.*;import android.content.pm.ServiceInfo;import android.content.res.AssetFileDescriptor;import android.os.*;
import java.io.*;import java.util.Set;import java.util.concurrent.*;import org.json.*;
/** Explicit local conversion, independent of screens; no automatic retry or network. */
@androidx.media3.common.util.UnstableApi
public class ChapterExportService extends Service {
 private static final String CHANNEL="onda-chapter-export",PREF="chapter-export";static final int NOTICE=907;
 interface Listener{void changed(Snapshot snapshot);}
 interface Converter{void convert(android.content.Context context,ChapterExportJob job,AssetFileDescriptor destination,ChapterExportTask.Control control)throws IOException;}
 static volatile Converter converter=ChapterExportTask::run;
 private static final Set<Listener> listeners=new CopyOnWriteArraySet<>();private static volatile Snapshot current;private static volatile ChapterExportService live;
 static final class BatchProgress{
  final String token,title,folder;final int count,index,done,failed;
  BatchProgress(String token,String title,int count,int index,int done,int failed,String folder){this.token=token;this.title=title;this.count=count;this.index=index;this.done=done;this.failed=failed;this.folder=folder;}
  JSONObject json()throws JSONException{return new JSONObject().put("token",token).put("title",title).put("count",count).put("index",index).put("done",done).put("failed",failed).put("folder",folder==null?JSONObject.NULL:folder);}
  static BatchProgress parse(JSONObject j)throws JSONException{return j==null?null:new BatchProgress(j.getString("token"),j.getString("title"),j.getInt("count"),j.getInt("index"),j.getInt("done"),j.getInt("failed"),j.isNull("folder")?null:j.getString("folder"));}
 }
 static final class Snapshot{
  final ChapterExportJob job;final String phase,message;final long at,total;final boolean running;final BatchProgress batch;
  Snapshot(ChapterExportJob job,String phase,String message,long at,long total){this(job,phase,message,at,total,null);}
  Snapshot(ChapterExportJob job,String phase,String message,long at,long total,BatchProgress batch){this.job=job;this.phase=phase;this.message=message;this.at=at;this.total=total;this.batch=batch;running="running".equals(phase)||"cancelling".equals(phase);}
  Snapshot with(String phase,String message,long at,long total){return new Snapshot(job,phase,message,at,total,batch);}
  Intent screen(Context c){return batch==null?job.screen(c):new Intent(c,ChapterBatchExportActivity.class).putExtra("batch_token",batch.token).putExtra("source",job.source.toString()).putExtra("stamp",job.stamp).putExtra("name",batch.title).putExtra("duration",job.duration);}
 }
 static Snapshot state(Context c){Snapshot state=current;if(state!=null)return state;try{String text=c.getSharedPreferences(PREF,0).getString("last","");if(text.isEmpty())return null;JSONObject j=new JSONObject(text);String phase=j.getString("phase"),message=j.getString("message");if("running".equals(phase)||"cancelling".equals(phase)){phase="interrupted";message="O Android interrompeu a conversão. Confira o destino antes de tentar novamente; ele pode estar incompleto.";}state=new Snapshot(ChapterExportJob.parse(j.getJSONObject("job").toString()),phase,message,j.optLong("at"),j.optLong("total"),BatchProgress.parse(j.optJSONObject("batch")));current=state;}catch(Exception ignored){}return state;}
 static void listen(Listener listener){listeners.add(listener);}static void unlisten(Listener listener){listeners.remove(listener);}
 // Activities and this service share one process. Android rejects descriptors inside startService
 // Intents, so a short-lived slot transfers ownership locally, without keeping the Activity alive.
 private static final Handler transferMain=new Handler(Looper.getMainLooper());
 private static final java.util.concurrent.atomic.AtomicReference<ChapterBatchPlan> batchTransfer=new java.util.concurrent.atomic.AtomicReference<>();
 private static final java.util.concurrent.atomic.AtomicReference<Transfer> transfer=new java.util.concurrent.atomic.AtomicReference<>();
 private static final class Transfer{
  final String token;final AssetFileDescriptor descriptor;final Runnable timeout;
  Transfer(String token,AssetFileDescriptor descriptor){this.token=token;this.descriptor=descriptor;timeout=()->{if(transfer.compareAndSet(this,null))close(descriptor);};}
 }
 private static AssetFileDescriptor take(String token){Transfer slot=transfer.get();if(slot!=null&&slot.token.equals(token)&&transfer.compareAndSet(slot,null)){transferMain.removeCallbacks(slot.timeout);return slot.descriptor;}return null;}
 static boolean start(Context c,ChapterExportJob job)throws IOException{
  Snapshot active=state(c);if(active!=null&&active.running||live!=null&&live.finished||transfer.get()!=null||batchTransfer.get()!=null)return false;
  if(!job.valid())throw new IOException("Conversão inválida");
  AssetFileDescriptor destination=c.getContentResolver().openAssetFileDescriptor(job.target,"rw");if(destination==null)throw new IOException("Não foi possível abrir o destino");
  Transfer slot=new Transfer(job.token,destination);if(!transfer.compareAndSet(null,slot)){close(destination);return false;}
  try{
   Intent intent=new Intent(c,ChapterExportService.class).putExtra("job",job.json().toString()).putExtra("transfer",job.token);
   ClipData clip=ClipData.newRawUri("Destino MP3",job.target);if("content".equals(job.source.getScheme()))clip.addItem(new ClipData.Item(job.source));intent.setClipData(clip);intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
   transferMain.postDelayed(slot.timeout,15000);androidx.core.content.ContextCompat.startForegroundService(c,intent);return true;
  }catch(JSONException|RuntimeException error){transferMain.removeCallbacks(slot.timeout);if(transfer.compareAndSet(slot,null))close(destination);if(error instanceof RuntimeException)throw (RuntimeException)error;throw new IOException(error);}
 }
 static boolean startBatch(Context c,ChapterBatchPlan plan)throws IOException{
  Snapshot active=state(c);if(active!=null&&active.running||live!=null&&live.finished||transfer.get()!=null||batchTransfer.get()!=null)return false;
  plan.validate();if(!batchTransfer.compareAndSet(null,plan))return false;
  try{
   Intent root=new Intent(c,ChapterExportService.class).setAction("batch").putExtra("token",plan.token);root.setClipData(ClipData.newRawUri("Pasta do Onda",plan.tree));root.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION|Intent.FLAG_GRANT_WRITE_URI_PERMISSION);androidx.core.content.ContextCompat.startForegroundService(c,root);
   Intent source=new Intent(c,ChapterExportService.class).setAction("batch_source").putExtra("token",plan.token);if("content".equals(plan.source.getScheme())){source.setClipData(ClipData.newRawUri("Coletânea",plan.source));source.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);}c.startService(source);return true;
  }catch(RuntimeException error){batchTransfer.compareAndSet(plan,null);c.stopService(new Intent(c,ChapterExportService.class));throw error;}
 }
 static void cancel(Context c,Snapshot state){if(state!=null&&state.running)c.startService(new Intent(c,ChapterExportService.class).setAction("cancel").putExtra("token",state.job.token));}
 private final Handler main=new Handler(Looper.getMainLooper());private final ExecutorService worker=Executors.newSingleThreadExecutor();
 private ChapterBatchPlan batchPlan;private boolean awaitingSource;
 private volatile boolean cancelled,finished;private volatile Thread processing;private Snapshot job;private AssetFileDescriptor pending;private PowerManager.WakeLock wake;private long lastProgress,lastNotification;
 private final Runnable sourceTimeout=()->{if(awaitingSource&&!finished){awaitingSource=false;finish(job.with("error","Não foi possível obter acesso ao áudio. Abra as faixas e tente novamente.",0,job.total));}};
 @Override public IBinder onBind(Intent intent){return null;}
 @Override public void onCreate(){super.onCreate();live=this;((NotificationManager)getSystemService(NOTIFICATION_SERVICE)).createNotificationChannel(new NotificationChannel(CHANNEL,"Conversão de faixas",NotificationManager.IMPORTANCE_LOW));}
 @Override public int onStartCommand(Intent intent,int flags,int startId){
  if(intent==null){if(job==null)stopSelf(startId);return START_NOT_STICKY;}
  if("cancel".equals(intent.getAction())){if(job!=null&&job.job.token.equals(intent.getStringExtra("token")))requestCancel();else if(job==null)stopSelf(startId);return START_NOT_STICKY;}
  if("batch".equals(intent.getAction())){
   ChapterBatchPlan plan=batchTransfer.get();if(plan==null||!plan.token.equals(intent.getStringExtra("token"))||!batchTransfer.compareAndSet(plan,null)){if(job==null)stopSelf(startId);return START_NOT_STICKY;}if(job!=null)return START_NOT_STICKY;
   batchPlan=plan;job=new Snapshot(plan.representative(),"running","Preparando a seleção. Pode minimizar o Onda.",0,plan.total,new BatchProgress(plan.token,plan.title,plan.rows.size(),0,0,0,null));
   try{foreground(job);awaitingSource=true;main.postDelayed(sourceTimeout,10000);publish(job,true);}catch(RuntimeException error){finish(job.with("error",DownloadFailure.describe("Iniciar seleção",error),0,job.total));}return START_NOT_STICKY;
  }
  if("batch_source".equals(intent.getAction())){if(job!=null&&batchPlan!=null&&job.job.token.equals(intent.getStringExtra("token"))&&awaitingSource&&!finished){awaitingSource=false;main.removeCallbacks(sourceTimeout);worker.execute(this::runBatch);}else if(job==null)stopSelf(startId);return START_NOT_STICKY;}
  AssetFileDescriptor descriptor=take(intent.getStringExtra("transfer"));if(job!=null){close(descriptor);return START_NOT_STICKY;}
  try{ChapterExportJob request=ChapterExportJob.parse(intent.getStringExtra("job"));if(descriptor==null)throw new IOException("Destino indisponível");pending=descriptor;job=new Snapshot(request,"running","Preparando a conversão. Pode minimizar o Onda.",0,request.end-request.start);
   foreground(job);publish(job,true);worker.execute(this::run);
  }catch(Exception error){close(descriptor);pending=null;if(job!=null)finish(job.with("error",DownloadFailure.describe("Iniciar conversão",error),0,job.total));else stopSelf(startId);}return START_NOT_STICKY;
 }
 private void foreground(Snapshot state){if(Build.VERSION.SDK_INT>=35)startForeground(NOTICE,notice(state),ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROCESSING);else if(Build.VERSION.SDK_INT>=29)startForeground(NOTICE,notice(state),ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC);else startForeground(NOTICE,notice(state));wake=((PowerManager)getSystemService(POWER_SERVICE)).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK,"Onda:ChapterExport");wake.acquire();}
 private Notification notice(Snapshot state){Intent open=state.screen(this).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP|Intent.FLAG_ACTIVITY_SINGLE_TOP);PendingIntent content=PendingIntent.getActivity(this,NOTICE,open,PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);Notification.Builder notice=new Notification.Builder(this,CHANNEL).setSmallIcon(android.R.drawable.stat_sys_download).setContentTitle("Onda • "+state.job.title).setContentText(state.message).setStyle(new Notification.BigTextStyle().bigText(state.message)).setContentIntent(content).setOnlyAlertOnce(true).setOngoing(state.running).setAutoCancel(!state.running);
  if(state.running){PendingIntent cancel=PendingIntent.getService(this,NOTICE,new Intent(this,ChapterExportService.class).setAction("cancel").putExtra("token",state.job.token),PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);notice.addAction(new Notification.Action.Builder(android.graphics.drawable.Icon.createWithResource(this,android.R.drawable.ic_menu_close_clear_cancel),"Cancelar",cancel).build());notice.setProgress(100,(int)Math.min(100,state.at*100/Math.max(1,state.total)),state.total<=0);}return notice.build();}
 private void publish(Snapshot state,boolean persist){current=state;if(persist)try{getSharedPreferences(PREF,0).edit().putString("last",new JSONObject().put("job",state.job.json()).put("phase",state.phase).put("message",state.message).put("at",state.at).put("total",state.total).put("batch",state.batch==null?JSONObject.NULL:state.batch.json()).toString()).apply();}catch(JSONException ignored){}for(Listener listener:listeners)try{listener.changed(state);}catch(RuntimeException ignored){}}
 private void notifyState(Snapshot state){try{((NotificationManager)getSystemService(NOTIFICATION_SERVICE)).notify(NOTICE,notice(state));}catch(RuntimeException ignored){}}
 private void check()throws IOException{if(cancelled||Thread.currentThread().isInterrupted())throw new InterruptedIOException("Conversão cancelada");}
 private void run(){processing=Thread.currentThread();Snapshot initial=job,result;AssetFileDescriptor target; synchronized(this){target=pending;pending=null;}
  try{check();converter.convert(this,initial.job,target,new ChapterExportTask.Control(){public void check()throws IOException{ChapterExportService.this.check();}public void progress(long at,long total){long now=SystemClock.elapsedRealtime();if(now-lastProgress<750&&at<total)return;lastProgress=now;Snapshot update=initial.with("running","Convertendo • "+initial.job.bitrate+" kbps. Continua com a tela apagada.",at,total);main.post(()->{if(finished||cancelled)return;publish(update,false);if(now-lastNotification>=PowerPolicy.progressInterval(OndaApplication.userVisible(ChapterExportService.this))){lastNotification=now;notifyState(update);}});}public void stage(String text){main.post(()->{if(!finished&&!cancelled){Snapshot state=current==null?initial:current;Snapshot update=state.with("running",text,state.at,state.total);publish(update,false);notifyState(update);}});}});result=initial.with("done","Faixa MP3 salva. O arquivo original foi preservado.",initial.total,initial.total);
  }catch(Exception|LinkageError error){boolean stopped=cancelled||error instanceof InterruptedIOException;result=initial.with(stopped?"cancelled":"error",stopped?"Conversão cancelada. O original foi preservado.":DownloadFailure.describe("Salvar faixa",error),0,initial.total);}
  finally{close(target);processing=null;Thread.interrupted();}Snapshot outcome=result;main.post(()->finish(outcome));
 }
 private Snapshot batchState(String phase,String text,long at,int index,int done,int failed,Uri folder){ChapterBatchPlan plan=batchPlan;return new Snapshot(plan.representative(),phase,text,at,plan.total,new BatchProgress(plan.token,plan.title,plan.rows.size(),index,done,failed,folder==null?null:folder.toString()));}
 private void runBatch(){
  processing=Thread.currentThread();ChapterBatchPlan plan=batchPlan;int done=0,failed=0,index=0;long elapsed=0;Uri folder=null;Snapshot outcome;
  try{
   check();ChapterBatchStore.save(this,plan);plan.validateSource(this);check();OndaFolders.configure(this,plan.tree);check();Uri audio=OndaFolders.directory(this,"mp3");
   String name=DownloadLinks.filename(plan.title)+" - "+new java.text.SimpleDateFormat("yyyyMMdd-HHmmss",java.util.Locale.ROOT).format(new java.util.Date())+" - "+plan.token.substring(0,6);
   folder=DocumentsContract.createDocument(getContentResolver(),audio,DocumentsContract.Document.MIME_TYPE_DIR,name);if(folder==null)throw new IOException("Não foi possível criar a pasta da seleção");
   for(ChapterBatchPlan.Row row:plan.rows){
    check();if(!plan.stamp.equals(AudioChapterStore.stamp(this,plan.source)))throw new IOException("O arquivo original mudou. Os MP3 concluídos foram mantidos.");
    final int position=++index,completed=done,errors=failed;final long base=elapsed;final Uri outputFolder=folder;String prefix=position+"/"+plan.rows.size()+" • ";
    main.post(()->{if(!finished&&!cancelled)publish(batchState("running",prefix+row.title,base,position,completed,errors,outputFolder),true);});
    Uri target=null;String failure=null;
    try{
     target=DocumentsContract.createDocument(getContentResolver(),folder,"audio/mpeg",plan.filename(row));if(target==null)throw new IOException("Não foi possível criar o MP3");check();
     AssetFileDescriptor descriptor=getContentResolver().openAssetFileDescriptor(target,"rw");if(descriptor==null)throw new IOException("Destino indisponível");
     try{converter.convert(this,plan.item(row,target),descriptor,new ChapterExportTask.Control(){public void check()throws IOException{ChapterExportService.this.check();}public void progress(long at,long total){long now=SystemClock.elapsedRealtime();if(now-lastProgress<750&&at<total)return;lastProgress=now;main.post(()->{if(finished||cancelled)return;Snapshot update=batchState("running",prefix+"Convertendo "+row.title,base+Math.max(0,Math.min(total,at)),position,completed,errors,outputFolder);publish(update,false);if(now-lastNotification>=PowerPolicy.progressInterval(OndaApplication.userVisible(ChapterExportService.this))){lastNotification=now;notifyState(update);}});}public void stage(String text){main.post(()->{if(finished||cancelled)return;Snapshot state=current==null?job:current;Snapshot update=state.with("running",prefix+text,state.at,state.total);publish(update,false);notifyState(update);});}});}finally{close(descriptor);}
     done++;DownloadedAudio.remember(this,target.toString(),row.title,"audio/mpeg");
    }catch(Exception|LinkageError error){ChapterBatchStore.discardEmpty(this,plan.source,target);if(cancelled||error instanceof InterruptedIOException)throw new InterruptedIOException("Conversão cancelada");failure=DownloadFailure.describe("Faixa "+(row.index+1),error);failed++;}
    ChapterBatchStore.append(this,plan.token,row,failure==null?target:null,failure);if(failure!=null)plan.validateSource(this);elapsed+=row.end-row.start;
    final Snapshot checkpoint=batchState("running",done+" salvas • "+failed+" falhas",elapsed,index,done,failed,folder);main.post(()->{if(!finished&&!cancelled)publish(checkpoint,true);});
   }
   outcome=batchState(failed==0?"done":"partial",done+" MP3 salvo(s) • "+failed+" falha(s). Originais preservados.",elapsed,index,done,failed,folder);
  }catch(Exception|LinkageError error){boolean stopped=cancelled||error instanceof InterruptedIOException;outcome=batchState(stopped?"cancelled":"error",(stopped?"Seleção cancelada.":DownloadFailure.describe("Salvar seleção",error))+" "+done+" MP3 concluído(s) mantido(s).",elapsed,index,done,failed,folder);}
  finally{processing=null;Thread.interrupted();}Snapshot result=outcome;main.post(()->finish(result));
 }
 private void requestCancel(){if(job==null||finished)return;cancelled=true;Thread thread=processing;if(thread!=null)thread.interrupt();Snapshot state=current==null?job:current;publish(state.with("cancelling","Cancelando conversão…",state.at,state.total),false);if(awaitingSource){awaitingSource=false;main.removeCallbacks(sourceTimeout);finish(state.with("cancelled","Seleção cancelada. Nenhum arquivo original foi alterado.",state.at,state.total));}}
 private void finish(Snapshot state){if(finished)return;main.removeCallbacks(sourceTimeout);finished=true;publish(state,true);releaseWake();stopForeground("cancelled".equals(state.phase)?STOP_FOREGROUND_REMOVE:STOP_FOREGROUND_DETACH);if(!"cancelled".equals(state.phase))notifyState(state);stopSelf();}
 private void releaseWake(){if(wake!=null){if(wake.isHeld())wake.release();wake=null;}}
 private static void close(AssetFileDescriptor fd){if(fd!=null)try{fd.close();}catch(IOException ignored){}}
 @Override public void onTimeout(int startId,int type){if(job!=null&&!finished){requestCancel();Snapshot state=current==null?job:current;finish(state.with("interrupted","O Android interrompeu a conversão. Os arquivos concluídos foram mantidos; confira o destino antes de tentar novamente.",state.at,state.total));}else stopSelf(startId);}
 @Override public void onDestroy(){cancelled=true;Thread thread=processing;if(thread!=null)thread.interrupt();worker.shutdownNow();synchronized(this){close(pending);pending=null;}releaseWake();if(job!=null&&!finished){finished=true;Snapshot state=current==null?job:current;publish(state.with("interrupted","Conversão interrompida. Os arquivos concluídos foram mantidos; confira o destino antes de tentar novamente.",state.at,state.total),true);}if(live==this)live=null;main.removeCallbacksAndMessages(null);super.onDestroy();}
}
