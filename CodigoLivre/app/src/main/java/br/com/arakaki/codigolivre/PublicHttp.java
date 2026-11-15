package br.com.arakaki.codigolivre;
import java.io.*;
import java.net.*;
import java.util.concurrent.TimeUnit;
import okhttp3.*;
/** O cliente conecta somente aos IPs públicos retornados pelo resolvedor validado. */
final class PublicHttp {
    private static final OkHttpClient CLIENT=new OkHttpClient.Builder().dns(WebSafety::resolve).followRedirects(false).followSslRedirects(false).connectTimeout(10,TimeUnit.SECONDS).readTimeout(12,TimeUnit.SECONDS).callTimeout(8,TimeUnit.SECONDS).build();
    static byte[] get(String initial)throws IOException {
        String address=initial;long deadline=System.nanoTime()+TimeUnit.SECONDS.toNanos(8);
        for(int hop=0;hop<4;hop++){
            WebSafety.url(address);Request request=new Request.Builder().url(address).header("User-Agent","CodigoLivre-Android/0.8 public-page-reader").get().build();
            long remaining=deadline-System.nanoTime();if(remaining<=0)throw new java.net.SocketTimeoutException("Tempo da leitura esgotado.");Call call=CLIENT.newCall(request);call.timeout().timeout(remaining,TimeUnit.NANOSECONDS);
            try(Response response=call.execute()){
                int code=response.code();if(code>=300&&code<400){String target=response.header("Location");if(target==null)throw new IOException("Redirecionamento inválido.");address=new URL(new URL(address),target).toString();continue;}
                if(code!=200)throw new IOException("Página respondeu HTTP "+code+"; não houve tentativa de contornar o bloqueio.");
                if(response.body()==null)throw new IOException("Resposta sem conteúdo.");try(InputStream in=response.body().byteStream()){return CodeFiles.read(in,4*1024*1024);}
            }
        }throw new IOException("Redirecionamentos em excesso.");
    }
}
