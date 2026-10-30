package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
import android.media.*;
import java.io.*;
import java.nio.*;
@androidx.media3.common.util.UnstableApi
public class Mp3ConverterTest {
 private File fixture(String name)throws Exception{File f=File.createTempFile("mp3-source-",".m4a",getInstrumentation().getTargetContext().getCacheDir());try(InputStream in=getInstrumentation().getContext().getAssets().open(name);OutputStream out=new FileOutputStream(f)){byte[] b=new byte[8192];int n;while((n=in.read(b))!=-1)out.write(b,0,n);}return f;}
 void verify(File file,int channels)throws Exception{MediaExtractor e=new MediaExtractor();MediaCodec decoder=null;try{e.setDataSource(file.getPath());assertEquals(1,e.getTrackCount());MediaFormat f=e.getTrackFormat(0);assertEquals("audio/mpeg",f.getString(MediaFormat.KEY_MIME));assertEquals(channels,f.getInteger(MediaFormat.KEY_CHANNEL_COUNT));assertTrue(f.getLong(MediaFormat.KEY_DURATION)>2000000);e.selectTrack(0);decoder=MediaCodec.createDecoderByType("audio/mpeg");decoder.configure(f,null,null,0);decoder.start();boolean inputEnd=false,heard=false;MediaCodec.BufferInfo info=new MediaCodec.BufferInfo();for(int step=0;step<400&&!heard;step++){
  if(!inputEnd){int i=decoder.dequeueInputBuffer(10000);if(i>=0){int n=e.readSampleData(decoder.getInputBuffer(i),0);if(n<0){decoder.queueInputBuffer(i,0,0,0,MediaCodec.BUFFER_FLAG_END_OF_STREAM);inputEnd=true;}else{decoder.queueInputBuffer(i,0,n,e.getSampleTime(),0);e.advance();}}}
  int i=decoder.dequeueOutputBuffer(info,10000);if(i>=0){ByteBuffer b=decoder.getOutputBuffer(i);if(b!=null&&info.size>0){b.position(info.offset);b.limit(info.offset+info.size);b.order(ByteOrder.LITTLE_ENDIAN);while(b.remaining()>=2)if(Math.abs((int)b.getShort())>100){heard=true;break;}}decoder.releaseOutputBuffer(i,false);}}
  assertTrue("MP3 decodificado deve conter áudio",heard);
 }finally{if(decoder!=null){decoder.stop();decoder.release();}e.release();}}
 @Test public void monoMp3ContainsRealAudio()throws Exception{File in=fixture("audio.m4a"),out=File.createTempFile("mp3-test-",".mp3",in.getParentFile());try{Mp3Converter.convert(in,out,192,()->{});verify(out,1);}finally{in.delete();out.delete();}}
 @Test public void stereoMp3ContainsRealAudio()throws Exception{File in=fixture("audio-stereo.m4a"),out=File.createTempFile("mp3-test-",".mp3",in.getParentFile());try{Mp3Converter.convert(in,out,192,()->{});verify(out,2);}finally{in.delete();out.delete();}}
 @Test public void conversionCanBeCancelled()throws Exception{File in=fixture("audio.m4a"),out=File.createTempFile("mp3-test-",".mp3",in.getParentFile());int[] checks={0};try{try{Mp3Converter.convert(in,out,192,()->{if(++checks[0]>5)throw new InterruptedIOException();});fail("Cancelamento ignorado");}catch(InterruptedIOException expected){}}finally{in.delete();out.delete();}}
 @Test public void downloadServiceSavesRealMp3()throws Exception{android.content.Context c=getInstrumentation().getTargetContext();File out=File.createTempFile("service-test-",".mp3",c.getCacheDir());c.getSharedPreferences("downloads",0).edit().clear().commit();android.content.Intent job=new android.content.Intent(c,MediaDownloadService.class).putExtra("first","https://raw.githubusercontent.com/cristianoarakaki-cpu/Arakaki/245b693e64cf5b5b33bc2a5f491a607f6a435655/Onda/tests/fixtures/download.mp4").putExtra("format","mp3").putExtra("destination",android.net.Uri.fromFile(out).toString()).putExtra("title","Fixture");
  try{getInstrumentation().runOnMainSync(()->c.startForegroundService(job));long until=System.currentTimeMillis()+90000;String status="";while(System.currentTimeMillis()<until){status=c.getSharedPreferences("downloads",0).getString("status","");if(!MediaDownloadService.activeDownload&&status.startsWith("Download concluído"))break;if(!MediaDownloadService.activeDownload&&status.startsWith("Operação interrompida"))fail(status);Thread.sleep(200);}assertTrue(status,status.startsWith("Download concluído"));assertEquals("audio/mpeg",c.getSharedPreferences("downloads",0).getString("last_mime",""));MediaExtractor ex=new MediaExtractor();try{ex.setDataSource(out.getPath());assertEquals("audio/mpeg",ex.getTrackFormat(0).getString(MediaFormat.KEY_MIME));}finally{ex.release();}}
  finally{c.stopService(job);out.delete();}
 }
}
