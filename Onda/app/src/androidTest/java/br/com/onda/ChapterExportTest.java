package br.com.onda;
import android.media.*;import android.net.Uri;import java.io.*;import java.nio.*;
import org.junit.Test;import static org.junit.Assert.*;import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
public class ChapterExportTest {
    private final android.content.Context c=getInstrumentation().getTargetContext();
    private ChapterMp3Exporter.Control control(){return new ChapterMp3Exporter.Control(){public void check()throws IOException{if(Thread.currentThread().isInterrupted())throw new InterruptedIOException();}public void progress(long at,long duration){assertTrue(at>=0&&at<=duration);}};}
    double decodedRms(File file,long expectedDurationMs)throws Exception{
        MediaExtractor ex=new MediaExtractor();MediaCodec decoder=null;long count=0;double squares=0;
        try{ex.setDataSource(file.getPath());MediaFormat format=ex.getTrackFormat(0);assertEquals("audio/mpeg",format.getString(MediaFormat.KEY_MIME));assertEquals(expectedDurationMs,format.getLong(MediaFormat.KEY_DURATION)/1000,350);ex.selectTrack(0);decoder=MediaCodec.createDecoderByType("audio/mpeg");decoder.configure(format,null,null,0);decoder.start();boolean inputEnd=false,end=false;MediaCodec.BufferInfo info=new MediaCodec.BufferInfo();
            for(int step=0;step<2000&&!end;step++){
                if(!inputEnd){int i=decoder.dequeueInputBuffer(10000);if(i>=0){ByteBuffer b=decoder.getInputBuffer(i);b.clear();int n=ex.readSampleData(b,0);if(n<0){decoder.queueInputBuffer(i,0,0,0,MediaCodec.BUFFER_FLAG_END_OF_STREAM);inputEnd=true;}else{decoder.queueInputBuffer(i,0,n,ex.getSampleTime(),0);ex.advance();}}}
                int i=decoder.dequeueOutputBuffer(info,10000);if(i>=0){try{ByteBuffer b=decoder.getOutputBuffer(i);if(info.size>0){b.position(info.offset);b.limit(info.offset+info.size);b.order(ByteOrder.LITTLE_ENDIAN);while(b.remaining()>=2){double value=b.getShort();squares+=value*value;count++;}}end=(info.flags&MediaCodec.BUFFER_FLAG_END_OF_STREAM)!=0;}finally{decoder.releaseOutputBuffer(i,false);}}
            }assertTrue("Decoder must reach EOS",end);assertTrue(count>0);return Math.sqrt(squares/count);
        }finally{if(decoder!=null){decoder.stop();decoder.release();}ex.release();}
    }
    @Test public void rawExportCropsActualToneAndSilenceWithoutChangingSource()throws Exception{
        File source=AudioTestFixtures.collection(c),tone=File.createTempFile("chapter-tone-",".mp3",c.getCacheDir()),silence=File.createTempFile("chapter-silence-",".mp3",c.getCacheDir());byte[] original=java.nio.file.Files.readAllBytes(source.toPath());
        try{ChapterMp3Exporter.convert(MediaInput.file(source),tone,320,34000,37000,control());assertTrue(decodedRms(tone,3000)>100);ChapterMp3Exporter.convert(MediaInput.file(source),silence,128,31200,32200,control());assertTrue(decodedRms(silence,1000)<30);assertArrayEquals(original,java.nio.file.Files.readAllBytes(source.toPath()));}finally{source.delete();tone.delete();silence.delete();}
    }
    @Test public void compressedAacSeekExportsOnlySelectedDuration()throws Exception{
        File source=File.createTempFile("chapter-aac-",".m4a",c.getCacheDir()),out=File.createTempFile("chapter-aac-out-",".mp3",c.getCacheDir());
        try{try(InputStream in=getInstrumentation().getContext().getAssets().open("audio.m4a");OutputStream target=new FileOutputStream(source)){byte[] bytes=new byte[8192];int n;while((n=in.read(bytes))!=-1)target.write(bytes,0,n);}ChapterMp3Exporter.convert(MediaInput.file(source),out,192,500,2000,control());assertTrue(decodedRms(out,1500)>100);}finally{source.delete();out.delete();}
    }
    @Test public void cancelledExportStopsBeforeCompleting()throws Exception{
        File source=AudioTestFixtures.collection(c),out=File.createTempFile("chapter-cancel-",".mp3",c.getCacheDir());int[] checks={0};
        try{try{ChapterMp3Exporter.convert(MediaInput.file(source),out,192,0,96000,new ChapterMp3Exporter.Control(){public void check()throws IOException{if(++checks[0]>4)throw new InterruptedIOException();}public void progress(long at,long total){}});fail("Cancellation ignored");}catch(InterruptedIOException expected){assertEquals(5,checks[0]);}}finally{source.delete();out.delete();}
    }
}
