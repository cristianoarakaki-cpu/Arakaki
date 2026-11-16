package br.com.arakaki.codigolivre;
import android.content.Context;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.concurrent.*;
import okhttp3.*;
/** Instalação no serviço foreground. Usa a mesma fila do motor nativo. */
final class ModelInstaller {
 interface Progress {void update(String status,int percent);}
 private static volatile Call active;
 private static final OkHttpClient HTTP=new OkHttpClient.Builder().dns(WebSafety::resolve).followRedirects(false).followSslRedirects(false).connectTimeout(15,TimeUnit.SECONDS).readTimeout(45,TimeUnit.SECONDS).build();
 static void cancel(){Call c=active;if(c!=null)c.cancel();}
 private static Response get(String url,long offset)throws Exception{
  String address=url;
  for(int hop=0;hop<8;hop++){if(NativeEngine.cancelled())throw new CancellationException();WebSafety.url(address);Request.Builder request=new Request.Builder().url(address).header("Accept-Encoding","identity");if(offset>0)request.header("Range","bytes="+offset+"-");Call call=HTTP.newCall(request.build());active=call;if(NativeEngine.cancelled())call.cancel();Response response=call.execute();
   if(response.code()>=300&&response.code()<400){String target=response.header("Location");response.close();if(target==null)throw new IOException("Redirecionamento sem destino.");address=new java.net.URL(new java.net.URL(address),target).toString();continue;}return response;
  }throw new IOException("Redirecionamentos em excesso.");
 }
 static void run(Context context,Progress progress)throws Exception{
  File part=new File(context.getFilesDir(),"modelo.download"),meta=new File(context.getFilesDir(),"modelo.download.json");
  try{
   progress.update("Preparando IA: consultando modelo oficial…",-1);ModelPackage.Info info;
   try(Response response=get("https://huggingface.co/api/models/"+ModelPackage.REPO+"?blobs=true",0)){if(response.code()!=200||response.body()==null)throw new IOException("Não foi possível obter o modelo oficial (HTTP "+response.code()+"). Confira sua conexão e tente novamente.");try(InputStream in=response.body().byteStream()){info=ModelPackage.parse(new String(CodeFiles.read(in,2*1024*1024),StandardCharsets.UTF_8));}}
   String identity=info.revision+"\n"+info.hash+"\n"+info.size;String saved=meta.exists()?new String(Files.readAllBytes(meta.toPath()),StandardCharsets.UTF_8):"";
   if(!identity.equals(saved)||part.length()>info.size){Files.deleteIfExists(part.toPath());Files.write(meta.toPath(),identity.getBytes(StandardCharsets.UTF_8));}
   long offset=part.length();if(context.getFilesDir().getUsableSpace()<info.size-offset+256L*1024*1024)throw new IOException("Espaço insuficiente. Libere cerca de 1,5 GB para preparar a IA sem apagar o modelo atual.");
   if(offset<info.size){try(Response response=get(info.url(),offset)){
    if(response.body()==null||response.code()!=200&&response.code()!=206)throw new IOException("Download indisponível (HTTP "+response.code()+"). Toque Preparar IA para tentar novamente.");
    if(response.code()==206)ModelPackage.range(response.header("Content-Range"),offset,info.size);else if(offset>0){Files.deleteIfExists(part.toPath());offset=0;}
    final long[] last={0};try(InputStream in=response.body().byteStream()){ModelPackage.receive(in,part,offset,info.size,NativeEngine::cancelled,done->{long now=android.os.SystemClock.elapsedRealtime();if(now-last[0]>=500||done==info.size){last[0]=now;progress.update(String.format(java.util.Locale.ROOT,"Preparando IA: baixando %d/%d MB",done/1048576,info.size/1048576),(int)(done*100/info.size));}});}
   }}
   progress.update("Preparando IA: verificando integridade SHA256…",-1);
   try{ModelPackage.verify(part,info,NativeEngine::cancelled);}catch(IOException invalid){Files.deleteIfExists(part.toPath());Files.deleteIfExists(meta.toPath());throw invalid;}
   if(NativeEngine.cancelled())throw new CancellationException();progress.update("Preparando IA: carregando o modelo no aparelho…",-1);
   try{NativeEngine.load(part.getAbsolutePath().getBytes(StandardCharsets.UTF_8));if(NativeEngine.cancelled())throw new CancellationException();Files.move(part.toPath(),new File(context.getFilesDir(),"modelo.gguf").toPath(),StandardCopyOption.REPLACE_EXISTING,StandardCopyOption.ATOMIC_MOVE);}catch(Exception failure){NativeEngine.unload();throw failure;}
   context.getSharedPreferences("modelo",Context.MODE_PRIVATE).edit().putString("nome",ModelPackage.FILE).apply();Files.deleteIfExists(meta.toPath());
  }finally{active=null;}
 }
}
