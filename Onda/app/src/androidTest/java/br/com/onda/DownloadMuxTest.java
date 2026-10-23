package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
import android.media.*;
import java.io.*;
@androidx.media3.common.util.UnstableApi
public class DownloadMuxTest {
 private File fixture(String name)throws Exception{File f=new File(getInstrumentation().getTargetContext().getCacheDir(),name);try(InputStream in=getInstrumentation().getContext().getAssets().open(name);OutputStream out=new FileOutputStream(f)){byte[] b=new byte[8192];int n;while((n=in.read(b))!=-1)out.write(b,0,n);}return f;}
 private void verify(File file,int count)throws Exception{MediaExtractor e=new MediaExtractor();try{e.setDataSource(file.getPath());assertEquals(count,e.getTrackCount());for(int i=0;i<count;i++)assertTrue(e.getTrackFormat(i).getLong(MediaFormat.KEY_DURATION)>1000000);}finally{e.release();}}
 @Test public void testCombinedAndAudioOnly()throws Exception{File source=fixture("combined.mp4"),out=File.createTempFile("test-",".mp4",source.getParentFile());try{DownloadMux.merge(source,null,out,false,()->{});verify(out,2);DownloadMux.merge(source,null,out,true,()->{});verify(out,1);}finally{source.delete();out.delete();}}
 @Test public void testSeparatedTracks()throws Exception{File video=fixture("video.mp4"),audio=fixture("audio.m4a"),out=File.createTempFile("test-",".mp4",video.getParentFile());try{DownloadMux.merge(video,audio,out,false,()->{});verify(out,2);}finally{video.delete();audio.delete();out.delete();}}
 @Test public void testCancellation()throws Exception{File source=fixture("combined.mp4"),out=File.createTempFile("test-",".mp4",source.getParentFile());try{try{DownloadMux.merge(source,null,out,false,()->{throw new InterruptedIOException();});fail("Cancelamento ignorado");}catch(InterruptedIOException expected){}}finally{source.delete();out.delete();}}
 @Test public void testDownloadServiceHttpsToFile()throws Exception{
  android.content.Context context=getInstrumentation().getTargetContext();File output=File.createTempFile("https-test-",".mp4",context.getCacheDir());
  context.getSharedPreferences("downloads",0).edit().clear().commit();
  android.content.Intent intent=new android.content.Intent(context,MediaDownloadService.class).putExtra("first","https://raw.githubusercontent.com/cristianoarakaki-cpu/Arakaki/onda-lab-downloads/Onda/tests/fixtures/download.mp4").putExtra("destination",android.net.Uri.fromFile(output).toString()).putExtra("audio",false);
  try{getInstrumentation().runOnMainSync(()->context.startForegroundService(intent));long end=System.currentTimeMillis()+90000;boolean started=false;String status="";
   while(System.currentTimeMillis()<end){status=context.getSharedPreferences("downloads",0).getString("status","");started|=MediaDownloadService.activeDownload||!status.isEmpty();if(started&&!MediaDownloadService.activeDownload&&status.startsWith("Download concluído"))break;if(started&&!MediaDownloadService.activeDownload&&status.startsWith("Falha"))fail(status);Thread.sleep(200);}
   assertTrue(status,status.startsWith("Download concluído"));verify(output,2);
  }finally{context.stopService(intent);output.delete();}
 }
}
