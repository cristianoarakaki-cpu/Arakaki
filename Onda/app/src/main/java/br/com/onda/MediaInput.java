package br.com.onda;
import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.media.MediaExtractor;
import android.net.Uri;
import android.system.Os;
import android.system.OsConstants;
import java.io.*;

/** A seekable media source. Descriptors stay open only during an explicit conversion. */
interface MediaInput {
 void bind(MediaExtractor reader)throws IOException;
 static MediaInput file(File file){return reader->reader.setDataSource(file.getPath());}
 final class Direct implements MediaInput,AutoCloseable {
  private final AssetFileDescriptor descriptor;final long offset,length;
  Direct(AssetFileDescriptor descriptor,long offset,long length){this.descriptor=descriptor;this.offset=offset;this.length=length;}
  public void bind(MediaExtractor reader)throws IOException{if(length>=0)reader.setDataSource(descriptor.getFileDescriptor(),offset,length);else reader.setDataSource(descriptor.getFileDescriptor());}
  public void close()throws IOException{descriptor.close();}
 }
 static Direct open(Context context,Uri uri)throws IOException{String scheme=uri.getScheme();if(!"content".equals(scheme)&&!"file".equals(scheme))throw new IOException("Escolha um arquivo local pelo Android");AssetFileDescriptor descriptor;try{descriptor=context.getContentResolver().openAssetFileDescriptor(uri,"r");}catch(IOException|RuntimeException unavailable){return null;}return descriptor==null?null:take(descriptor);}
 /** Takes ownership, including on failure. Pipes use the existing streaming import fallback. */
 static Direct take(AssetFileDescriptor descriptor){boolean kept=false;MediaExtractor reader=null;try{Os.lseek(descriptor.getFileDescriptor(),0,OsConstants.SEEK_CUR);long offset=descriptor.getStartOffset(),length=descriptor.getDeclaredLength();if(offset<0)return null;if(length<0){long stat=descriptor.getParcelFileDescriptor().getStatSize();if(stat>=offset)length=stat-offset;else if(offset!=0)return null;}Direct direct=new Direct(descriptor,offset,length);reader=new MediaExtractor();direct.bind(reader);if(reader.getTrackCount()==0)return null;kept=true;return direct;}catch(Exception unavailable){return null;}finally{if(reader!=null)reader.release();if(!kept)try{descriptor.close();}catch(IOException ignored){}}}
}
