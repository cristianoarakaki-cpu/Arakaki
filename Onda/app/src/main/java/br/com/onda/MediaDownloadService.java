package br.com.onda;

import android.app.*;
import android.content.*;
import android.net.Uri;
import android.os.*;
import android.provider.DocumentsContract;
import org.json.*;
import java.io.*;
import java.net.*;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.concurrent.*;

/** Explicit sequential downloads, never an automatic scheduler. */
@androidx.media3.common.util.UnstableApi
public class MediaDownloadService extends Service {
 private static final String CHANNEL="onda-download";private static final long LIMIT=512L*1024*1024;
 private final ExecutorService worker=Executors.newSingleThreadExecutor();private volatile boolean cancelled;private volatile HttpURLConnection active;private volatile Thread processing;private volatile boolean running;static volatile boolean activeDownload;private long total,lastNotice,startedAt,itemStarted;private String prefix="",stage="Preparação";private PowerManager.WakeLock wake;private final StringBuilder report=new StringBuilder();
 @Override public IBinder onBind(Intent intent){return null;}
 @Override public int onStartCommand(Intent intent,int flags,int startId){
  if(intent==null){stopSelf();return START_NOT_STICKY;}if("cancel".equals(intent.getAction())){cancel();return START_NOT_STICKY;}if(running)return START_NOT_STICKY;
  running=true;activeDownload=true;cancelled=false;total=0;lastNotice=0;startedAt=SystemClock.elapsedRealtime();itemStarted=startedAt;report.setLength(0);getSharedPreferences("downloads",0).edit().remove("last_error").apply();
  ((NotificationManager)getSystemService(NOTIFICATION_SERVICE)).createNotificationChannel(new NotificationChannel(CHANNEL,"Downloads do Onda",NotificationManager.IMPORTANCE_LOW));startForeground(901,notice("Iniciando download…"));
  wake=((PowerManager)getSystemService(POWER_SERVICE)).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK,"Onda:Download");wake.acquire(2*60*60*1000L);update("Preparando download…",true);
  worker.execute(()->run(intent));return START_NOT_STICKY;
 }
 private Notification notice(String text){PendingIntent content=PendingIntent.getActivity(this,0,new Intent(this,DownloadsActivity.class),PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);PendingIntent cancel=PendingIntent.getService(this,1,new Intent(this,MediaDownloadService.class).setAction("cancel"),PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);return new Notification.Builder(this,CHANNEL).setSmallIcon(android.R.drawable.stat_sys_download).setContentTitle("Onda • downloads").setContentText(text).setContentIntent(content).setOngoing(true).setOnlyAlertOnce(true).addAction(new Notification.Action.Builder(android.graphics.drawable.Icon.createWithResource(this,android.R.drawable.ic_menu_close_clear_cancel),"Cancelar",cancel).build()).build();}
 private void update(String message,boolean busy){getSharedPreferences("downloads",0).edit().putString("status",message).putBoolean("busy",busy).apply();if(busy&&!cancelled&&(Build.VERSION.SDK_INT<33||checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS)==android.content.pm.PackageManager.PERMISSION_GRANTED))((NotificationManager)getSystemService(NOTIFICATION_SERVICE)).notify(901,notice(message));}
 private void check()throws IOException{if(cancelled||Thread.currentThread().isInterrupted())throw new InterruptedIOException("Cancelado");long now=SystemClock.elapsedRealtime();if(now-startedAt>2*60*60*1000L)throw new InterruptedIOException("Tempo total de 2 horas atingido");if(now-itemStarted>30*60*1000L)throw new IOException("Tempo limite de 30 minutos por arquivo");}
 private void fetch(String link,File target)throws IOException{
  stage="Download";check();long remaining=LIMIT-total;
  ResilientDownload.fetch(link,target,remaining,ExtractorHttp.AGENT,new ResilientDownload.Control(){
   public void check()throws IOException{MediaDownloadService.this.check();}
   public void opened(HttpURLConnection c){active=c;}
   public void closed(HttpURLConnection c){if(active==c)active=null;}
   public void bytes(int count,long stored,long expected)throws IOException{total+=count;check();if(total>LIMIT||getCacheDir().getUsableSpace()<32L*1024*1024)throw new IOException("Limite de transferência ou espaço livre atingido");if(SystemClock.elapsedRealtime()-lastNotice>1000){lastNotice=SystemClock.elapsedRealtime();update(prefix+"Transferidos "+total/(1024*1024)+" MB",true);}}
   public void retry(int number,long stored)throws IOException{check();update(prefix+"Conexão interrompida • reconectando ("+number+"/2), "+stored/(1024*1024)+" MB preservados…",true);}
  });
 }
 private void transfer(String first,String second,String format,Uri destination,String title)throws Exception{
  File a=null,b=null,result=null;boolean complete=false;total=0;lastNotice=0;itemStarted=SystemClock.elapsedRealtime();
  try{a=File.createTempFile("onda-download-",".part",getCacheDir());result=File.createTempFile("onda-download-",".out",getCacheDir());fetch(first,a);if(second!=null&&!second.isEmpty()){b=File.createTempFile("onda-download-",".part",getCacheDir());fetch(second,b);}
   if("mp3".equals(format)){stage="Conversão para MP3";update(prefix+"Convertendo para MP3 • 192 kbps…",true);try{Mp3Converter.convert(a,result,192,this::check);}catch(LinkageError e){throw new IOException("O conversor MP3 não pôde ser carregado neste aparelho",e);}}else{stage="Montagem de "+format.toUpperCase(Locale.ROOT);update(prefix+"Montando "+format.toUpperCase(Locale.ROOT)+"…",true);DownloadMux.merge(a,b,result,"m4a".equals(format),this::check);}check();stage="Gravação do arquivo";update(prefix+"Salvando…",true);
   try(InputStream in=new FileInputStream(result);OutputStream out=getContentResolver().openOutputStream(destination,"wt")){if(out==null)throw new IOException("Destino indisponível");byte[] bytes=new byte[65536];int n;while((n=in.read(bytes))!=-1){check();out.write(bytes,0,n);}}check();complete=true;
   getSharedPreferences("downloads",0).edit().putString("last_uri",destination.toString()).putString("last_title",title).putString("last_mime",mime(format)).apply();
  }finally{for(File f:new File[]{a,b,result})if(f!=null)f.delete();if(!complete)try{DocumentsContract.deleteDocument(getContentResolver(),destination);}catch(Exception ignored){}}
 }
 static String mime(String format){return "mp3".equals(format)?"audio/mpeg":"m4a".equals(format)?"audio/mp4":"video/mp4";}
 private void run(Intent intent){
  processing=Thread.currentThread();try{check();File[] stale=getCacheDir().listFiles((dir,name)->name.startsWith("onda-download-"));if(stale!=null)for(File f:stale)f.delete();String format=intent.getStringExtra("format");if(format==null)format=intent.getBooleanExtra("audio",false)?"m4a":"mp4";if(!Arrays.asList("mp3","m4a","mp4").contains(format))throw new IOException("Formato inválido");final String selected=format;
   String queue=intent.getStringExtra("queue");if(queue==null){prefix="";transfer(intent.getStringExtra("first"),intent.getStringExtra("second"),selected,Uri.parse(intent.getStringExtra("destination")),intent.getStringExtra("title"));update("Download concluído. Arquivo salvo no local escolhido.",false);}
   else{
    stage="Criação da pasta";JSONArray entries=DownloadQueue.validate(queue);Uri tree=Uri.parse(intent.getStringExtra("tree"));Uri parent=DocumentsContract.buildDocumentUriUsingTree(tree,DocumentsContract.getTreeDocumentId(tree));String name=DownloadLinks.filename(intent.getStringExtra("title"))+" - "+new SimpleDateFormat("yyyyMMdd-HHmmss",Locale.ROOT).format(new Date());Uri folder=DocumentsContract.createDocument(getContentResolver(),parent,DocumentsContract.Document.MIME_TYPE_DIR,name);if(folder==null)throw new IOException("Não foi possível criar a pasta da playlist");
    BatchDownloads.Summary summary=BatchDownloads.run(entries.length(),index->{JSONObject entry=entries.getJSONObject(index);prefix=(index+1)+"/"+entries.length()+" • ";itemStarted=SystemClock.elapsedRealtime();stage="Análise do vídeo";update(prefix+"Analisando "+entry.getString("title")+"…",true);
     try{YoutubeDownloads.Option option=YoutubeDownloads.choose(YoutubeDownloads.inspect(entry.getString("url")),selected);check();stage="Criação do arquivo";Uri file=DocumentsContract.createDocument(getContentResolver(),folder,mime(selected),String.format(Locale.ROOT,"%03d - ",index+1)+DownloadLinks.filename(entry.getString("title"))+"."+selected);if(file==null)throw new IOException("Destino indisponível");transfer(option.first,option.second,selected,file,entry.getString("title"));report.append(index+1).append(". OK • ").append(entry.getString("title")).append('\n');}
     catch(Exception e){report.append(index+1).append(". Falhou • ").append(entry.getString("title")).append(" • ").append(DownloadFailure.describe(stage,e)).append('\n');throw e;}
    },(index,ok)->getSharedPreferences("downloads",0).edit().putString("report",report.toString()).apply(),this::check);
    update("Playlist: "+summary.text(entries.length())+(summary.stopped?". Fila interrompida após 3 falhas seguidas.":"."),false);
   }
  }catch(Exception e){String message=cancelled?"Download cancelado. Os arquivos concluídos foram mantidos.":"Operação interrompida • "+DownloadFailure.describe(stage,e);if(!cancelled){getSharedPreferences("downloads",0).edit().putString("last_error",message).apply();if(report.length()==0)report.append(message).append('\n');}update(message,false);}finally{getSharedPreferences("downloads",0).edit().putString("report",report.toString()).apply();processing=null;running=false;activeDownload=false;releaseWake();stopForeground(STOP_FOREGROUND_REMOVE);stopSelf();}
 }
 private synchronized void releaseWake(){if(wake!=null){if(wake.isHeld())wake.release();wake=null;}}
 private void cancel(){cancelled=true;HttpURLConnection c=active;if(c!=null)c.disconnect();Thread job=processing;if(job!=null)job.interrupt();if(running)update("Cancelando… Os arquivos concluídos serão mantidos.",true);else stopSelf();}
 @Override public void onTimeout(int startId,int fgsType){cancel();stopSelf();}
 @Override public void onDestroy(){cancelled=true;HttpURLConnection c=active;if(c!=null)c.disconnect();activeDownload=false;worker.shutdownNow();releaseWake();if(running)update("Download interrompido. Os arquivos concluídos foram mantidos.",false);super.onDestroy();}
}
