package br.com.onda;

import android.content.*;
import android.media.*;
import android.net.Uri;
import java.io.*;
import java.net.*;
import java.util.*;
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
   try {result=MediaDownloads.inspect("https://vt.tiktok.com/ZSgT118XJ/");}
   catch(Exception unavailable){report.put("analysis","provider-unavailable").put("reason",DownloadFailure.describe("Consulta",unavailable));return;}
   report.put("analysis","formats-found");
   for(String format:new String[]{"mp4","mp3"}){
    YoutubeDownloads.Option option=null;for(YoutubeDownloads.Option candidate:result.options)if(format.equals(candidate.extension)){option=candidate;break;}
    assertNotNull(option);File out=File.createTempFile("tiktok-live-","."+format,c.getCacheDir());
    Intent job=new Intent(c,MediaDownloadService.class).putExtra("request_cookies",option.requestCookies).putExtra("first",option.first).putExtra("original",option.original).putExtra("referer",option.referer).putExtra("format",format).putExtra("destination",Uri.fromFile(out).toString()).putExtra("title","TikTok live test");
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
 @Test public void anonymousSessionSurvivesRedirectProbeAndFormatHandoffOnAndroid()throws Exception{
  final String id="7412345678901234567",pageUrl="https://www.tiktok.com/@onda/video/"+id,cdn="https://v16-webapp-prime.tiktok.com/video/test.mp4";PublicMediaSession session=new PublicMediaSession();JSONObject item=new JSONObject().put("id",id).put("desc","Native public video").put("video",new JSONObject().put("downloadAddr",cdn));String html="<script id='__UNIVERSAL_DATA_FOR_REHYDRATION__'>"+new JSONObject().put("__DEFAULT_SCOPE__",new JSONObject().put("webapp.video-detail",new JSONObject().put("statusCode",0).put("itemInfo",new JSONObject().put("itemStruct",item))))+"</script>";
  PublicMediaHttp.Factory transport=url->new HttpURLConnection(url){public void connect(){}public boolean usingProxy(){return false;}public void disconnect(){}public int getResponseCode(){return url.getHost().equals("vt.tiktok.com")?302:url.getHost().equals("www.tiktok.com")?200:"ttwid=guest%7Ctoken".equals(getRequestProperty("Cookie"))?206:403;}public String getHeaderField(String name){return name.equalsIgnoreCase("Location")?pageUrl:null;}public Map<String,List<String>> getHeaderFields(){return url.getHost().equals("vt.tiktok.com")?Collections.singletonMap("Set-Cookie",Collections.singletonList("ttwid=guest%7Ctoken; Domain=.tiktok.com; Path=/; Secure; HttpOnly")):Collections.emptyMap();}public String getContentType(){return url.getHost().startsWith("v16")?"video/mp4":"text/html";}public InputStream getInputStream(){return new ByteArrayInputStream(url.getHost().startsWith("v16")?new byte[]{0,0,0,20,'f','t','y','p','i','s','o','m'}:html.getBytes(java.nio.charset.StandardCharsets.UTF_8));}};
  PublicMediaHttp.Page page=PublicMediaHttp.read("https://vt.tiktok.com/ZSgT118XJ/",true,"",transport,false,session);TiktokPage.Clip clip=TiktokPage.parse(page.text(),id);TiktokPage.Clip ready=MediaDownloads.available(clip,page.url,(url,referer)->PublicMediaHttp.read(url,false,referer,transport,false,session));assertEquals(cdn,ready.video);for(YoutubeDownloads.Option option:MediaDownloads.tiktok(ready,page.url,session.snapshot()).options){assertEquals("ttwid=guest%7Ctoken",PublicMediaSession.restore(option.requestCookies).header(cdn));assertEquals("",PublicMediaSession.restore(option.requestCookies).header("https://example.org/video"));}assertEquals("",session.header("http://v16-webapp-prime.tiktok.com/video/test.mp4"));
 }
 @Test public void photoOriginalIsValidatedWithoutReencoding()throws Exception{Context c=getInstrumentation().getTargetContext();File source=File.createTempFile("photo-source-",".jpg",c.getCacheDir()),out=File.createTempFile("photo-copy-",".jpg",c.getCacheDir());android.graphics.Bitmap bitmap=android.graphics.Bitmap.createBitmap(32,24,android.graphics.Bitmap.Config.ARGB_8888);try{bitmap.eraseColor(android.graphics.Color.CYAN);try(OutputStream stream=new FileOutputStream(source)){assertTrue(bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG,90,stream));}OriginalMedia.copy(source,out,"jpg",()->{});assertArrayEquals(java.nio.file.Files.readAllBytes(source.toPath()),java.nio.file.Files.readAllBytes(out.toPath()));assertEquals("image/jpeg",MediaDownloadService.mime("jpg"));java.nio.file.Files.write(source.toPath(),"<html>not an image</html>".getBytes());try{OriginalMedia.copy(source,out,"jpg",()->{});fail();}catch(IOException expected){}}finally{bitmap.recycle();source.delete();out.delete();}}
 @Test public void userPhotoLinkDownloadsSeparateImageAndSoundtrackWhenProviderAvailable()throws Exception{Context c=getInstrumentation().getTargetContext();JSONObject report=new JSONObject();try{YoutubeDownloads.Result result;try{result=MediaDownloads.inspect("https://vt.tiktok.com/ZSpMhBrxN/");}catch(Exception unavailable){report.put("analysis","provider-unavailable").put("reason",DownloadFailure.describe("Consulta",unavailable));return;}report.put("analysis","formats-found");boolean image=false;for(YoutubeDownloads.Option option:result.options){assertNotEquals("mp4",option.extension);if(!option.extension.equals("jpg")&&!option.extension.equals("mp3"))continue;image|=option.extension.equals("jpg");File out=File.createTempFile("tiktok-photo-live-","."+option.extension,c.getCacheDir());Intent job=new Intent(c,MediaDownloadService.class).putExtra("request_cookies",option.requestCookies).putExtra("first",option.first).putExtra("original",true).putExtra("referer",option.referer).putExtra("format",option.extension).putExtra("destination",Uri.fromFile(out).toString()).putExtra("title","TikTok photo test");try{c.getSharedPreferences("downloads",0).edit().putString("status","").commit();getInstrumentation().runOnMainSync(()->c.startForegroundService(job));long end=System.currentTimeMillis()+120000;String status="";while(System.currentTimeMillis()<end){status=c.getSharedPreferences("downloads",0).getString("status","");if(!MediaDownloadService.activeDownload&&(status.startsWith("Download concluído")||status.startsWith("Operação interrompida")))break;Thread.sleep(200);}assertTrue(status,status.startsWith("Download concluído"));assertTrue(out.length()>100);report.put(option.extension+"Bytes",out.length());if(option.extension.equals("jpg")){android.graphics.BitmapFactory.Options bounds=new android.graphics.BitmapFactory.Options();bounds.inJustDecodeBounds=true;android.graphics.BitmapFactory.decodeFile(out.getPath(),bounds);assertTrue(bounds.outWidth>0&&bounds.outHeight>0);}else{MediaExtractor extractor=new MediaExtractor();try{extractor.setDataSource(out.getPath());assertEquals("audio/mpeg",extractor.getTrackFormat(0).getString(MediaFormat.KEY_MIME));}finally{extractor.release();}}}finally{c.stopService(job);out.delete();}}report.put("imageAvailable",image);}finally{try(OutputStream out=new FileOutputStream(new File(c.getFilesDir(),"tiktok-photo-tests.json"))){out.write(report.toString(2).getBytes(java.nio.charset.StandardCharsets.UTF_8));}}}
}
