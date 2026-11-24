package br.com.onda;

import android.app.*;
import android.content.*;
import android.content.pm.ServiceInfo;
import android.net.Uri;
import android.os.*;
import java.io.*;
import java.util.Set;
import java.util.concurrent.*;
import org.json.JSONObject;

/** One explicit local scan; independent of Activity lifecycle, never automatically restarted. */
@androidx.media3.common.util.UnstableApi
public class ChapterScanService extends Service {
    private static final String CHANNEL="onda-chapters",PREF="chapter-scan";
    static final int NOTICE=906;
    private static final String CANCEL="cancel";
    interface Listener {void changed(Snapshot state);}
    interface Scanner {AudioChapterScanner.Result scan(Context context,Uri uri,AudioChapterScanner.Control control)throws IOException;}
    // Instrumentation can gate the real decoder to exercise lifecycle races deterministically.
    static volatile Scanner scanner=AudioChapterScanner::scan;
    private static final Set<Listener> listeners=new CopyOnWriteArraySet<>();
    private static volatile Snapshot current;
    private static volatile ChapterScanService live;
    static final class Snapshot {
        final String token,ownerId,title,phase,message;final Uri uri;final long at,total;final boolean running;
        Snapshot(String token,Uri uri,String ownerId,String title,String phase,String message,long at,long total){this.token=token;this.uri=uri;this.ownerId=ownerId;this.title=title;this.phase=phase;this.message=message;this.at=at;this.total=total;running="running".equals(phase)||"cancelling".equals(phase);}
        Snapshot with(String phase,String message,long at,long total){return new Snapshot(token,uri,ownerId,title,phase,message,at,total);}
    }
    static Snapshot state(Context context){
        Snapshot snapshot=current;if(snapshot!=null)return snapshot;
        try{String text=context.getSharedPreferences(PREF,0).getString("last","");if(text.isEmpty())return null;JSONObject j=new JSONObject(text);String phase=j.getString("phase"),message=j.getString("message");
            if("running".equals(phase)||"cancelling".equals(phase)){phase="interrupted";message="A análise foi interrompida pelo Android. As divisões anteriores foram mantidas; toque em analisar para tentar novamente.";}
            snapshot=new Snapshot(j.getString("token"),Uri.parse(j.getString("uri")),j.getString("owner"),j.getString("title"),phase,message,j.optLong("at"),j.optLong("total"));current=snapshot;
        }catch(Exception ignored){}return snapshot;
    }
    static void listen(Listener listener){listeners.add(listener);}
    static void unlisten(Listener listener){listeners.remove(listener);}
    static boolean start(Context context,Uri source,String owner,String title,long duration){
        ChapterScanService service=live;if(service!=null&&service.finished)return false;
        Intent intent=new Intent(context,ChapterScanService.class).putExtra("source",source.toString()).putExtra("owner",owner).putExtra("title",title).putExtra("duration",duration);
        if("content".equals(source.getScheme())){intent.setClipData(ClipData.newRawUri("Coletânea",source));intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);}
        androidx.core.content.ContextCompat.startForegroundService(context,intent);return true;
    }
    static void cancel(Context context,Snapshot state){if(state!=null&&state.running)context.startService(new Intent(context,ChapterScanService.class).setAction(CANCEL).putExtra("token",state.token));}
    private final Handler main=new Handler(Looper.getMainLooper());
    private final ExecutorService worker=Executors.newSingleThreadExecutor();
    private volatile boolean cancelled,finished;private volatile Thread processing;private Snapshot job;
    private PowerManager.WakeLock wake;private long lastNotice;
    @Override public IBinder onBind(Intent intent){return null;}
    @Override public void onCreate(){super.onCreate();live=this;((NotificationManager)getSystemService(NOTIFICATION_SERVICE)).createNotificationChannel(new NotificationChannel(CHANNEL,"Análise de coletâneas",NotificationManager.IMPORTANCE_LOW));}
    @Override public int onStartCommand(Intent intent,int flags,int startId){
        if(intent==null){if(job==null)stopSelf(startId);return START_NOT_STICKY;}
        if(CANCEL.equals(intent.getAction())){if(job!=null&&job.token.equals(intent.getStringExtra("token")))requestCancel("Cancelando análise…");else if(job==null)stopSelf(startId);return START_NOT_STICKY;}
        if(job!=null)return START_NOT_STICKY;
        String source=intent.getStringExtra("source");Uri uri=source==null?null:Uri.parse(source);if(uri==null||!("file".equals(uri.getScheme())||"content".equals(uri.getScheme()))){stopSelf(startId);return START_NOT_STICKY;}
        String title=intent.getStringExtra("title");if(title==null||title.trim().isEmpty())title="Coletânea";
        job=new Snapshot(java.util.UUID.randomUUID().toString(),uri,intent.getStringExtra("owner"),title,"running","Analisando coletânea. Pode minimizar ou apagar a tela.",0,Math.max(0,intent.getLongExtra("duration",0)));
        try{
            Notification notice=notice(job);
            if(Build.VERSION.SDK_INT>=35)startForeground(NOTICE,notice,ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROCESSING);
            else if(Build.VERSION.SDK_INT>=29)startForeground(NOTICE,notice,ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC);
            else startForeground(NOTICE,notice);
            wake=((PowerManager)getSystemService(POWER_SERVICE)).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK,"Onda:ChapterScan");wake.acquire();
            publish(job,true);worker.execute(this::scan);
        }catch(RuntimeException error){finish(job.with("error","Não foi possível iniciar a análise em segundo plano. Tente novamente com o Onda aberto.",0,job.total));}
        return START_NOT_STICKY;
    }
    private Notification notice(Snapshot state){
        Intent open=new Intent(this,AudioChaptersActivity.class).setAction("chapter_scan_result").putExtra("scan_title",state.title).putExtra("scan_uri",state.uri.toString()).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP|Intent.FLAG_ACTIVITY_SINGLE_TOP);
        PendingIntent content=PendingIntent.getActivity(this,NOTICE,open,PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
        Notification.Builder notice=new Notification.Builder(this,CHANNEL).setSmallIcon(android.R.drawable.stat_sys_download).setContentTitle("Onda • "+state.title).setContentText(state.message).setStyle(new Notification.BigTextStyle().bigText(state.message)).setContentIntent(content).setOnlyAlertOnce(true).setOngoing(state.running).setAutoCancel(!state.running);
        if(state.running){PendingIntent cancel=PendingIntent.getService(this,NOTICE,new Intent(this,ChapterScanService.class).setAction(CANCEL).putExtra("token",state.token),PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);notice.addAction(new Notification.Action.Builder(android.graphics.drawable.Icon.createWithResource(this,android.R.drawable.ic_menu_close_clear_cancel),"Cancelar",cancel).build());notice.setProgress(100,state.total>0?(int)Math.min(100,state.at*100/state.total):0,state.total<=0);}
        return notice.build();
    }
    private void publish(Snapshot state,boolean persist){
        current=state;
        if(persist)try{JSONObject j=new JSONObject().put("token",state.token).put("uri",state.uri.toString()).put("owner",state.ownerId==null?"":state.ownerId).put("title",state.title).put("phase",state.phase).put("message",state.message).put("at",state.at).put("total",state.total);getSharedPreferences(PREF,0).edit().putString("last",j.toString()).apply();}catch(Exception ignored){}
        for(Listener listener:listeners)try{listener.changed(state);}catch(RuntimeException ignored){/* UI observer cannot stop the independent scan. */}
    }
    private void check()throws IOException{if(cancelled||Thread.currentThread().isInterrupted())throw new InterruptedIOException("Análise cancelada");}
    private void scan(){
        processing=Thread.currentThread();Snapshot initial=job,result;
        try{
            check();String stamp=AudioChapterStore.stamp(this,initial.uri);
            AudioChapterScanner.Control control=new AudioChapterScanner.Control(){public void check()throws IOException{ChapterScanService.this.check();}public void progress(long at,long total){long now=SystemClock.elapsedRealtime();if(now-lastNotice<750)return;lastNotice=now;
                Snapshot update=initial.with("running","Analisando "+AudioChaptersActivity.time(at)+(total>0?" de "+AudioChaptersActivity.time(total):"")+". Continua com a tela apagada.",at,total);
                main.post(()->{if(finished||cancelled||job==null)return;publish(update,false);long cadence=PowerPolicy.progressInterval(OndaApplication.userVisible(ChapterScanService.this));if(now-lastNotification>=cadence){lastNotification=now;notifyState(update);}});
            }};
            AudioChapterStore.Data data=AudioChapterStore.detected(scanner.scan(this,initial.uri,control));check();AudioChapterStore.save(this,initial.uri,stamp,data);
            result=initial.with("done",data.chapters.size()+" faixa(s) salva(s). Confira as divisões no Onda.",data.duration,data.duration);
        }catch(Exception|LinkageError error){boolean stopped=cancelled||error instanceof InterruptedIOException;result=initial.with(stopped?"cancelled":"error",stopped?"Análise cancelada. As divisões anteriores foram mantidas.":DownloadFailure.describe("Análise da coletânea",error)+" As divisões anteriores foram mantidas.",0,initial.total);}
        finally{processing=null;Thread.interrupted();}
        Snapshot outcome=result;main.post(()->finish(outcome));
    }
    private long lastNotification;
    private void notifyState(Snapshot state){try{((NotificationManager)getSystemService(NOTIFICATION_SERVICE)).notify(NOTICE,notice(state));}catch(RuntimeException ignored){}}
    private void requestCancel(String message){if(job==null||finished)return;cancelled=true;Thread thread=processing;if(thread!=null)thread.interrupt();publish(job.with("cancelling",message,0,job.total),false);}
    private void finish(Snapshot state){if(finished)return;finished=true;publish(state,true);releaseWake();stopForeground(STOP_FOREGROUND_REMOVE);if(!"cancelled".equals(state.phase))notifyState(state);stopSelf();}
    private void releaseWake(){if(wake!=null){if(wake.isHeld())wake.release();wake=null;}}
    @Override public void onTimeout(int startId,int type){if(job!=null&&!finished){requestCancel("O Android interrompeu a análise.");finish(job.with("interrupted","O Android interrompeu a análise. As divisões anteriores foram mantidas. Abra o Onda para tentar novamente.",0,job.total));}else stopSelf(startId);}
    @Override public void onDestroy(){cancelled=true;Thread thread=processing;if(thread!=null)thread.interrupt();worker.shutdownNow();releaseWake();if(job!=null&&!finished){finished=true;publish(job.with("interrupted","Análise interrompida. As divisões anteriores foram mantidas; toque em analisar para tentar novamente.",0,job.total),true);}if(live==this)live=null;main.removeCallbacksAndMessages(null);super.onDestroy();}
}
