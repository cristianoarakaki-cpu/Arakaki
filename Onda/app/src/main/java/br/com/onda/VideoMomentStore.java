package br.com.onda;
import android.content.*;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.*;
final class VideoMomentStore {
 static final int FILE_LIMIT=100;
 private static String key(Context c,Uri source){Uri uri=source;String authority=uri.getAuthority();if(Build.VERSION.SDK_INT>=29&&("com.android.externalstorage.documents".equals(authority)||"com.android.providers.media.documents".equals(authority)||"com.android.providers.downloads.documents".equals(authority))){try{Uri media=MediaStore.getMediaUri(c,uri);if(media!=null)uri=media;}catch(RuntimeException ignored){}}
  String identity=uri.toString();if("media".equals(uri.getAuthority())){try{long id=ContentUris.parseId(uri);if(id>=0)identity="video:"+(uri.getPathSegments().contains("internal")?"internal:":"external:")+id;}catch(RuntimeException ignored){}}
  try{byte[] bytes=MessageDigest.getInstance("SHA-256").digest(identity.getBytes(StandardCharsets.UTF_8));StringBuilder out=new StringBuilder("v:");for(byte b:bytes){out.append(Character.forDigit((b>>4)&15,16));out.append(Character.forDigit(b&15,16));}return out.toString();}catch(Exception e){throw new IllegalStateException(e);}
 }
 private static SharedPreferences prefs(Context c){return c.getSharedPreferences("video_moments",0);}
 static synchronized List<VideoMoments.Moment> read(Context c,Uri uri){return VideoMoments.decode(prefs(c).getString(key(c,uri),"[]"));}
 static synchronized VideoMoments.Moment add(Context c,Uri uri,String label,long position){String k=key(c,uri);SharedPreferences p=prefs(c);List<VideoMoments.Moment> items=VideoMoments.decode(p.getString(k,"[]"));if(items.size()>=VideoMoments.LIMIT)return null;if(!p.contains(k)&&p.getAll().size()>=FILE_LIMIT)return null;VideoMoments.Moment item=new VideoMoments.Moment(UUID.randomUUID().toString(),VideoMoments.label(label),position);if(!VideoMoments.valid(item))return null;items.add(item);p.edit().putString(k,VideoMoments.encode(items)).apply();return item;}
 static synchronized boolean rename(Context c,Uri uri,String id,String label){String k=key(c,uri);List<VideoMoments.Moment> items=read(c,uri);for(int i=0;i<items.size();i++){VideoMoments.Moment old=items.get(i);if(old.id.equals(id)){VideoMoments.Moment changed=new VideoMoments.Moment(id,VideoMoments.label(label),old.position,old.note);if(!VideoMoments.valid(changed))return false;items.set(i,changed);prefs(c).edit().putString(k,VideoMoments.encode(items)).apply();return true;}}return false;}
 static synchronized boolean annotate(Context c,Uri uri,String id,String note){String k=key(c,uri);List<VideoMoments.Moment> items=read(c,uri);for(int i=0;i<items.size();i++){VideoMoments.Moment old=items.get(i);if(old.id.equals(id)){VideoMoments.Moment changed=new VideoMoments.Moment(id,old.label,old.position,VideoMoments.note(note));if(!VideoMoments.valid(changed))return false;items.set(i,changed);prefs(c).edit().putString(k,VideoMoments.encode(items)).apply();return true;}}return false;}
 static synchronized boolean remove(Context c,Uri uri,String id){String k=key(c,uri);List<VideoMoments.Moment> items=read(c,uri);if(!items.removeIf(m->m.id.equals(id)))return false;SharedPreferences.Editor e=prefs(c).edit();if(items.isEmpty())e.remove(k);else e.putString(k,VideoMoments.encode(items));e.apply();return true;}
}
