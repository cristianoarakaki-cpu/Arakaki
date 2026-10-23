package br.com.onda;

import android.media.*;
import java.io.*;
import java.nio.ByteBuffer;
import java.util.*;

/** Remux compatible AAC/H.264 tracks without re-encoding or degrading quality. */
final class DownloadMux {
 interface Cancel {void check()throws IOException;}
 static void merge(File first,File second,File output,boolean audioOnly,Cancel cancel)throws IOException {
  List<MediaExtractor> readers=new ArrayList<>();MediaMuxer mux=null;boolean started=false;
  try{
   mux=new MediaMuxer(output.getPath(),MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4);
   List<Map<Integer,Integer>> maps=new ArrayList<>();boolean audio=false,video=false;
   for(File file:new File[]{first,second}){
    if(file==null)continue;MediaExtractor ex=new MediaExtractor();readers.add(ex);ex.setDataSource(file.getPath());int chosen=-1;Map<Integer,Integer> map=new HashMap<>();maps.add(map);
    for(int i=0;i<ex.getTrackCount();i++){
     MediaFormat format=ex.getTrackFormat(i);String mime=format.getString(MediaFormat.KEY_MIME);
     boolean takeAudio="audio/mp4a-latm".equals(mime)&&!audio;
     boolean takeVideo="video/avc".equals(mime)&&!video&&!audioOnly;
     if(takeAudio||takeVideo){ex.selectTrack(i);map.put(i,mux.addTrack(format));chosen=i;if(takeAudio)audio=true;else video=true;}
    }
    if(chosen<0&&file==second)throw new IOException("Faixa de áudio incompatível");
   }
   if(!audio||(!audioOnly&&!video))throw new IOException("Arquivo sem áudio/vídeo AAC/H.264 compatível");
   cancel.check();mux.start();started=true;ByteBuffer buffer=ByteBuffer.allocateDirect(8*1024*1024);MediaCodec.BufferInfo info=new MediaCodec.BufferInfo();
   for(int reader=0;reader<readers.size();reader++){
    MediaExtractor ex=readers.get(reader);Map<Integer,Integer> mapping=maps.get(reader);
    while(true){cancel.check();buffer.clear();int size=ex.readSampleData(buffer,0);if(size<0)break;Integer target=mapping.get(ex.getSampleTrackIndex());if(target==null)throw new IOException("Faixa inesperada");info.set(0,size,Math.max(0,ex.getSampleTime()),(ex.getSampleFlags()&MediaExtractor.SAMPLE_FLAG_SYNC)!=0?MediaCodec.BUFFER_FLAG_KEY_FRAME:0);mux.writeSampleData(target,buffer,info);ex.advance();}
   }
   mux.stop();started=false;
  }catch(RuntimeException e){throw new IOException("Não foi possível montar o arquivo MP4/M4A.",e);}finally{for(MediaExtractor ex:readers)ex.release();if(mux!=null){if(started)try{mux.stop();}catch(Exception ignored){}try{mux.release();}catch(RuntimeException ignored){}}}
 }
}
