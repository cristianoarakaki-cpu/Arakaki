package br.com.onda;
import android.content.*;
import android.net.Uri;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.*;
final class VideoProgressStore {
    private static String key(Uri uri){try{byte[] bytes=MessageDigest.getInstance("SHA-256").digest(uri.toString().getBytes(StandardCharsets.UTF_8));StringBuilder out=new StringBuilder();for(byte b:bytes){out.append(Character.forDigit((b>>4)&15,16));out.append(Character.forDigit(b&15,16));}return out.toString();}catch(Exception e){throw new IllegalStateException(e);}}
    static long read(Context c,Uri uri,long duration){SharedPreferences p=c.getSharedPreferences("video_progress",0);String k=key(uri);return VideoProgress.resume(p.getLong(k+":position",0),p.getLong(k+":duration",0),duration);}
    static void save(Context c,Uri uri,long position,long duration){ShelfStore.remember(c,"video",uri.toString(),"",position,duration);SharedPreferences p=c.getSharedPreferences("video_progress",0);String k=key(uri);SharedPreferences.Editor e=p.edit();if(VideoProgress.resume(position,duration,duration)==0)e.remove(k+":position").remove(k+":duration").remove(k+":seen");else e.putLong(k+":position",position).putLong(k+":duration",duration).putLong(k+":seen",System.currentTimeMillis());
        List<Map.Entry<String,?>> seen=new ArrayList<>();for(Map.Entry<String,?> entry:p.getAll().entrySet())if(entry.getKey().endsWith(":seen")&&!entry.getKey().equals(k+":seen"))seen.add(entry);seen.sort(Comparator.comparingLong(a->a.getValue() instanceof Long?(Long)a.getValue():0));while(seen.size()>=100){String old=seen.remove(0).getKey().replace(":seen","");e.remove(old+":position").remove(old+":duration").remove(old+":seen");}e.apply();}
    static void clear(Context c,Uri uri){save(c,uri,0,0);}
}
