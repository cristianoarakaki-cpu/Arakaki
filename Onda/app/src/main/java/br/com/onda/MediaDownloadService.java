package br.com.onda;

import android.app.*;
import android.content.*;
import android.net.Uri;
import android.os.*;
import android.provider.DocumentsContract;
import java.io.*;
import java.net.*;
import java.util.concurrent.*;

/** One explicit download at a time; no scheduler, retries or idle background loop. */
public class MediaDownloadService extends Service {
 private static final String CHANNEL="onda-download";private static final long LIMIT=512L*1024*1024;
 private final ExecutorService worker=Executors.newSingleThreadExecutor();private volatile boolean cancelled;private volatile HttpURLConnection active;private boolean running;static volatile boolean activeDownload;private long total,lastNotice,startedAt;
 @Override public IBinder onBind(Intent intent){return null;}
 @Override public int onStartCommand(Intent intent,int flags,int startId){
  if(intent==null){stopSelf();return START_NOT_STICKY;}
  if("cancel".equals(intent.getAction())){cancel();return START_NOT_STICKY;}
  if(running)return START_NOT_STICKY;
  running=true;activeDownload=true;cancelled=false;startedAt=System.currentTimeMillis();
  ((NotificationManager)getSystemService(NOTIFICATION_SERVICE)).createNotificationChannel(new NotificationChannel(CHANNEL,"Downloads do Onda",NotificationManager.IMPORTANCE_LOW));
  startForeground(901,notice("Iniciando download…"));update("Baixando…",true);
  worker.execute(()->download(intent));return START_NOT_STICKY;
 }
 private Notification notice(String text){Intent open=new Intent(this,DownloadsActivity.class);PendingIntent content=PendingIntent.getActivity(this,0,open,PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);PendingIntent cancel=PendingIntent.getService(this,1,new Intent(this,MediaDownloadService.class).setAction("cancel"),PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);return new Notification.Builder(this,CHANNEL).setSmallIcon(android.R.drawable.stat_sys_download).setContentTitle("Onda Lab • download").setContentText(text).setContentIntent(content).setOngoing(true).setOnlyAlertOnce(true).addAction(new Notification.Action.Builder(android.graphics.drawable.Icon.createWithResource(this,android.R.drawable.ic_menu_close_clear_cancel),"Cancelar",cancel).build()).build();}
 private void update(String message,boolean busy){getSharedPreferences("downloads",0).edit().putString("status",message).putBoolean("busy",busy).apply();if(busy&&!cancelled&&(Build.VERSION.SDK_INT<33||checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS)==android.content.pm.PackageManager.PERMISSION_GRANTED))((NotificationManager)getSystemService(NOTIFICATION_SERVICE)).notify(901,notice(message));}
 private void check()throws IOException{if(cancelled||Thread.currentThread().isInterrupted())throw new InterruptedIOException("Cancelado");if(System.currentTimeMillis()-startedAt>30*60*1000L)throw new IOException("Tempo limite de 30 minutos");}
 private void fetch(String link,File target)throws IOException {
  check();URL url=new URL(link);if(!"https".equalsIgnoreCase(url.getProtocol()))throw new IOException("Link inválido");HttpURLConnection c=(HttpURLConnection)url.openConnection();active=c;
  try{
   c.setConnectTimeout(15000);c.setReadTimeout(20000);c.setRequestProperty("User-Agent",ExtractorHttp.AGENT);int code=c.getResponseCode();if(code!=200)throw new IOException("Servidor recusou o download (HTTP "+code+"). Analise o link novamente.");
   long expected=c.getContentLengthLong(),copied=0;if(expected>LIMIT-total)throw new IOException("Limite de 512 MB por operação");
   try(InputStream in=c.getInputStream();OutputStream out=new FileOutputStream(target)){byte[] b=new byte[65536];int n;while((n=in.read(b))!=-1){check();total+=n;copied+=n;if(total>LIMIT||getCacheDir().getUsableSpace()<32L*1024*1024)throw new IOException("Limite de tamanho ou espaço livre atingido");out.write(b,0,n);if(System.currentTimeMillis()-lastNotice>1000){lastNotice=System.currentTimeMillis();update("Baixados "+(total/(1024*1024))+" MB • limite 512 MB",true);}}}
   if(copied==0||(expected>=0&&copied!=expected))throw new IOException("Download incompleto. Tente novamente.");
  }finally{active=null;c.disconnect();}
 }
 private void download(Intent intent){File a=null,b=null,result=null;Uri destination=Uri.parse(intent.getStringExtra("destination"));boolean complete=false;
  try{
   a=File.createTempFile("onda-download-",".part",getCacheDir());b=File.createTempFile("onda-download-",".part",getCacheDir());result=File.createTempFile("onda-download-",".mp4",getCacheDir());
   fetch(intent.getStringExtra("first"),a);String second=intent.getStringExtra("second");if(second!=null&&!second.isEmpty())fetch(second,b);
   update("Montando arquivo sem recomprimir…",true);DownloadMux.merge(a,second==null?null:b,result,intent.getBooleanExtra("audio",false),this::check);check();update("Salvando no destino escolhido…",true);
   try(InputStream in=new FileInputStream(result);OutputStream out=getContentResolver().openOutputStream(destination,"wt")){if(out==null)throw new IOException("Destino indisponível");byte[] bytes=new byte[65536];int n;while((n=in.read(bytes))!=-1){check();out.write(bytes,0,n);}}
   check();complete=true;getSharedPreferences("downloads",0).edit().putString("last_uri",destination.toString()).putString("last_mime",intent.getBooleanExtra("audio",false)?"audio/mp4":"video/mp4").apply();update("Download concluído. Arquivo salvo no local escolhido.",false);
  }catch(Exception e){update(cancelled?"Download cancelado.":"Falha no download: "+(e.getMessage()==null?"formato indisponível":e.getMessage()),false);}finally{
   for(File f:new File[]{a,b,result})if(f!=null)f.delete();if(!complete)try{DocumentsContract.deleteDocument(getContentResolver(),destination);}catch(Exception ignored){}
   running=false;activeDownload=false;stopForeground(STOP_FOREGROUND_REMOVE);stopSelf();
  }
 }
 private void cancel(){cancelled=true;HttpURLConnection c=active;if(c!=null)c.disconnect();}
 @Override public void onTimeout(int startId,int fgsType){cancel();stopSelf();}
 @Override public void onDestroy(){cancel();activeDownload=false;worker.shutdownNow();if(running)update("Download interrompido. Você pode tentar novamente.",false);super.onDestroy();}
}
