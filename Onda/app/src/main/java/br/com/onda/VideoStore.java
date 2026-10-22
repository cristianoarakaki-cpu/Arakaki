package br.com.onda;
import android.content.*;
import android.database.Cursor;
import android.net.Uri;
import android.provider.MediaStore;
import java.util.*;
final class VideoStore {
    static final class Item {
        final Uri uri;final String title,file;final long duration,size;
        Item(Uri uri,String title,String file,long duration,long size){this.uri=uri;this.title=title;this.file=file;this.duration=duration;this.size=size;}
    }
    static List<Item> scan(Context context){
        List<Item> found=new ArrayList<>();
        try(Cursor c=context.getContentResolver().query(MediaStore.Video.Media.EXTERNAL_CONTENT_URI,new String[]{"_id","title","_display_name","duration","_size"},null,null,"_display_name COLLATE NOCASE ASC")){
            if(c!=null)while(c.moveToNext()){
                if(Thread.currentThread().isInterrupted())break;
                String file=c.getString(2),title=c.getString(1);if(file==null)file="Vídeo";if(title==null||title.trim().isEmpty())title=file;
                found.add(new Item(ContentUris.withAppendedId(MediaStore.Video.Media.EXTERNAL_CONTENT_URI,c.getLong(0)),title,file,c.getLong(3),c.getLong(4)));
            }
        }
        return found;
    }
}
