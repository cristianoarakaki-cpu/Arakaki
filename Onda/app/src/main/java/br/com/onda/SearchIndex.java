package br.com.onda;
import android.content.*;
import android.database.Cursor;
import android.net.Uri;
import android.provider.MediaStore;
import androidx.media3.common.MediaItem;
import java.util.*;
@androidx.media3.common.util.UnstableApi
final class SearchIndex {
 static final class Result {final List<UnifiedSearch.Entry> entries=new ArrayList<>();boolean audioMissing,videoMissing;}
 static Result load(Context c){
  Result result=new Result();Set<String> favorites=c.getSharedPreferences("library",0).getStringSet("favorites",Collections.emptySet());
  scan(c,MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,"audio",favorites,result);
  scan(c,MediaStore.Video.Media.EXTERNAL_CONTENT_URI,"video",favorites,result);
  for(MediaItem item:DownloadedAudio.read(c)){if(result.entries.size()>=20200||Thread.currentThread().isInterrupted())break;if(item.localConfiguration==null)continue;UnifiedSearch.Entry e=new UnifiedSearch.Entry(item.mediaId,"audio",item.localConfiguration.uri.toString(),String.valueOf(item.mediaMetadata.title),String.valueOf(item.mediaMetadata.artist));e.favorite=favorites.contains(item.mediaId);result.entries.add(e);}
  MediaShelf shelf=ShelfStore.read(c);
  for(MediaShelf.Item item:shelf.items.values()){
   UnifiedSearch.Entry e=new UnifiedSearch.Entry(item.id,item.type,item.uri,item.title,"");e.position=item.position;e.seen=item.seen;e.favorite=item.type.equals("audio")&&favorites.contains(DownloadedAudio.id(item.uri));result.entries.add(e);
   for(MediaShelf.Note n:item.notes){UnifiedSearch.Entry note=new UnifiedSearch.Entry(n.id,"note",item.uri,item.title,n.text);note.note=n.text;note.targetType=item.type;note.position=n.at;result.entries.add(note);}
  }
  for(MediaShelf.Collection collection:shelf.collections.values()){UnifiedSearch.Entry e=new UnifiedSearch.Entry(collection.id,"collection","",collection.name,collection.items.size()+" arquivos");e.collection=collection.id;result.entries.add(e);}
  SharedPreferences pdf=c.getSharedPreferences("pdf_reading",0);String uri=pdf.getString("uri","");if(MediaShelf.source("pdf",uri)){UnifiedSearch.Entry e=new UnifiedSearch.Entry("lastpdf","pdf",uri,pdf.getString("name","PDF"),"");e.position=pdf.getInt("page",0);result.entries.add(e);}
  List<UnifiedSearch.Entry> merged=UnifiedSearch.merge(result.entries);result.entries.clear();result.entries.addAll(merged);return result;
 }
 private static void scan(Context c,Uri uri,String type,Set<String> favorites,Result result){
  boolean audio=type.equals("audio");String[] columns=audio?new String[]{"_id","title","_display_name","artist","album"}:new String[]{"_id","title","_display_name"};
  try(Cursor cursor=c.getContentResolver().query(uri,columns,null,null,"_id DESC")){
   if(cursor==null)return;int count=0;while(count++<10000&&cursor.moveToNext()&&!Thread.currentThread().isInterrupted()){
    String id=cursor.getString(0),title=cursor.getString(1),file=cursor.getString(2);if(title==null||title.trim().isEmpty())title=file==null?"Arquivo local":file;String detail=audio?String.valueOf(cursor.getString(3))+" • "+String.valueOf(cursor.getString(4))+" • "+file:String.valueOf(file);
    UnifiedSearch.Entry e=new UnifiedSearch.Entry(id,type,ContentUris.withAppendedId(uri,Long.parseLong(id)).toString(),title,detail);e.favorite=audio&&favorites.contains(id);result.entries.add(e);
   }
  }catch(RuntimeException denied){if(audio)result.audioMissing=true;else result.videoMissing=true;}
 }
}
