package br.com.onda;
import java.io.*;
import java.net.URI;
import java.security.*;
import java.util.*;
/** Bounded, versioned local transfer protocol; no file paths supplied by peers. */
final class ConnectProtocol {
 static final int MAGIC=0x4f4e4431,FILES=10;static final long FILE_LIMIT=512L*1024*1024,TOTAL_LIMIT=1024L*1024*1024;
 static final class Pair {
  final String host,token,pin;final int port;
  Pair(String host,int port,String token,String pin){this.host=host;this.port=port;this.token=token;this.pin=pin;}
  String code(){return "onda-connect://"+host+":"+port+"/1/"+token+"/"+pin;}
  static Pair parse(String code)throws IOException{try{if(code==null||code.length()>300)throw new Exception();URI uri=new URI(code.trim());String[] p=uri.getPath().split("/");String host=uri.getHost();int port=uri.getPort();if(!"onda-connect".equals(uri.getScheme())||uri.getUserInfo()!=null||uri.getQuery()!=null||uri.getFragment()!=null||!privateHost(host)||port<1024||port>65535||p.length!=4||!p[1].equals("1")||!p[2].matches("[a-f0-9]{64}")||!p[3].matches("[a-f0-9]{64}"))throw new Exception();return new Pair(host,port,p[2],p[3]);}catch(Exception e){throw new IOException("Código Conecta inválido ou incompatível.");}}
 }
 static boolean privateHost(String host){if(host==null)return false;String[] p=host.split("\\.");if(p.length!=4)return false;int[] n=new int[4];try{for(int i=0;i<4;i++){if(!p[i].matches("[0-9]{1,3}"))return false;n[i]=Integer.parseInt(p[i]);if(n[i]>255)return false;}}catch(Exception e){return false;}return n[0]==10||n[0]==192&&n[1]==168||n[0]==172&&n[1]>=16&&n[1]<=31;}
 static final class FileInfo {final String name,mime;final long size;FileInfo(String name,String mime,long size)throws IOException{this.name=safeName(name);if(mime==null||mime.length()>100||!(mime.startsWith("audio/")||mime.startsWith("video/")||mime.equals("application/pdf"))||size<0||size>FILE_LIMIT)throw new IOException("Escolha áudios, vídeos ou PDFs de até 512 MB, com tamanho conhecido.");this.mime=mime;this.size=size;}}
 static String safeName(String name)throws IOException{if(name==null||name.trim().isEmpty())throw new IOException("Nome inválido");String s=name.trim().replaceAll("[\\\\/\\p{Cntrl}]","_");if(s.equals(".")||s.equals("..")||s.startsWith("."))s="Onda-"+s;s=s.substring(0,Math.min(180,s.length()));return s;}
 static long total(List<FileInfo> files)throws IOException{if(files.isEmpty()||files.size()>FILES)throw new IOException("Escolha de 1 a 10 arquivos.");long sum=0;for(FileInfo f:files){sum+=f.size;if(sum>TOTAL_LIMIT)throw new IOException("O envio deve ter até 1 GB no total.");}return sum;}
 static void offer(DataOutputStream out,String token,List<FileInfo> files)throws IOException{total(files);out.writeInt(MAGIC);out.writeUTF(token);out.writeInt(files.size());for(FileInfo f:files){out.writeUTF(f.name);out.writeUTF(f.mime);out.writeLong(f.size);}out.flush();}
 static List<FileInfo> offer(DataInputStream in,String token)throws IOException{if(in.readInt()!=MAGIC||!MessageDigest.isEqual(in.readUTF().getBytes(java.nio.charset.StandardCharsets.UTF_8),token.getBytes(java.nio.charset.StandardCharsets.UTF_8)))throw new IOException("Pareamento não autorizado.");int count=in.readInt();if(count<1||count>FILES)throw new IOException("Quantidade inválida");List<FileInfo> result=new ArrayList<>();for(int i=0;i<count;i++)result.add(new FileInfo(in.readUTF(),in.readUTF(),in.readLong()));total(result);return result;}
 interface Progress {void bytes(long amount)throws IOException;}
 static byte[] copy(InputStream input,OutputStream output,long size,Progress progress)throws IOException{try{MessageDigest hash=MessageDigest.getInstance("SHA-256");byte[] buffer=new byte[65536];long remaining=size;while(remaining>0){if(Thread.currentThread().isInterrupted())throw new InterruptedIOException();int read=input.read(buffer,0,(int)Math.min(buffer.length,remaining));if(read<0)throw new EOFException("Arquivo ou conexão interrompida");if(read==0)continue;output.write(buffer,0,read);hash.update(buffer,0,read);remaining-=read;progress.bytes(read);}return hash.digest();}catch(NoSuchAlgorithmException e){throw new IOException(e);}}
 static String hex(byte[] data){StringBuilder s=new StringBuilder();for(byte b:data)s.append(String.format(Locale.ROOT,"%02x",b&255));return s.toString();}
 static String secret(){byte[] b=new byte[32];new SecureRandom().nextBytes(b);return hex(b);}
}
