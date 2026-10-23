package br.com.onda;
import android.test.InstrumentationTestCase;
import android.media.*;
import java.io.*;
public class DownloadMuxTest extends InstrumentationTestCase {
 private File fixture(String name)throws Exception{File f=new File(getInstrumentation().getTargetContext().getCacheDir(),name);try(InputStream in=getInstrumentation().getContext().getAssets().open(name);OutputStream out=new FileOutputStream(f)){byte[] b=new byte[8192];int n;while((n=in.read(b))!=-1)out.write(b,0,n);}return f;}
 private void verify(File file,int count)throws Exception{MediaExtractor e=new MediaExtractor();try{e.setDataSource(file.getPath());assertEquals(count,e.getTrackCount());for(int i=0;i<count;i++)assertTrue(e.getTrackFormat(i).getLong(MediaFormat.KEY_DURATION)>1000000);}finally{e.release();}}
 public void testCombinedAndAudioOnly()throws Exception{File source=fixture("combined.mp4"),out=File.createTempFile("test-",".mp4",source.getParentFile());try{DownloadMux.merge(source,null,out,false,()->{});verify(out,2);DownloadMux.merge(source,null,out,true,()->{});verify(out,1);}finally{source.delete();out.delete();}}
 public void testSeparatedTracks()throws Exception{File video=fixture("video.mp4"),audio=fixture("audio.m4a"),out=File.createTempFile("test-",".mp4",video.getParentFile());try{DownloadMux.merge(video,audio,out,false,()->{});verify(out,2);}finally{video.delete();audio.delete();out.delete();}}
 public void testCancellation()throws Exception{File source=fixture("combined.mp4"),out=File.createTempFile("test-",".mp4",source.getParentFile());try{try{DownloadMux.merge(source,null,out,false,()->{throw new InterruptedIOException();});fail("Cancelamento ignorado");}catch(InterruptedIOException expected){}}finally{source.delete();out.delete();}}
}
