package br.com.onda;
import android.content.*;
final class ShelfStore {
 interface Edit {boolean apply(MediaShelf shelf);}
 static synchronized MediaShelf read(Context c){return MediaShelf.decode(c.getSharedPreferences("media_shelf",0).getString("data","{\"v\":1}"));}
 static synchronized boolean edit(Context c,Edit action){MediaShelf s=read(c);if(!s.valid||!action.apply(s))return false;String raw=s.encode();if(raw.length()>MediaShelf.MAX_JSON)return false;c.getSharedPreferences("media_shelf",0).edit().putString("data",raw).apply();return true;}
 static void remember(Context c,String type,String uri,String title,long position,long duration){edit(c,s->s.touch(type,uri,title,position,duration,System.currentTimeMillis())!=null);}
}
