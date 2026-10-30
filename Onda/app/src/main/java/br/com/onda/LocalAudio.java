package br.com.onda;
import android.content.Context;
import android.media.*;
import android.net.Uri;
import java.io.*;

/** Local audio extraction/conversion, with originals left untouched. */
final class LocalAudio {
 static final long MAX=512L*1024*1024;
 static String inspect(Context c,Uri uri)throws IOException{if(!"content".equals(uri.getScheme())&&!"file".equals(uri.getScheme()))throw new IOException("Escolha um arquivo do celular pelo Android.");MediaExtractor ex=new MediaExtractor();try{ex.setDataSource(c,uri,null);return describe(ex);}catch(RuntimeException e){throw new IOException("Não foi possível ler o áudio. Se o arquivo estiver na nuvem, disponibilize-o no celular primeiro.",e);}finally{ex.release();}}
 static String describe(MediaExtractor ex)throws IOException{MediaFormat f=ex.getTrackFormat(AudioTracks.select(ex));long seconds=f.containsKey(MediaFormat.KEY_DURATION)?Math.max(0,f.getLong(MediaFormat.KEY_DURATION)/1000000):0;return f.getString(MediaFormat.KEY_MIME)+" • "+f.getInteger(MediaFormat.KEY_SAMPLE_RATE)+" Hz • "+f.getInteger(MediaFormat.KEY_CHANNEL_COUNT)+" canal(is)"+(seconds>0?" • "+seconds/60+":"+String.format(java.util.Locale.ROOT,"%02d",seconds%60):"");}
 static boolean canExtractAac(Context c,Uri uri){MediaExtractor ex=new MediaExtractor();try{ex.setDataSource(c,uri,null);return AudioTracks.aac(ex.getTrackFormat(AudioTracks.select(ex)));}catch(Exception e){return false;}finally{ex.release();}}
 interface Progress {void bytes(long count)throws IOException;}
 static void importFile(Context c,Uri uri,File target,DownloadMux.Cancel cancel,Progress progress)throws IOException{if(!"content".equals(uri.getScheme())&&!"file".equals(uri.getScheme()))throw new IOException("Arquivo local inválido");try(InputStream in=c.getContentResolver().openInputStream(uri);OutputStream out=new FileOutputStream(target)){if(in==null)throw new IOException("Arquivo indisponível");byte[] b=new byte[65536];long count=0;int n;while((n=in.read(b))!=-1){cancel.check();count+=n;if(count>MAX)throw new IOException("Arquivo excede 512 MB");out.write(b,0,n);progress.bytes(count);}if(count==0)throw new IOException("Arquivo vazio");}}
 static void convert(File source,File output,String format,DownloadMux.Cancel cancel)throws IOException{convert(source,output,format,192,cancel);}
 static void convert(File source,File output,String format,int bitrate,DownloadMux.Cancel cancel)throws IOException{if(source.equals(output))throw new IOException("O destino deve ser outro arquivo");MediaExtractor ex=new MediaExtractor();try{ex.setDataSource(source.getPath());describe(ex);}finally{ex.release();}cancel.check();if("mp3".equals(format))try{Mp3Converter.convert(source,output,bitrate,cancel);}catch(LinkageError e){throw new IOException("Conversor MP3 indisponível neste aparelho",e);}else if("m4a".equals(format))DownloadMux.merge(source,null,output,true,cancel);else throw new IOException("Escolha MP3 ou M4A");if(output.length()==0||output.length()>MAX)throw new IOException("Saída vazia ou maior que 512 MB");cancel.check();}
}
