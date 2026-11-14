package br.com.onda;
import android.content.Context;
import android.net.ConnectivityManager;
import android.net.NetworkCapabilities;
import java.io.*;import java.net.*;import java.security.MessageDigest;
import java.util.function.BooleanSupplier;
/** Optional, immutable model downloads; audio is never uploaded. */
final class LiveSpeechModels {
 static final String REV="5359861c739e955e79d9a303bcbc70fb988958b1";
 enum Model {
  BASE("Equilibrado • 60 MB","ggml-base-q5_1.bin",59707625,"422f1ae452ade6f30a004d7e5c6a43195e4433bc370bf23fac9cc591f01a8898"),
  SMALL("Precisão • 190 MB • mais processamento","ggml-small-q5_1.bin",190085487,"ae85e4a935d7a567bd102fe55afc16bb595bdb618e11b2fc7591bc08120411bb");
  final String label,file,sha;final long bytes;Model(String l,String f,long b,String s){label=l;file=f;bytes=b;sha=s;}
 }
 interface Progress {void changed(long bytes,long total);}
 static File path(Context c,Model m){return new File(new File(c.getFilesDir(),"live-models"),m.file);}
 static boolean installed(Context c,Model m){File f=path(c,m);return f.isFile()&&f.length()==m.bytes;}
 static File obtain(Context c,Model m,boolean wifi,BooleanSupplier cancelled,Progress progress)throws Exception{
  File file=path(c,m);File folder=file.getParentFile();if(!folder.isDirectory()&&!folder.mkdirs())throw new IOException("Não foi possível salvar o modelo.");
  if(installed(c,m)&&hash(file,cancelled).equals(m.sha))return file;
  if(wifi){ConnectivityManager cm=(ConnectivityManager)c.getSystemService(Context.CONNECTIVITY_SERVICE);NetworkCapabilities caps=cm==null?null:cm.getNetworkCapabilities(cm.getActiveNetwork());if(caps==null||!caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI))throw new IOException("Conecte ao Wi-Fi ou escolha Dados móveis para baixar o modelo.");}
  if(folder.getUsableSpace()<m.bytes+32L*1024*1024)throw new IOException("Libere espaço para o modelo de reconhecimento.");
  File partial=new File(folder,m.file+".part");boolean done=false;HttpURLConnection connection=(HttpURLConnection)new URL("https://huggingface.co/ggerganov/whisper.cpp/resolve/"+REV+"/"+m.file).openConnection();connection.setConnectTimeout(15000);connection.setReadTimeout(15000);
  try{if(connection.getResponseCode()!=200)throw new IOException("Não foi possível baixar o modelo agora.");MessageDigest digest=MessageDigest.getInstance("SHA-256");long bytes=0,last=0;
   try(InputStream in=connection.getInputStream();OutputStream out=new FileOutputStream(partial)){byte[] block=new byte[32768];int n;while((n=in.read(block))!=-1){check(cancelled);bytes+=n;if(bytes>m.bytes)throw new IOException("Tamanho de modelo inválido");out.write(block,0,n);digest.update(block,0,n);long now=System.nanoTime();if(now-last>300000000){last=now;progress.changed(bytes,m.bytes);}}}
   if(bytes!=m.bytes||!hex(digest.digest()).equals(m.sha))throw new IOException("Modelo incompleto ou alterado. Tente novamente.");check(cancelled);if(file.exists()&&!file.delete())throw new IOException("Não foi possível substituir o modelo.");if(!partial.renameTo(file))throw new IOException("Não foi possível salvar o modelo.");done=true;return file;
  }finally{connection.disconnect();if(!done)partial.delete();}
 }
 private static String hash(File f,BooleanSupplier cancelled)throws Exception{MessageDigest d=MessageDigest.getInstance("SHA-256");try(InputStream in=new FileInputStream(f)){byte[] b=new byte[32768];int n;while((n=in.read(b))!=-1){check(cancelled);d.update(b,0,n);}}return hex(d.digest());}
 private static void check(BooleanSupplier cancelled)throws InterruptedIOException{if(cancelled.getAsBoolean()||Thread.currentThread().isInterrupted())throw new InterruptedIOException("Preparação cancelada");}
 private static String hex(byte[] value){StringBuilder b=new StringBuilder();for(byte v:value)b.append(String.format(java.util.Locale.ROOT,"%02x",v&255));return b.toString();}
}
