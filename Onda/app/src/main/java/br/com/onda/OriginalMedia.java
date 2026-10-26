package br.com.onda;
import android.media.MediaExtractor;
import android.media.MediaFormat;
import java.io.*;
/** Validate actual tracks before preserving a direct file; never save a login HTML page as media. */
final class OriginalMedia {
 static void copy(File source,File target,String extension,DownloadMux.Cancel cancel)throws IOException{cancel.check();MediaExtractor extractor=new MediaExtractor();boolean audio=false,video=false,mp3=false;try{extractor.setDataSource(source.getPath());for(int i=0;i<extractor.getTrackCount();i++){String mime=extractor.getTrackFormat(i).getString(MediaFormat.KEY_MIME);audio|=mime!=null&&mime.startsWith("audio/");video|=mime!=null&&mime.startsWith("video/");mp3|="audio/mpeg".equals(mime);}if(extension.equals("mp3")?!mp3:extension.equals("m4a")?(!audio||video):!video)throw new IOException("O arquivo recebido não contém faixas compatíveis com "+extension.toUpperCase(java.util.Locale.ROOT)+".");}catch(RuntimeException e){throw new IOException("O servidor não entregou um arquivo de mídia válido.",e);}finally{extractor.release();}try(InputStream in=new FileInputStream(source);OutputStream out=new FileOutputStream(target)){byte[] buffer=new byte[65536];int n;while((n=in.read(buffer))!=-1){cancel.check();out.write(buffer,0,n);}}cancel.check();}
}
