package br.com.onda;

import android.content.Context;
import android.media.*;
import android.net.Uri;
import android.os.SystemClock;
import java.io.*;
import java.nio.*;
import java.util.*;

/** Decode on explicit request, constant-size PCM windows; no encoder, copy, network client or service. */
@androidx.media3.common.util.UnstableApi
final class MemoryAudio {
    interface Recognizer extends AutoCloseable {String recognize(float[] pcm)throws IOException;void cancel();void close();}
    interface Factory {Recognizer open(Context c)throws Exception;}
    static volatile Factory factory=context->{File model=LiveSpeechModels.verified(context,LiveSpeechModels.Model.BASE,()->Thread.currentThread().isInterrupted());if(!LiveSpeechModels.installed(context,LiveSpeechModels.Model.BASE))throw new IOException("Prepare o modelo de voz antes de transcrever.");android.app.ActivityManager.MemoryInfo info=new android.app.ActivityManager.MemoryInfo();((android.app.ActivityManager)context.getSystemService(Context.ACTIVITY_SERVICE)).getMemoryInfo(info);if(info.lowMemory||info.availMem<256L*1024*1024)throw new IOException("Memória insuficiente agora. Feche outros aplicativos ou use legendas prontas.");WhisperEngine engine=new WhisperEngine(model);return new Recognizer(){public String recognize(float[] pcm)throws IOException{return engine.recognize(pcm,"auto",2);}public void cancel(){engine.cancel();}public void close(){engine.close();}};};
    static volatile Recognizer active;
    private static final class Energy {
        final Recognizer recognizer;final MemoryStore.Writer writer;final MemoryIndexer.Control control;int rate,channels,count;long inputFrames,endUs,startUs;double next;float[] pcm=new float[320000];
        Energy(Recognizer r,MemoryStore.Writer w,MemoryIndexer.Control c){recognizer=r;writer=w;control=c;}
        void format(MediaFormat f)throws IOException{int r=f.getInteger(MediaFormat.KEY_SAMPLE_RATE),ch=f.getInteger(MediaFormat.KEY_CHANNEL_COUNT);if(r<8000||r>192000||ch<1||ch>8||(f.containsKey(MediaFormat.KEY_PCM_ENCODING)&&f.getInteger(MediaFormat.KEY_PCM_ENCODING)!=AudioFormat.ENCODING_PCM_16BIT))throw new IOException("PCM incompatível com reconhecimento neste aparelho.");if(rate!=0&&(rate!=r||channels!=ch))throw new IOException("O formato de áudio mudou.");rate=r;channels=ch;}
        void samples(ByteBuffer buffer,int offset,int size,long timestampUs)throws IOException{if(rate==0||size%(2*channels)!=0)throw new IOException("PCM inválido");ByteBuffer data=buffer.duplicate().order(ByteOrder.LITTLE_ENDIAN);data.position(offset);data.limit(offset+size);int local=0;while(data.remaining()>=channels*2){if((local&4095)==0)control.check();float value=0;for(int ch=0;ch<channels;ch++)value+=data.getShort()/(32768f*channels);long now=Math.max(0,timestampUs)+local*1000000L/rate;while(next<=inputFrames){if(count==0)startUs=now;pcm[count++]=value;next+=rate/16000.0;endUs=now+1000000L/rate;if(count==pcm.length)flush();}inputFrames++;local++;}}
        void flush()throws IOException{if(count==0)return;control.check();float[] audio=java.util.Arrays.copyOf(pcm,count);count=0;if(LivePcmWindow.audible(audio)){String text=recognizer.recognize(audio.length<16000?java.util.Arrays.copyOf(audio,16000):audio);control.check();if(LiveRecognizer.recognizable(text))for(String part:MemoryText.chunks(text))writer.add(new MemoryText.Cue(startUs/1000,Math.max(startUs/1000+1,endUs/1000),-1,part));}}
    }
    static void scan(Context context,Uri uri,MemoryStore.Writer writer,MemoryIndexer.Control control)throws Exception{
        try(Recognizer recognizer=factory.open(context)){active=recognizer;try{decode(context,uri,writer,control,recognizer);}finally{active=null;}}
    }
    private static void decode(Context context,Uri uri,MemoryStore.Writer writer,MemoryIndexer.Control control,Recognizer recognizer)throws IOException{
        MediaInput.Direct source=MediaInput.open(context,uri);if(source==null)throw new IOException("Não foi possível abrir um áudio local com busca. Disponibilize o arquivo no celular primeiro.");
        MediaExtractor extractor=new MediaExtractor();MediaCodec decoder=null;boolean started=false;Energy energy=new Energy(recognizer,writer,control);long declared=0,lastProgress=0;
        try(MediaInput.Direct ignored=source){
            control.check();source.bind(extractor);int track=AudioTracks.select(extractor);MediaFormat format=extractor.getTrackFormat(track);extractor.selectTrack(track);if(format.containsKey(MediaFormat.KEY_DURATION))declared=Math.max(0,format.getLong(MediaFormat.KEY_DURATION)/1000);
            if("audio/raw".equals(format.getString(MediaFormat.KEY_MIME))){energy.format(format);ByteBuffer raw=ByteBuffer.allocate(65536);while(true){control.check();raw.clear();int size=extractor.readSampleData(raw,0);if(size<0)break;if((extractor.getSampleFlags()&MediaExtractor.SAMPLE_FLAG_ENCRYPTED)!=0)throw new IOException("Áudio protegido não é analisado.");energy.samples(raw,0,size,extractor.getSampleTime());extractor.advance();long now=SystemClock.elapsedRealtime();if(now-lastProgress>=750){lastProgress=now;control.progress("Transcrevendo fala • horários aproximados",energy.endUs/1000,declared);}}
            }else{
                format.setInteger(MediaFormat.KEY_PCM_ENCODING,AudioFormat.ENCODING_PCM_16BIT);decoder=MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME));decoder.configure(format,null,null,0);decoder.start();started=true;boolean inputEnd=false,outputEnd=false;MediaCodec.BufferInfo info=new MediaCodec.BufferInfo();long lastOutput=SystemClock.elapsedRealtime();
                while(!outputEnd){control.check();if(SystemClock.elapsedRealtime()-lastOutput>30000)throw new IOException("O decodificador parou de responder.");if(!inputEnd){int index=decoder.dequeueInputBuffer(10000);if(index>=0){ByteBuffer buffer=decoder.getInputBuffer(index);if(buffer==null)throw new IOException("Entrada de áudio indisponível.");int size=extractor.readSampleData(buffer,0);if(size<0){decoder.queueInputBuffer(index,0,0,0,MediaCodec.BUFFER_FLAG_END_OF_STREAM);inputEnd=true;}else{if((extractor.getSampleFlags()&MediaExtractor.SAMPLE_FLAG_ENCRYPTED)!=0)throw new IOException("Áudio protegido não é analisado.");decoder.queueInputBuffer(index,0,size,extractor.getSampleTime(),0);extractor.advance();}}}int index=decoder.dequeueOutputBuffer(info,10000);if(index==MediaCodec.INFO_OUTPUT_FORMAT_CHANGED){energy.format(decoder.getOutputFormat());lastOutput=SystemClock.elapsedRealtime();}else if(index>=0){lastOutput=SystemClock.elapsedRealtime();try{if(info.size>0){ByteBuffer buffer=decoder.getOutputBuffer(index);if(buffer==null)throw new IOException("Saída de áudio indisponível.");energy.samples(buffer,info.offset,info.size,info.presentationTimeUs);lastOutput=SystemClock.elapsedRealtime();}outputEnd=(info.flags&MediaCodec.BUFFER_FLAG_END_OF_STREAM)!=0;}finally{decoder.releaseOutputBuffer(index,false);}}long now=SystemClock.elapsedRealtime();if(now-lastProgress>=750){lastProgress=now;control.progress("Transcrevendo fala • horários aproximados",energy.endUs/1000,declared);}}
            }
            control.check();energy.flush();control.progress("Transcrição concluída",declared,declared);
        }catch(RuntimeException error){throw new IOException("Não foi possível analisar este áudio no aparelho.",error);}finally{if(decoder!=null){if(started)try{decoder.stop();}catch(RuntimeException ignored){}decoder.release();}extractor.release();}
    }
}
