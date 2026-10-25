package br.com.onda;
import android.content.*;
import android.database.Cursor;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.os.*;
import android.provider.*;
import androidx.media3.common.*;

/** Reads only the document explicitly granted by a file manager. Call off the UI thread. */
@androidx.media3.common.util.UnstableApi
final class ExternalAudio {
 static MediaItem read(Context c,Uri uri,String supplied)throws Exception{
  String title=uri.getLastPathSegment(),artist="Áudio local",album="",mime=supplied;long duration=0,size=0;
  try(Cursor cursor=c.getContentResolver().query(uri,new String[]{OpenableColumns.DISPLAY_NAME,OpenableColumns.SIZE},null,null,null)){if(cursor!=null&&cursor.moveToFirst()){title=cursor.getString(0);size=cursor.getLong(1);}}catch(RuntimeException ignored){}
  // Check the read grant before storing an inaccessible favorite/library entry.
  try(ParcelFileDescriptor fd=c.getContentResolver().openFileDescriptor(uri,"r")){if(fd==null)throw new java.io.IOException("Arquivo indisponível");}
  MediaMetadataRetriever reader=new MediaMetadataRetriever();try{reader.setDataSource(c,uri);String name=reader.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE),author=reader.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST),record=reader.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM),length=reader.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION);if(name!=null&&!name.trim().isEmpty())title=name;if(author!=null&&!author.trim().isEmpty())artist=author;if(record!=null)album=record;if(length!=null)duration=Long.parseLong(length);}catch(RuntimeException ignored){}finally{reader.release();}
  if(title==null||title.isEmpty())title="Áudio selecionado";if(mime==null||!mime.startsWith("audio/"))mime="audio/ogg";
  Uri canonical=uri;if(Build.VERSION.SDK_INT>=29&&"content".equals(uri.getScheme()))try{String authority=uri.getAuthority();if("com.android.providers.media.documents".equals(authority)||"com.android.externalstorage.documents".equals(authority)||"com.android.providers.downloads.documents".equals(authority)){Uri mapped=MediaStore.getMediaUri(c,uri);if(mapped!=null)canonical=mapped;}}catch(RuntimeException ignored){}
  String id=DownloadedAudio.id(uri.toString());if("media".equals(canonical.getAuthority())&&canonical.getPath()!=null&&canonical.getPath().matches("/(external|external_primary|internal)/audio/media/[0-9]+"))id=canonical.getLastPathSegment();else DownloadedAudio.remember(c,uri.toString(),title,mime);
  Bundle extras=new Bundle();extras.putLong("durationMs",duration);extras.putLong("size",size);
  return new MediaItem.Builder().setUri(uri).setMediaId(id).setMimeType(mime).setMediaMetadata(new MediaMetadata.Builder().setTitle(title).setArtist(artist).setAlbumTitle(album).setExtras(extras).build()).build();
 }
}
