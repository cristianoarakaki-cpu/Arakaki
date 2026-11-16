package br.com.arakaki.codigolivre;
import java.io.*;
import java.security.*;
import java.util.function.*;
import org.json.*;
/** Metadados e verificação independentes do Android para permitir testes com arquivos fictícios. */
final class ModelPackage {
 static final String REPO="Qwen/Qwen2.5-1.5B-Instruct-GGUF";
 static final String FILE="qwen2.5-1.5b-instruct-q4_k_m.gguf";
 static final class Info {final String revision,hash;final long size;Info(String revision,String hash,long size){this.revision=revision;this.hash=hash;this.size=size;}String url(){return "https://huggingface.co/"+REPO+"/resolve/"+revision+"/"+FILE;}}
 static Info parse(String json)throws Exception{
  JSONObject root=new JSONObject(json);String revision=root.getString("sha");if(!revision.matches("[a-fA-F0-9]{40}"))throw new IOException("Revisão do modelo inválida.");
  JSONArray files=root.getJSONArray("siblings");for(int i=0;i<files.length();i++){JSONObject f=files.getJSONObject(i);if(!FILE.equals(f.optString("rfilename")))continue;JSONObject lfs=f.getJSONObject("lfs");String hash=lfs.getString("sha256");long size=lfs.getLong("size");if(!hash.matches("[a-fA-F0-9]{64}")||size<1024||size>2L*1024*1024*1024)throw new IOException("Metadados de integridade inválidos.");return new Info(revision,hash.toLowerCase(java.util.Locale.ROOT),size);}
  throw new IOException("Modelo recomendado não encontrado na fonte oficial.");
 }
 static void range(String header,long offset,long size)throws IOException{if(header==null||!header.matches("bytes "+offset+"-[0-9]+/"+size))throw new IOException("Resposta de retomada inválida; tente novamente.");long end=Long.parseLong(header.substring(header.indexOf('-')+1,header.indexOf('/')));if(end<offset||end!=size-1)throw new IOException("Intervalo incompleto do servidor.");}
 static void receive(InputStream in,File file,long offset,long size,BooleanSupplier cancelled,LongConsumer progress)throws IOException{
  if(file.length()!=offset)throw new IOException("Arquivo parcial mudou durante o download.");
  try(FileOutputStream out=new FileOutputStream(file,offset>0)){byte[] buffer=new byte[256*1024];long done=offset;int n;while((n=in.read(buffer))!=-1){if(cancelled.getAsBoolean())throw new java.util.concurrent.CancellationException();if(n>size-done)throw new IOException("Download excedeu o tamanho previsto.");out.write(buffer,0,n);done+=n;progress.accept(done);}out.getFD().sync();if(done!=size)throw new IOException("Download incompleto. Toque Preparar IA para retomar.");}
 }
 static void verify(File file,Info info,BooleanSupplier cancelled)throws Exception{
  if(file.length()!=info.size)throw new IOException("Tamanho incorreto do modelo.");MessageDigest digest=MessageDigest.getInstance("SHA-256");
  try(InputStream in=new FileInputStream(file)){byte[] magic=new byte[4];new DataInputStream(in).readFully(magic);if(!java.util.Arrays.equals(magic,new byte[]{'G','G','U','F'}))throw new IOException("Modelo não tem cabeçalho GGUF.");digest.update(magic);byte[] buffer=new byte[1024*1024];int n;while((n=in.read(buffer))!=-1){if(cancelled.getAsBoolean())throw new java.util.concurrent.CancellationException();digest.update(buffer,0,n);}}
  StringBuilder hash=new StringBuilder();for(byte b:digest.digest())hash.append(String.format(java.util.Locale.ROOT,"%02x",b&255));if(!hash.toString().equals(info.hash))throw new IOException("SHA256 não confere. O modelo atual foi preservado; descarte o download e tente novamente.");
 }
}
