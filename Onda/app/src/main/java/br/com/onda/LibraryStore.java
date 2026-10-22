package br.com.onda;

import android.content.*;
import android.database.Cursor;
import android.os.Bundle;
import android.provider.MediaStore;
import androidx.media3.common.*;
import java.util.*;

final class LibraryStore {
    static List<MediaItem> scan(Context context){
        ArrayList<MediaItem> songs=new ArrayList<>();
        String[] columns={"_id","title","artist","album","duration","_size","date_added"};
        try(Cursor c=context.getContentResolver().query(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,columns,null,null,MediaStore.Audio.Media.TITLE+" COLLATE NOCASE ASC")){
            if(c!=null)while(c.moveToNext()){
                if(Thread.currentThread().isInterrupted())break;if(c.getLong(4)<=0)continue;
                String id=c.getString(0),name=c.getString(1),author=c.getString(2),album=c.getString(3);
                Bundle extras=new Bundle();extras.putLong("durationMs",c.getLong(4));extras.putLong("size",c.getLong(5));extras.putLong("added",c.getLong(6));
                songs.add(new MediaItem.Builder().setMediaId(id).setUri(ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,c.getLong(0))).setMediaMetadata(new MediaMetadata.Builder().setTitle(name==null?"Sem título":name).setArtist(author==null||author.equals("<unknown>")?"Artista desconhecido":author).setAlbumTitle(album).setExtras(extras).build()).build());
            }
        }
        return songs;
    }
    static long number(MediaItem item,String key){Bundle extras=item.mediaMetadata.extras;return extras==null?0:extras.getLong(key,0);}
    static int count(Context c,String id){return c.getSharedPreferences("listening",Context.MODE_PRIVATE).getInt("count:"+id,0);}
    static long last(Context c,String id){return c.getSharedPreferences("listening",Context.MODE_PRIVATE).getLong("last:"+id,0);}
    static void heard(Context c,String id){SharedPreferences p=c.getSharedPreferences("listening",Context.MODE_PRIVATE);p.edit().putInt("count:"+id,p.getInt("count:"+id,0)+1).putLong("last:"+id,System.currentTimeMillis()).apply();}
    static boolean isLocal(MediaItem item){return item!=null&&item.mediaId.matches("\\d+");}
}
