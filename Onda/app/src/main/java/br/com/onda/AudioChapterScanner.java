package br.com.onda;

import android.content.Context;
import android.media.*;
import android.net.Uri;
import android.os.SystemClock;
import java.io.*;
import java.nio.*;
import java.util.*;

/** Decode on explicit request, constant-size PCM windows; no encoder, copy, network client or service. */
final class AudioChapterScanner {
    interface Control {void check()throws IOException;void progress(long position,long duration);}
    static final class Result {final long duration;final List<Long> starts;Result(long duration,List<Long> starts){this.duration=duration;this.starts=starts;}}
    private static final class Energy {
        final SilenceChapters detector=new SilenceChapters();int rate,channels,frames;long windowStartUs,endUs;double squares;boolean initialized;
        void format(MediaFormat f)throws IOException{int nextRate=f.getInteger(MediaFormat.KEY_SAMPLE_RATE),nextChannels=f.getInteger(MediaFormat.KEY_CHANNEL_COUNT);if(nextRate<8000||nextRate>192000||nextChannels<1||nextChannels>2||(f.containsKey(MediaFormat.KEY_PCM_ENCODING)&&f.getInteger(MediaFormat.KEY_PCM_ENCODING)!=AudioFormat.ENCODING_PCM_16BIT))throw new IOException("O áudio não tem um formato compatível com a análise neste aparelho.");if(rate!=0&&(rate!=nextRate||channels!=nextChannels))throw new IOException("O formato mudou durante a análise.");rate=nextRate;channels=nextChannels;}
        void samples(ByteBuffer buffer,int offset,int size,long timestampUs)throws IOException{if(rate==0||size%(2*channels)!=0)throw new IOException("Bloco de áudio inválido.");ByteBuffer pcm=buffer.duplicate().order(ByteOrder.LITTLE_ENDIAN);pcm.position(offset);pcm.limit(offset+size);long base=Math.max(endUs,Math.max(0,timestampUs));if(initialized&&base-endUs>250000)flush();int read=0;while(pcm.remaining()>=2*channels){if(!initialized){windowStartUs=base+read*1000000L/rate;initialized=true;}for(int ch=0;ch<channels;ch++){double sample=pcm.getShort()/32768.0;squares+=sample*sample;}frames++;read++;endUs=base+read*1000000L/rate;if(frames>=rate/10){flush();}}}
        void flush(){if(frames==0)return;long start=windowStartUs/1000,length=Math.max(1,(frames*1000L)/rate);detector.window(start,length,squares/(frames*(double)channels));frames=0;squares=0;initialized=false;}
        Result result(long declared){flush();long end=Math.max(endUs/1000,declared);if(end<=0)end=1;return new Result(end,detector.finish(end));}
    }
    static Result scan(Context context,Uri uri,Control control)throws IOException{
        MediaInput.Direct source=MediaInput.open(context,uri);if(source==null)throw new IOException("Não foi possível abrir um áudio local com busca. Disponibilize o arquivo no celular primeiro.");
        MediaExtractor extractor=new MediaExtractor();MediaCodec decoder=null;boolean started=false;Energy energy=new Energy();long declared=0,lastProgress=0;
        try(MediaInput.Direct ignored=source){
            control.check();source.bind(extractor);int track=AudioTracks.select(extractor);MediaFormat format=extractor.getTrackFormat(track);extractor.selectTrack(track);if(format.containsKey(MediaFormat.KEY_DURATION))declared=Math.max(0,format.getLong(MediaFormat.KEY_DURATION)/1000);
            if("audio/raw".equals(format.getString(MediaFormat.KEY_MIME))){energy.format(format);ByteBuffer raw=ByteBuffer.allocate(65536);while(true){control.check();raw.clear();int size=extractor.readSampleData(raw,0);if(size<0)break;if((extractor.getSampleFlags()&MediaExtractor.SAMPLE_FLAG_ENCRYPTED)!=0)throw new IOException("Áudio protegido não é analisado.");energy.samples(raw,0,size,extractor.getSampleTime());extractor.advance();long now=SystemClock.elapsedRealtime();if(now-lastProgress>=750){lastProgress=now;control.progress(energy.endUs/1000,declared);}}
            }else{
                format.setInteger(MediaFormat.KEY_PCM_ENCODING,AudioFormat.ENCODING_PCM_16BIT);decoder=MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME));decoder.configure(format,null,null,0);decoder.start();started=true;boolean inputEnd=false,outputEnd=false;MediaCodec.BufferInfo info=new MediaCodec.BufferInfo();long lastOutput=SystemClock.elapsedRealtime();
                while(!outputEnd){control.check();if(SystemClock.elapsedRealtime()-lastOutput>30000)throw new IOException("O decodificador parou de responder.");if(!inputEnd){int index=decoder.dequeueInputBuffer(10000);if(index>=0){ByteBuffer buffer=decoder.getInputBuffer(index);if(buffer==null)throw new IOException("Entrada de áudio indisponível.");int size=extractor.readSampleData(buffer,0);if(size<0){decoder.queueInputBuffer(index,0,0,0,MediaCodec.BUFFER_FLAG_END_OF_STREAM);inputEnd=true;}else{if((extractor.getSampleFlags()&MediaExtractor.SAMPLE_FLAG_ENCRYPTED)!=0)throw new IOException("Áudio protegido não é analisado.");decoder.queueInputBuffer(index,0,size,extractor.getSampleTime(),0);extractor.advance();}}}int index=decoder.dequeueOutputBuffer(info,10000);if(index==MediaCodec.INFO_OUTPUT_FORMAT_CHANGED){energy.format(decoder.getOutputFormat());lastOutput=SystemClock.elapsedRealtime();}else if(index>=0){lastOutput=SystemClock.elapsedRealtime();try{if(info.size>0){ByteBuffer buffer=decoder.getOutputBuffer(index);if(buffer==null)throw new IOException("Saída de áudio indisponível.");energy.samples(buffer,info.offset,info.size,info.presentationTimeUs);}outputEnd=(info.flags&MediaCodec.BUFFER_FLAG_END_OF_STREAM)!=0;}finally{decoder.releaseOutputBuffer(index,false);}}long now=SystemClock.elapsedRealtime();if(now-lastProgress>=750){lastProgress=now;control.progress(energy.endUs/1000,declared);}}
            }
            control.check();Result result=energy.result(declared);control.progress(result.duration,result.duration);return result;
        }catch(RuntimeException error){throw new IOException("Não foi possível analisar este áudio no aparelho.",error);}finally{if(decoder!=null){if(started)try{decoder.stop();}catch(RuntimeException ignored){}decoder.release();}extractor.release();}
    }
}
