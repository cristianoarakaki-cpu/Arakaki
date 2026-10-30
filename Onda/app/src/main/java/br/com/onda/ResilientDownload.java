package br.com.onda;

import java.io.*;
import java.net.*;
import java.util.regex.*;

/** Bounded in-operation recovery. Never concatenate a full response onto a partial file. */
final class ResilientDownload {
 static final long CHUNK=8L*1024*1024,MAX=512L*1024*1024;
 interface Control {
  void check()throws IOException;
  void opened(HttpURLConnection connection);
  void closed(HttpURLConnection connection);
  void bytes(int count,long stored,long expected)throws IOException;
  void retry(int number,long stored)throws IOException;
 }
 interface Factory {HttpURLConnection open(URL url)throws IOException;}
 interface Sleeper {void pause(long millis)throws InterruptedException;}
 static final class Failure extends IOException {Failure(String message,IOException cause){super(message,cause);}}
 private static final class Changed extends IOException {Changed(){super("O arquivo mudou no servidor");}}
 private static final class HttpFailure extends IOException {final int status;HttpFailure(int value){super("Servidor recusou o download (HTTP "+value+"). Analise o link novamente ou tente mais tarde.");status=value;}}
 private static final class Range {final long start,end,total;Range(long s,long e,long t){start=s;end=e;total=t;}}
 private static final Pattern CONTENT_RANGE=Pattern.compile("bytes (\\d+)-(\\d+)/(\\d+)",Pattern.CASE_INSENSITIVE);
 private static Range range(String value)throws ProtocolException {try{Matcher m=CONTENT_RANGE.matcher(value==null?"":value.trim());if(!m.matches())throw new IllegalArgumentException();long start=Long.parseLong(m.group(1)),end=Long.parseLong(m.group(2)),total=Long.parseLong(m.group(3));if(start<0||end<start||total<=end)throw new IllegalArgumentException();return new Range(start,end,total);}catch(Exception e){throw new ProtocolException("Servidor retornou uma faixa de bytes inválida");}}
 private static boolean transientError(IOException e){
  Throwable cause=e;boolean network=false;for(int i=0;cause!=null&&i<6;i++,cause=cause.getCause()){
   if(cause instanceof java.security.cert.CertificateException||cause instanceof java.security.cert.CertPathValidatorException||cause instanceof javax.net.ssl.SSLPeerUnverifiedException)return false;
   if(cause instanceof SocketException||cause instanceof SocketTimeoutException||cause instanceof EOFException||cause instanceof UnknownHostException)network=true;
   String message=cause.getMessage();if(cause instanceof IOException&&message!=null){String text=message.toLowerCase(java.util.Locale.ROOT);if(text.contains("connection reset")||text.contains("connection aborted")||text.contains("unexpected end of stream")||text.contains("broken pipe"))network=true;}
  }
  return network||e instanceof Changed||(e instanceof HttpFailure&&(((HttpFailure)e).status==408||((HttpFailure)e).status==500||((HttpFailure)e).status==502||((HttpFailure)e).status==503||((HttpFailure)e).status==504));
 }
 static void fetch(String link,File target,long maxBytes,String agent,Control control)throws IOException {fetch(link,target,maxBytes,agent,control,"");}
 static void fetch(String link,File target,long maxBytes,String agent,Control control,String referer)throws IOException {fetch(link,target,maxBytes,agent,control,url->{HttpURLConnection c=PublicMediaHttp.open(url);if(referer!=null&&!referer.isEmpty()){try{c.setRequestProperty("Referer",MediaLinks.referer(referer));}catch(Exception e){c.disconnect();throw new IOException("Origem do vídeo inválida",e);}}return c;},Thread::sleep);}
 static void fetch(String link,File target,long maxBytes,String agent,Control control,Factory factory,Sleeper sleeper)throws IOException {
  URL initial=new URL(link);https(initial);if(maxBytes<=0||maxBytes>MAX)throw new IOException("Limite de tamanho atingido");
  try(RandomAccessFile fresh=new RandomAccessFile(target,"rw")){fresh.setLength(0);}long expected=-1;String validator=null;boolean useEtag=false;int failures=0,requests=0;
  while(true){control.check();long offset=target.length();if(expected>0&&offset==expected)return;if(offset>=maxBytes)throw new IOException("Limite de tamanho atingido");long end=Math.min(maxBytes-1,offset+CHUNK-1);HttpURLConnection c=null;
   try{
    URL url=initial;int redirects=0;
    while(true){control.check();https(url);if(++requests>512)throw new ProtocolException("O servidor fragmentou o arquivo em partes demais");c=factory.open(url);control.opened(c);c.setConnectTimeout(15000);c.setReadTimeout(20000);c.setInstanceFollowRedirects(false);c.setRequestProperty("User-Agent",agent);c.setRequestProperty("Accept-Encoding","identity");c.setRequestProperty("Connection","close");c.setRequestProperty("Range","bytes="+offset+"-"+end);if(offset>0&&validator!=null)c.setRequestProperty("If-Range",validator);
     int status=c.getResponseCode();if(status==301||status==302||status==303||status==307||status==308){String location=c.getHeaderField("Location");if(location==null||++redirects>3)throw new ProtocolException("Redirecionamento inválido");URL next=new URL(url,location);https(next);control.closed(c);c.disconnect();c=null;url=next;continue;}break;
    }
    int code=c.getResponseCode();if(code!=200&&code!=206)throw new HttpFailure(code);String encoding=c.getHeaderField("Content-Encoding");if(encoding!=null&&!encoding.isEmpty()&&!"identity".equalsIgnoreCase(encoding))throw new ProtocolException("Resposta comprimida incompatível com continuação");
    String etag=c.getHeaderField("ETag");if(etag!=null&&etag.startsWith("W/"))etag=null;String modified=c.getHeaderField("Last-Modified");String current=offset>0&&validator!=null?(useEtag?etag:modified):(etag!=null?etag:modified);long responseLength=c.getContentLengthLong(),wanted;
    if(code==206){Range part=range(c.getHeaderField("Content-Range"));if(part.start!=offset||part.end>end)throw new ProtocolException("Servidor retornou bytes diferentes dos solicitados");if(part.total>maxBytes)throw new IOException("Arquivo excede o limite de tamanho");if((expected>0&&part.total!=expected)||(offset>0&&validator!=null&&current!=null&&!validator.equals(current)))throw new Changed();expected=part.total;wanted=part.end-part.start+1;if(responseLength>=0&&responseLength!=wanted)throw new ProtocolException("Tamanho da resposta incompatível com a faixa solicitada");}
    else{offset=0;expected=responseLength;wanted=responseLength;if(expected==0)throw new IOException("O servidor retornou um arquivo vazio");if(expected>maxBytes)throw new IOException("Arquivo excede o limite de tamanho");}
    if(offset==0||validator==null){useEtag=etag!=null;validator=useEtag?etag:modified;}else if(current!=null)validator=current;
    try(RandomAccessFile out=new RandomAccessFile(target,"rw")){if(offset==0)out.setLength(0);out.seek(offset);try(InputStream in=c.getInputStream()){byte[] bytes=new byte[65536];long received=0;int count;
     while((count=in.read(bytes))!=-1){control.check();if(wanted>=0&&received+count>wanted)throw new ProtocolException("Servidor enviou mais bytes que o informado");if(offset+received+count>maxBytes)throw new IOException("Arquivo excede o limite de tamanho");control.bytes(count,offset+received+count,expected);out.write(bytes,0,count);received+=count;}
     if(received==0||(wanted>=0&&received!=wanted))throw new EOFException("Conexão encerrada antes de completar o download");}
    }
    control.check();if(code==200)return;if(target.length()==expected)return;
   }catch(IOException error){control.check();if(!transientError(error))throw error;if(!(error instanceof Changed)&&expected>0&&target.length()==expected)return;if(++failures>=3)throw new Failure("Não foi possível concluir o download após duas reconexões. A conexão continuou sendo interrompida. Tente outra rede ou mais tarde.",error);
    if(error instanceof Changed){try(RandomAccessFile fresh=new RandomAccessFile(target,"rw")){fresh.setLength(0);}expected=-1;validator=null;useEtag=false;}
    if(c!=null){control.closed(c);c.disconnect();c=null;}control.retry(failures,target.length());try{sleeper.pause(600L*failures);}catch(InterruptedException e){Thread.currentThread().interrupt();throw new InterruptedIOException("Download cancelado durante a reconexão");}control.check();
   }finally{if(c!=null){control.closed(c);c.disconnect();}}
  }
 }
 private static void https(URL url)throws IOException {if(!"https".equalsIgnoreCase(url.getProtocol())||url.getUserInfo()!=null)throw new ProtocolException("Somente links HTTPS são aceitos no download");}
}
