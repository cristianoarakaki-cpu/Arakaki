package br.com.onda;
import android.media.*;import java.io.*;import java.nio.*;
/** One codec track per temporary MP4, with explicit finalization and cancellation. */
final class PhotoCodecOutput implements AutoCloseable {
 final MediaMuxer mux;int track=-1;boolean started,ended;long lastPts=-1;
 PhotoCodecOutput(File output)throws IOException{mux=new MediaMuxer(output.getPath(),MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4);}
 boolean drain(MediaCodec codec,DownloadMux.Cancel cancel)throws IOException{cancel.check();MediaCodec.BufferInfo info=new MediaCodec.BufferInfo();int index=codec.dequeueOutputBuffer(info,10000);if(index==MediaCodec.INFO_OUTPUT_FORMAT_CHANGED){if(started)throw new IOException("O formato mudou durante a montagem");track=mux.addTrack(codec.getOutputFormat());mux.start();started=true;return true;}if(index<0)return false;try{if(info.size>0&&(info.flags&MediaCodec.BUFFER_FLAG_CODEC_CONFIG)==0){if(!started)throw new IOException("Formato de saída não informado");ByteBuffer data=codec.getOutputBuffer(index);if(data==null)throw new IOException("Saída do codec indisponível");info.presentationTimeUs=Math.max(lastPts+1,Math.max(0,info.presentationTimeUs));lastPts=info.presentationTimeUs;data.position(info.offset);data.limit(info.offset+info.size);mux.writeSampleData(track,data,info);}if((info.flags&MediaCodec.BUFFER_FLAG_END_OF_STREAM)!=0)ended=true;}finally{codec.releaseOutputBuffer(index,false);}return true;}
 void finish()throws IOException{if(!started||lastPts<0)throw new IOException("Nenhuma mídia foi produzida");mux.stop();started=false;}
 public void close(){if(started)try{mux.stop();}catch(RuntimeException ignored){}try{mux.release();}catch(RuntimeException ignored){}}
 static void release(MediaCodec codec){if(codec==null)return;try{codec.stop();}catch(RuntimeException ignored){}try{codec.release();}catch(RuntimeException ignored){}}
}
