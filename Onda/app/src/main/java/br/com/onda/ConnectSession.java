package br.com.onda;
import java.io.*;
import java.net.*;
import java.security.MessageDigest;
import java.util.*;
import java.util.concurrent.*;
import java.util.function.Consumer;
import javax.net.ssl.*;
/** One foreground, one-use transfer. Closing it aborts sockets and pending approval. */
final class ConnectSession implements AutoCloseable {
 interface Source {InputStream open(int index)throws Exception;}
 interface Target {OutputStream stream();void commit()throws Exception;void abort();}
 interface Sink {Target create(ConnectProtocol.FileInfo file)throws Exception;}
 interface Listener {void pair(ConnectProtocol.Pair pair);void offer(List<ConnectProtocol.FileInfo> files,Consumer<Boolean> answer);void progress(String text,long done,long total);void finished(boolean success,int completed,String message);}
 private volatile boolean closed;private volatile ServerSocket server;private volatile Socket socket;private volatile Closeable io;private final CompletableFuture<Boolean> approval=new CompletableFuture<>();private final Listener listener;private long lastProgress,done,total;private int completed;
 ConnectSession(Listener listener){this.listener=listener;}
 void receive(SSLContext tls,String host,String pin,Sink sink){boolean success=false;String result="Transferência interrompida. Os arquivos concluídos foram mantidos.";try{
  SSLServerSocket listening=(SSLServerSocket)tls.getServerSocketFactory().createServerSocket();server=listening;listening.bind(new InetSocketAddress(host,0),1);listening.setSoTimeout(180000);check();String token=ConnectProtocol.secret();listener.pair(new ConnectProtocol.Pair(host,listening.getLocalPort(),token,pin));
  try(SSLSocket client=(SSLSocket)listening.accept()){socket=client;check();client.setSoTimeout(15000);client.startHandshake();DataInputStream input=new DataInputStream(new BufferedInputStream(client.getInputStream(),65536));DataOutputStream output=new DataOutputStream(new BufferedOutputStream(client.getOutputStream(),65536));List<ConnectProtocol.FileInfo> files=ConnectProtocol.offer(input,token);total=ConnectProtocol.total(files);listener.offer(files,value->approval.complete(value));boolean allowed=approval.get(60,TimeUnit.SECONDS);check();output.writeBoolean(allowed);output.flush();if(!allowed){result="Recebimento recusado. Nenhum arquivo foi criado.";return;}
   for(ConnectProtocol.FileInfo file:files){check();Target target=sink.create(file);boolean committed=false;try{io=target.stream();byte[] digest=ConnectProtocol.copy(input,target.stream(),file.size,n->progress(file.name,n));target.stream().close();io=null;byte[] expected=new byte[32];input.readFully(expected);if(!MessageDigest.isEqual(digest,expected))throw new IOException("Falha de integridade");check();target.commit();committed=true;completed++;output.writeBoolean(true);output.flush();}finally{io=null;if(!committed){try{target.stream().close();}catch(Exception ignored){}target.abort();}}}
   success=true;result="Recebimento concluído.";
  }
 }catch(SocketTimeoutException|TimeoutException e){result="Tempo esgotado. Gere um novo QR e tente novamente na mesma rede Wi-Fi.";}catch(Exception e){if(!closed)result="Não foi possível concluir. Confira a rede Wi-Fi e o espaço da pasta. Arquivos já concluídos foram mantidos.";}finally{close();listener.finished(success,completed,result);}}
 void send(SSLContext tls,ConnectProtocol.Pair pair,List<ConnectProtocol.FileInfo> files,Source source){send(tls,pair,files,source,javax.net.SocketFactory.getDefault());}
 void send(SSLContext tls,ConnectProtocol.Pair pair,List<ConnectProtocol.FileInfo> files,Source source,javax.net.SocketFactory route){boolean success=false;String result="Envio interrompido. Arquivos já concluídos foram mantidos no destino.";try{total=ConnectProtocol.total(files);Socket raw=route.createSocket();socket=raw;check();raw.connect(new InetSocketAddress(pair.host,pair.port),10000);SSLSocket client=(SSLSocket)tls.getSocketFactory().createSocket(raw,pair.host,pair.port,true);socket=client;check();client.setSoTimeout(15000);client.startHandshake();DataInputStream input=new DataInputStream(new BufferedInputStream(client.getInputStream(),65536));DataOutputStream output=new DataOutputStream(new BufferedOutputStream(client.getOutputStream(),65536));ConnectProtocol.offer(output,pair.token,files);listener.progress("Aguardando autorização no outro celular…",0,total);client.setSoTimeout(90000);if(!input.readBoolean()){result="O outro celular recusou o recebimento.";return;}client.setSoTimeout(15000);
  for(int i=0;i<files.size();i++){check();ConnectProtocol.FileInfo file=files.get(i);try(InputStream stream=source.open(i)){io=stream;byte[] digest=ConnectProtocol.copy(stream,output,file.size,n->progress(file.name,n));if(stream.read()!=-1)throw new IOException("Arquivo alterado após a seleção");output.write(digest);output.flush();if(!input.readBoolean())throw new IOException("Arquivo não confirmado");completed++;}finally{io=null;}}
  success=true;result="Envio concluído.";
 }catch(Exception e){if(!closed)result="Não foi possível concluir. Confira o QR, a rede Wi-Fi e a autorização no outro celular. Gere um novo QR para tentar novamente.";}finally{close();listener.finished(success,completed,result);}}
 private void progress(String name,long bytes)throws IOException{check();done+=bytes;long now=System.nanoTime();if(now-lastProgress>300000000L||done==total){lastProgress=now;listener.progress("Transferindo: "+name,done,total);}}
 private void check()throws IOException{if(closed||Thread.currentThread().isInterrupted())throw new InterruptedIOException();}
 @Override public void close(){closed=true;approval.complete(false);try{if(socket!=null)socket.close();}catch(Exception ignored){}try{if(server!=null)server.close();}catch(Exception ignored){}try{if(io!=null)io.close();}catch(Exception ignored){}}
}
