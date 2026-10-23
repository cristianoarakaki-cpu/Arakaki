package br.com.onda;

import org.schabi.newpipe.extractor.downloader.*;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.util.*;

/** Bounded metadata requests. No login cookies, proxy service or analytics. */
final class ExtractorHttp extends Downloader {
 private static final ThreadLocal<Long> deadline=new ThreadLocal<>();
 static void begin(){deadline.set(System.currentTimeMillis()+90000);}
 static void end(){deadline.remove();}
 static int remaining()throws IOException{Long until=deadline.get();long left=until==null?20000:until-System.currentTimeMillis();if(left<=0||Thread.currentThread().isInterrupted())throw new InterruptedIOException("Tempo limite da consulta");return (int)Math.min(20000,left);}
 static final String AGENT="Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36";
 @Override public Response execute(Request request)throws IOException {
  if(Thread.currentThread().isInterrupted())throw new InterruptedIOException();
  URL url=new URL(request.url());if(!"https".equalsIgnoreCase(url.getProtocol()))throw new IOException("HTTPS obrigatório");
  HttpURLConnection c=(HttpURLConnection)url.openConnection();
  try{
   c.setConnectTimeout(Math.min(15000,remaining()));c.setReadTimeout(remaining());c.setRequestMethod(request.httpMethod());c.setRequestProperty("User-Agent",AGENT);
   for(Map.Entry<String,List<String>> h:request.headers().entrySet())if(h.getValue()!=null) c.setRequestProperty(h.getKey(),String.join(", ",h.getValue()));
   byte[] body=request.dataToSend();if(body!=null){c.setDoOutput(true);try(OutputStream out=c.getOutputStream()){out.write(body);}}
   int code=c.getResponseCode();InputStream raw=code>=400?c.getErrorStream():c.getInputStream();ByteArrayOutputStream out=new ByteArrayOutputStream();
   if(raw!=null)try(InputStream in=raw){byte[] b=new byte[16384];int n;while((n=in.read(b))!=-1){remaining();if(out.size()+n>12*1024*1024)throw new IOException("Resposta excede limite");out.write(b,0,n);}}
   return new Response(code,c.getResponseMessage(),c.getHeaderFields(),new String(out.toByteArray(),StandardCharsets.UTF_8),c.getURL().toString());
  }finally{c.disconnect();}
 }
}
