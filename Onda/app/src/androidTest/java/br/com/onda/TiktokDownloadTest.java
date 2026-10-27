package br.com.onda;

import android.content.*;
import android.media.*;
import android.net.Uri;
import java.io.*;
import org.json.JSONObject;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;

/** Live provider availability is reported separately from local media regression tests. */
@androidx.media3.common.util.UnstableApi
public class TiktokDownloadTest {
 @Test public void usersPublicShortLinkDownloadsVideoAndConvertsAudio()throws Exception {
  Context c=getInstrumentation().getTargetContext();JSONObject report=new JSONObject();
  File summary=new File(c.getFilesDir(),"tiktok-download-tests.json");
  try {
   YoutubeDownloads.Result result;
   try {result=MediaDownloads.inspect("https://vt.tiktok.com/ZSg42qGJc/");}
   catch(Exception unavailable){report.put("analysis","provider-unavailable").put("reason",DownloadFailure.describe("Consulta",unavailable));return;}
   report.put("analysis","formats-found");
   for(String format:new String[]{"mp4","mp3"}){
    YoutubeDownloads.Option option=null;for(YoutubeDownloads.Option candidate:result.options)if(format.equals(candidate.extension)){option=candidate;break;}
    assertNotNull(option);File out=File.createTempFile("tiktok-live-","."+format,c.getCacheDir());
    Intent job=new Intent(c,MediaDownloadService.class).putExtra("first",option.first).putExtra("original",option.original).putExtra("referer",option.referer).putExtra("format",format).putExtra("destination",Uri.fromFile(out).toString()).putExtra("title","TikTok live test");
    try {
     c.getSharedPreferences("downloads",0).edit().putString("status","").commit();
     getInstrumentation().runOnMainSync(()->c.startForegroundService(job));
     long end=System.currentTimeMillis()+180000;String status="";
     while(System.currentTimeMillis()<end){status=c.getSharedPreferences("downloads",0).getString("status","");if(!MediaDownloadService.activeDownload&&(status.startsWith("Download concluído")||status.startsWith("Operação interrompida")))break;Thread.sleep(200);}
     report.put(format+"Status",status);assertTrue(status,status.startsWith("Download concluído"));
     boolean audio=false,video=false;MediaExtractor e=new MediaExtractor();
     try{e.setDataSource(out.getPath());for(int i=0;i<e.getTrackCount();i++){String mime=e.getTrackFormat(i).getString(MediaFormat.KEY_MIME);if(mime!=null){audio|=mime.startsWith("audio/");video|=mime.startsWith("video/");if(format.equals("mp3"))assertEquals("audio/mpeg",mime);}}}finally{e.release();}
     assertTrue("Missing audio",audio);assertEquals(format.equals("mp4"),video);report.put(format,true).put(format+"Bytes",out.length());
    }finally{c.stopService(job);out.delete();}
   }
  }finally{try(FileOutputStream out=new FileOutputStream(summary)){out.write(report.toString(2).getBytes(java.nio.charset.StandardCharsets.UTF_8));}}
 }
}
