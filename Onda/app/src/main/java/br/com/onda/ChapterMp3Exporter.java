package br.com.onda;

import android.media.*;
import android.os.SystemClock;
import java.io.*;
import java.nio.*;

/** Decodes only the requested range, with bounded PCM buffers and no full-file WAV copy. */
final class ChapterMp3Exporter {
    interface Control extends DownloadMux.Cancel {void progress(long position,long duration);}
    static void convert(MediaInput source,File output,int bitrate,long startMs,long endMs,Control control)throws IOException {
        convert(source,output,bitrate,startMs,endMs,0,control);
    }
    interface PcmSink {
        void write(short[] samples,int count,int rate,int channels)throws IOException;
    }
    static void convert(MediaInput source,File output,int bitrate,long startMs,long endMs,int profile,Control control)throws IOException {
        try(OutputStream out=new BufferedOutputStream(new FileOutputStream(output),65536)){
            decode(source,out,bitrate,startMs,endMs,profile,control,null);
        }
    }
    static void pcm(MediaInput source,long startMs,long endMs,Control control,PcmSink sink)throws IOException {
        decode(source,null,0,startMs,endMs,0,control,sink);
    }
    private static void decode(MediaInput source,OutputStream out,int bitrate,long startMs,long endMs,int profile,Control control,PcmSink sink)throws IOException {
        if(!RestorationDsp.valid(profile))throw new IOException("Perfil inválido");
        if(startMs<0||endMs<=startMs||endMs>Long.MAX_VALUE/1000)throw new IOException("Limites da faixa inválidos");
        long from=startMs*1000,to=endMs*1000;MediaExtractor extractor=new MediaExtractor();MediaCodec decoder=null;boolean started=false;
        try{
            source.bind(extractor);int track=AudioTracks.select(extractor);MediaFormat input=extractor.getTrackFormat(track);extractor.selectTrack(track);extractor.seekTo(from,MediaExtractor.SEEK_TO_PREVIOUS_SYNC);
            String mime=input.getString(MediaFormat.KEY_MIME);
            try(Crop crop=new Crop(out,bitrate,from,to,profile,control,sink)){
                if("audio/raw".equals(mime)){
                    crop.format(input);ByteBuffer buffer=ByteBuffer.allocate(65536);
                    while(true){control.check();buffer.clear();int size=extractor.readSampleData(buffer,0);if(size<0)break;if(size>buffer.capacity())throw new IOException("Bloco PCM muito grande");if((extractor.getSampleFlags()&MediaExtractor.SAMPLE_FLAG_ENCRYPTED)!=0)throw new IOException("Áudio protegido não é convertido");long time=extractor.getSampleTime();buffer.position(0);buffer.limit(size);if(crop.write(buffer,time))break;extractor.advance();}
                }else{
                    input.setInteger(MediaFormat.KEY_PCM_ENCODING,AudioFormat.ENCODING_PCM_16BIT);decoder=MediaCodec.createDecoderByType(mime);decoder.configure(input,null,null,0);decoder.start();started=true;
                    boolean inputEnd=false,done=false;MediaCodec.BufferInfo info=new MediaCodec.BufferInfo();long last=SystemClock.elapsedRealtime();
                    while(!done){control.check();if(SystemClock.elapsedRealtime()-last>30000)throw new IOException("O decodificador parou de responder");
                        if(!inputEnd){int index=decoder.dequeueInputBuffer(10000);if(index>=0){ByteBuffer buffer=decoder.getInputBuffer(index);if(buffer==null)throw new IOException("Entrada de áudio indisponível");buffer.clear();int size=extractor.readSampleData(buffer,0);if(size<0){decoder.queueInputBuffer(index,0,0,0,MediaCodec.BUFFER_FLAG_END_OF_STREAM);inputEnd=true;}else{if((extractor.getSampleFlags()&MediaExtractor.SAMPLE_FLAG_ENCRYPTED)!=0)throw new IOException("Áudio protegido não é convertido");decoder.queueInputBuffer(index,0,size,extractor.getSampleTime(),0);extractor.advance();}}}
                        int index=decoder.dequeueOutputBuffer(info,10000);
                        if(index==MediaCodec.INFO_OUTPUT_FORMAT_CHANGED){crop.format(decoder.getOutputFormat());last=SystemClock.elapsedRealtime();}
                        else if(index>=0){last=SystemClock.elapsedRealtime();try{if(info.size>0){ByteBuffer buffer=decoder.getOutputBuffer(index);if(buffer==null)throw new IOException("Saída de áudio indisponível");buffer.position(info.offset);buffer.limit(info.offset+info.size);done=crop.write(buffer.slice(),info.presentationTimeUs);}done|=(info.flags&MediaCodec.BUFFER_FLAG_END_OF_STREAM)!=0;}finally{decoder.releaseOutputBuffer(index,false);}}
                    }
                }
                control.check();crop.finish();
            }
        }catch(RuntimeException error){throw new IOException("Não foi possível salvar esta faixa em MP3",error);}finally{if(decoder!=null){if(started)try{decoder.stop();}catch(RuntimeException ignored){}decoder.release();}extractor.release();}
    }
    private static final class Crop implements AutoCloseable {
        private final OutputStream out;private final int bitrate;private final long from,to;private final Control control;
        private final PcmSink sink;private RestorationDsp restoration;private final int profile;
        private Mp3Converter.Encoder encoder;private int rate,channels;private long frames,lastProgress;
        private final short[] samples=new short[32768];
        Crop(OutputStream out,int bitrate,long from,long to,int profile,Control control,PcmSink sink){this.sink=sink;this.profile=profile;this.out=out;this.bitrate=bitrate;this.from=from;this.to=to;this.control=control;}
        void format(MediaFormat format)throws IOException{
            int nextRate=format.getInteger(MediaFormat.KEY_SAMPLE_RATE),nextChannels=format.getInteger(MediaFormat.KEY_CHANNEL_COUNT);
            if(format.containsKey(MediaFormat.KEY_PCM_ENCODING)&&format.getInteger(MediaFormat.KEY_PCM_ENCODING)!=AudioFormat.ENCODING_PCM_16BIT)throw new IOException("PCM de 16 bits necessário");
            if(rate!=0){if(rate!=nextRate||channels!=nextChannels)throw new IOException("Formato de áudio mudou durante a faixa");return;}
            rate=nextRate;channels=nextChannels;if(rate<=0||channels<1||channels>2)throw new IOException("Escolha áudio mono ou estéreo");if(profile>0)restoration=new RestorationDsp(rate,channels,profile);if(sink==null)encoder=new Mp3Converter.Encoder(out,rate,channels,bitrate);
        }
        boolean write(ByteBuffer buffer,long timestamp)throws IOException{
            if(rate==0||buffer.remaining()%(channels*2)!=0)throw new IOException("Bloco PCM inválido");
            int total=buffer.remaining()/(channels*2);
            int skip=(int)Math.min(total,ceilFrames(Math.max(0,from-timestamp),rate));
            int until=(int)Math.min(total,ceilFrames(Math.max(0,to-timestamp),rate));
            if(until>skip){buffer.position(buffer.position()+skip*channels*2);buffer.limit(buffer.position()+(until-skip)*channels*2);ShortBuffer pcm=buffer.slice().order(ByteOrder.LITTLE_ENDIAN).asShortBuffer();while(pcm.hasRemaining()){control.check();int count=Math.min(pcm.remaining(),4096*channels);count-=count%channels;pcm.get(samples,0,count);if(restoration!=null)restoration.process(samples,count);if(sink==null)encoder.write(samples,count/channels);else sink.write(samples,count,rate,channels);frames+=count/channels;}}
            long now=SystemClock.elapsedRealtime();if(now-lastProgress>=750){lastProgress=now;control.progress(Math.max(0,Math.min(to-from,timestamp-from))/1000,(to-from)/1000);}
            return timestamp>=to||until<total;
        }
        private static long ceilFrames(long us,int rate){return us/1000000*rate+(us%1000000*rate+999999)/1000000;}
        void finish()throws IOException{if(frames==0)throw new IOException("Nenhum áudio encontrado neste trecho");if(frames*1000/rate+250<(to-from)/1000)throw new IOException("O arquivo terminou antes do fim da faixa. Confira os horários.");if(encoder!=null)encoder.finish();control.progress((to-from)/1000,(to-from)/1000);}
        public void close(){if(encoder!=null)encoder.close();}
    }
}
