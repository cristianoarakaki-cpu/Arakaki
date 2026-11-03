package br.com.onda;

import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.provider.OpenableColumns;
import android.util.AtomicFile;
import org.json.*;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.*;

/** Private seek markers only; the selected audio is never opened for writing. */
final class AudioChapterStore {
    static final class Chapter {final long start;final String title;Chapter(long start,String title){this.start=start;this.title=title==null?"":title;}}
    static final class Data {final long duration;final List<Chapter> chapters;Data(long duration,List<Chapter> chapters){this.duration=duration;this.chapters=Collections.unmodifiableList(new ArrayList<>(chapters));}}
    static Data detected(AudioChapterScanner.Result result){ArrayList<Chapter> tracks=new ArrayList<>();for(long at:result.starts)tracks.add(new Chapter(at,""));return new Data(result.duration,tracks);}
    static String label(Data data,int index){String name=data.chapters.get(index).title.trim();return name.isEmpty()?"Faixa "+(index+1):name;}
    static String stamp(Context context,Uri uri){if("file".equals(uri.getScheme())){File file=new File(uri.getPath());return file.length()+":"+file.lastModified();}String size="?",changed="?";try(Cursor c=context.getContentResolver().query(uri,null,null,null,null)){if(c!=null&&c.moveToFirst()){int s=c.getColumnIndex(OpenableColumns.SIZE),m=c.getColumnIndex("date_modified");if(s>=0&&!c.isNull(s))size=c.getString(s);if(m>=0&&!c.isNull(m))changed=c.getString(m);}}catch(RuntimeException ignored){}return size+":"+changed;}
    private static AtomicFile file(Context context,Uri uri)throws IOException{try{byte[] hash=MessageDigest.getInstance("SHA-256").digest(uri.toString().getBytes(StandardCharsets.UTF_8));StringBuilder name=new StringBuilder();for(byte b:hash)name.append(String.format(Locale.ROOT,"%02x",b&255));File directory=new File(context.getFilesDir(),"audio-chapters");if(!directory.isDirectory()&&!directory.mkdirs())throw new IOException("Não foi possível salvar as divisões.");return new AtomicFile(new File(directory,name+".json"));}catch(java.security.NoSuchAlgorithmException e){throw new IOException(e);}}
    private static void validate(Data data)throws IOException{if(data==null||data.duration<=0||data.chapters.isEmpty()||data.chapters.get(0).start!=0)throw new IOException("Divisões inválidas.");long previous=-1;for(Chapter chapter:data.chapters){if(chapter.start<=previous||chapter.start>=data.duration||chapter.title.length()>120)throw new IOException("Divisões inválidas.");previous=chapter.start;}}
    static Data load(Context context,Uri uri,String fingerprint,long duration)throws IOException{AtomicFile target=file(context,uri);if(!target.getBaseFile().exists()&&!new File(target.getBaseFile().getPath()+".bak").exists())return null;try(InputStream in=target.openRead();ByteArrayOutputStream out=new ByteArrayOutputStream()){byte[] buffer=new byte[8192];int n;while((n=in.read(buffer))!=-1){if(out.size()+n>1048576)throw new IOException("Divisões salvas inválidas.");out.write(buffer,0,n);}JSONObject json=new JSONObject(out.toString("UTF-8"));if(json.getInt("version")!=1)throw new IOException("Formato de divisões não reconhecido. Reanalisar substitui apenas as marcações.");if(!fingerprint.equals(json.getString("stamp")))return null;long savedDuration=json.getLong("duration");if(duration>0&&Math.abs(duration-savedDuration)>1500)return null;JSONArray list=json.getJSONArray("chapters");ArrayList<Chapter> tracks=new ArrayList<>();for(int i=0;i<list.length();i++){JSONObject row=list.getJSONObject(i);tracks.add(new Chapter(row.getLong("start"),row.getString("title")));}Data result=new Data(savedDuration,tracks);validate(result);return result;}catch(JSONException e){throw new IOException("Não foi possível ler as divisões. O áudio original está preservado.",e);}}
    static void save(Context context,Uri uri,String fingerprint,Data data)throws IOException{validate(data);if(!fingerprint.equals(stamp(context,uri)))throw new IOException("O arquivo mudou durante a análise. Tente novamente.");try{JSONArray rows=new JSONArray();for(Chapter chapter:data.chapters)rows.put(new JSONObject().put("start",chapter.start).put("title",chapter.title));byte[] bytes=new JSONObject().put("version",1).put("stamp",fingerprint).put("duration",data.duration).put("chapters",rows).toString().getBytes(StandardCharsets.UTF_8);if(bytes.length>1048576)throw new IOException("As marcações excedem o espaço de armazenamento local disponível para este arquivo.");AtomicFile target=file(context,uri);FileOutputStream out=target.startWrite();try{out.write(bytes);target.finishWrite(out);}catch(IOException|RuntimeException error){target.failWrite(out);throw error;}}catch(JSONException e){throw new IOException(e);}}
}
