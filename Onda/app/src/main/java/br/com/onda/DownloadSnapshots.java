package br.com.onda;
import android.content.Context;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
/** Private snapshots keep large selections out of Android's limited Binder transaction. */
final class DownloadSnapshots {
 private static File file(Context c,String token)throws IOException{if(token==null||!token.matches("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"))throw new IOException("Seleção inválida");File dir=new File(c.getFilesDir(),"download-selections");if(!dir.isDirectory()&&!dir.mkdirs())throw new IOException("Não foi possível guardar a seleção");return new File(dir,token+".json");}
 static String write(Context c,String value)throws IOException{String token=UUID.randomUUID().toString();File f=file(c,token);try(Writer out=new OutputStreamWriter(new FileOutputStream(f),StandardCharsets.UTF_8)){out.write(value);}catch(IOException e){f.delete();throw e;}return token;}
 static String read(Context c,String token)throws IOException{try(Reader in=new InputStreamReader(new FileInputStream(file(c,token)),StandardCharsets.UTF_8)){StringBuilder s=new StringBuilder();char[] b=new char[8192];int n;while((n=in.read(b))!=-1)s.append(b,0,n);return s.toString();}}
 static void remove(Context c,String token){try{file(c,token).delete();}catch(IOException ignored){}}
}
