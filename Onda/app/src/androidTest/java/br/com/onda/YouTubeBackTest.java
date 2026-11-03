package br.com.onda;
import android.app.*;
import android.content.*;
import android.view.*;
import android.webkit.*;
import android.widget.*;
import java.io.*;
import java.lang.reflect.*;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.*;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
/** API35 dispatcher integration. Actual HTML media playback is covered by YouTubeFullscreenTest on API29. */
@androidx.media3.common.util.UnstableApi
public class YouTubeBackTest {
 private final Instrumentation ins=getInstrumentation();private YouTubeActivity activity;private String phase="launch";
 private Object field(String name){try{Field f=YouTubeActivity.class.getDeclaredField(name);f.setAccessible(true);return f.get(activity);}catch(Exception e){throw new RuntimeException(e);}}
 private interface Check{boolean ready();}
 private void waitFor(Check c)throws Exception{for(int i=0;i<300;i++){boolean[] ready={false};ins.runOnMainSync(()->ready[0]=c.ready());if(ready[0])return;Thread.sleep(50);}String[] detail={""};ins.runOnMainSync(()->{WebView w=(WebView)field("web");detail[0]=" url="+(w==null?"null":w.getUrl())+" progress="+(w==null?-1:w.getProgress())+" focus="+activity.hasWindowFocus()+" full="+(field("fullscreenView")!=null)+" orientation="+activity.getResources().getConfiguration().orientation;});fail("API35 browser Back timed out: "+phase+detail[0]);}
 @After public void after(){if(activity!=null){ins.runOnMainSync(activity::finish);ins.waitForIdleSync();}}
 @Test public void overlayBackThenNormalHistoryAndLifecycle()throws Exception{
  android.content.Context c=ins.getTargetContext();activity=(YouTubeActivity)ins.startActivitySync(new Intent(c,YouTubeActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));waitFor(()->field("web")!=null);
  WebView[] web={null};int[] orientation={0};String first="https://m.youtube.com/watch?v=aqz-KE-bpKQ",second="https://m.youtube.com/watch?v=i7j0bw5TonI";
  ins.runOnMainSync(()->{web[0]=(WebView)field("web");orientation[0]=activity.getRequestedOrientation();web[0].stopLoading();web[0].setWebViewClient(new WebViewClient(){@Override public WebResourceResponse shouldInterceptRequest(WebView w,WebResourceRequest r){return new WebResourceResponse("text/html","UTF-8",new ByteArrayInputStream("<html><head><title>Onda Back fixture</title></head><body>Onda</body></html>".getBytes(java.nio.charset.StandardCharsets.UTF_8)));}});web[0].loadDataWithBaseURL(first,"<html><head><title>Onda Back fixture</title></head><body>Onda</body></html>","text/html","UTF-8",first);});
  phase="local-fixture-ready";waitFor(()->first.equals(web[0].getUrl())&&web[0].getProgress()==100&&activity.hasWindowFocus());AtomicInteger exits=new AtomicInteger();ins.runOnMainSync(()->web[0].getWebChromeClient().onShowCustomView(new FrameLayout(activity),exits::incrementAndGet));
  phase="fullscreen-landscape";waitFor(()->field("fullscreenView")!=null&&activity.hasWindowFocus()&&activity.getResources().getConfiguration().orientation==android.content.res.Configuration.ORIENTATION_LANDSCAPE);
  ins.runOnMainSync(()->{assertNotNull(field("fullscreenBackCallback"));assertNotNull(field("pageBackCallback"));assertEquals(View.GONE,((View)field("page")).getVisibility());});
  phase="back-from-fullscreen";assertTrue(ins.getUiAutomation().performGlobalAction(android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_BACK));waitFor(()->field("fullscreenView")==null&&activity.hasWindowFocus()&&activity.getRequestedOrientation()==orientation[0]);
  ins.runOnMainSync(()->{assertEquals(1,exits.get());assertNull(field("fullscreenBackCallback"));assertEquals(View.VISIBLE,((View)field("page")).getVisibility());assertSame(web[0],field("web"));assertFalse(activity.isFinishing());web[0].loadUrl(second);});
  phase="history-navigation";waitFor(()->second.equals(web[0].getUrl())&&web[0].getProgress()==100&&web[0].canGoBack());assertTrue(ins.getUiAutomation().performGlobalAction(android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_BACK));waitFor(()->first.equals(web[0].getUrl()));assertFalse(activity.isFinishing());
  ins.runOnMainSync(()->{web[0].getWebChromeClient().onShowCustomView(new FrameLayout(activity),exits::incrementAndGet);try{Method pause=YouTubeActivity.class.getDeclaredMethod("onPause");pause.setAccessible(true);pause.invoke(activity);assertEquals(2,exits.get());assertNull(field("fullscreenBackCallback"));assertNull(field("fullscreenView"));Method resume=YouTubeActivity.class.getDeclaredMethod("onResume");resume.setAccessible(true);resume.invoke(activity);}catch(Exception e){throw new RuntimeException(e);}});
  phase="home-no-pip";assertTrue(ins.getUiAutomation().performGlobalAction(android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_HOME));waitFor(()->field("web")==null);ins.runOnMainSync(()->assertFalse(activity.isInPictureInPictureMode()));
  try(OutputStream out=new FileOutputStream(new File(c.getFilesDir(),"youtube-back-35.json"))){out.write("{\"automaticPictureInPictureDisabled\":true,\"nativeOverlayBack\":true,\"normalBackHistory\":true,\"sameWebView\":true,\"pauseReleasesFullscreen\":true}".getBytes(java.nio.charset.StandardCharsets.UTF_8));}
 }
}
