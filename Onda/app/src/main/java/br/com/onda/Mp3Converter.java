package br.com.onda;
import android.media.*;
import android.os.SystemClock;
import java.io.*;
import java.nio.*;

/** Decode AAC with Android, encode real MPEG Layer III locally with LAME. Bounded PCM buffers. */
final class Mp3Converter {
 static {System.loadLibrary("onda_mp3");}
 private static native long open(int rate,int channels,int bitrate)throws IOException;
 private static native int encode(long handle,short[] pcm,int frames,byte[] bytes,int channels)throws IOException;
 private static native int flush(long handle,byte[] bytes)throws IOException;
 private static native void close(long handle);
 static void convert(File source,File output,int bitrate,DownloadMux.Cancel cancel)throws IOException {
  MediaExtractor ex=new MediaExtractor();MediaCodec decoder=null;long encoder=0;boolean started=false;
  try(OutputStream out=new FileOutputStream(output)){
   ex.setDataSource(source.getPath());int track=-1;MediaFormat format=null;
   for(int i=0;i<ex.getTrackCount();i++)if("audio/mp4a-latm".equals(ex.getTrackFormat(i).getString(MediaFormat.KEY_MIME))){track=i;format=ex.getTrackFormat(i);break;}
   if(track<0)throw new IOException("Áudio AAC indisponível para converter");ex.selectTrack(track);
   format.setInteger(MediaFormat.KEY_PCM_ENCODING,AudioFormat.ENCODING_PCM_16BIT);decoder=MediaCodec.createDecoderByType("audio/mp4a-latm");decoder.configure(format,null,null,0);decoder.start();started=true;
   boolean inputEnd=false,outputEnd=false;int channels=0,rate=0;byte[] bytes=new byte[32768];short[] pcm=new short[32768];MediaCodec.BufferInfo info=new MediaCodec.BufferInfo();long last=SystemClock.elapsedRealtime();
   while(!outputEnd){cancel.check();if(SystemClock.elapsedRealtime()-last>30000)throw new IOException("O decodificador parou de responder");
    if(!inputEnd){int idx=decoder.dequeueInputBuffer(10000);if(idx>=0){ByteBuffer buffer=decoder.getInputBuffer(idx);if(buffer==null)throw new IOException("PCM indisponível");int n=ex.readSampleData(buffer,0);if(n<0){decoder.queueInputBuffer(idx,0,0,0,MediaCodec.BUFFER_FLAG_END_OF_STREAM);inputEnd=true;}else{decoder.queueInputBuffer(idx,0,n,ex.getSampleTime(),0);ex.advance();}}}
    int idx=decoder.dequeueOutputBuffer(info,10000);
    if(idx==MediaCodec.INFO_OUTPUT_FORMAT_CHANGED){if(encoder!=0)throw new IOException("Formato de áudio mudou durante a conversão");MediaFormat f=decoder.getOutputFormat();channels=f.getInteger(MediaFormat.KEY_CHANNEL_COUNT);rate=f.getInteger(MediaFormat.KEY_SAMPLE_RATE);if(f.containsKey(MediaFormat.KEY_PCM_ENCODING)&&f.getInteger(MediaFormat.KEY_PCM_ENCODING)!=AudioFormat.ENCODING_PCM_16BIT)throw new IOException("PCM de 16 bits necessário");encoder=open(rate,channels,bitrate);last=SystemClock.elapsedRealtime();}
    else if(idx>=0){last=SystemClock.elapsedRealtime();try{if(info.size>0){if(encoder==0)throw new IOException("Formato PCM não informado");ByteBuffer buffer=decoder.getOutputBuffer(idx);if(buffer==null||info.size%(2*channels)!=0)throw new IOException("Bloco PCM inválido");buffer.position(info.offset);buffer.limit(info.offset+info.size);buffer.order(ByteOrder.LITTLE_ENDIAN);ShortBuffer shorts=buffer.slice().order(ByteOrder.LITTLE_ENDIAN).asShortBuffer();while(shorts.hasRemaining()){cancel.check();int count=Math.min(shorts.remaining(),16384*channels);shorts.get(pcm,0,count);int n=encode(encoder,pcm,count/channels,bytes,channels);if(n>0)out.write(bytes,0,n);}}outputEnd=(info.flags&MediaCodec.BUFFER_FLAG_END_OF_STREAM)!=0;}finally{decoder.releaseOutputBuffer(idx,false);}}
   }
   cancel.check();if(encoder==0)throw new IOException("Nenhum áudio encontrado");int n=flush(encoder,bytes);if(n>0)out.write(bytes,0,n);
  }catch(RuntimeException e){throw new IOException("Não foi possível converter para MP3 neste aparelho",e);}finally{if(encoder!=0)close(encoder);if(decoder!=null){if(started)try{decoder.stop();}catch(RuntimeException ignored){}decoder.release();}ex.release();}
 }
}
