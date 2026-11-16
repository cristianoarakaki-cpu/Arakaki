package br.com.arakaki.codigolivre;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.concurrent.*;
import okhttp3.*;
final class CloudClient implements CloudRouter.Client {
 private final OkHttpClient client=new OkHttpClient.Builder().dns(WebSafety::resolve).followRedirects(false).followSslRedirects(false).connectTimeout(10,TimeUnit.SECONDS).readTimeout(25,TimeUnit.SECONDS).callTimeout(30,TimeUnit.SECONDS).build();
 private volatile Call active;
 private final java.util.function.BooleanSupplier cancelled;
 CloudClient(){this(()->false);}
 CloudClient(java.util.function.BooleanSupplier cancelled){this.cancelled=cancelled;}
 void cancel(){Call c=active;if(c!=null)c.cancel();}
 private String request(CloudProtocol.Provider p,String key,String url,String body)throws Exception{
  CloudProtocol.key(key);String expected=java.net.URI.create(p.modelsUrl).getHost();java.net.URI uri=java.net.URI.create(url);
  if(!"https".equals(uri.getScheme())||!expected.equals(uri.getHost())||uri.getUserInfo()!=null||uri.getQuery()!=null)throw new IllegalArgumentException("Destino da chave não autorizado.");
  Request.Builder b=new Request.Builder().url(url);if(p==CloudProtocol.Provider.GEMINI)b.header("x-goog-api-key",key);else b.header("Authorization","Bearer "+key);
  if(body==null)b.get();else b.post(RequestBody.create(body,MediaType.get("application/json; charset=utf-8")));
  Call call=client.newCall(b.build());active=call;if(cancelled.getAsBoolean())call.cancel();
  try(Response response=call.execute()){
   if(response.code()!=200)throw new CloudRouter.Failure(response.code(),CloudProtocol.retryMillis(response.header("Retry-After"),System.currentTimeMillis()));
   if(response.body()==null)throw new IOException("Resposta vazia do provedor.");try(InputStream in=response.body().byteStream()){return new String(CodeFiles.read(in,8*1024*1024),StandardCharsets.UTF_8);}
  }finally{active=null;}
 }
 List<CloudProtocol.Model> models(CloudProtocol.Provider p,String key)throws Exception{return CloudProtocol.models(p,request(p,key,p.modelsUrl,null));}
 @Override public String generate(CloudRouter.Account a,String system,String prompt,int max)throws Exception{return CloudProtocol.answer(a.provider,request(a.provider,a.key,CloudProtocol.endpoint(a.provider,a.model),CloudProtocol.body(a.provider,a.model,system,prompt,max)));}
}
