package br.com.onda;
import android.app.*;
import android.content.*;
import android.view.*;
import android.widget.*;
import android.text.Layout;
import java.util.*;
import java.util.concurrent.*;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
@androidx.media3.common.util.UnstableApi
public class PdfSpeechTest {
 private final Instrumentation ins=getInstrumentation();private final Context context=ins.getTargetContext();
 private interface Check{boolean ready();}
 private void waitFor(Check check)throws Exception{for(int i=0;i<200;i++){boolean[] result={false};ins.runOnMainSync(()->result[0]=check.ready());if(result[0])return;Thread.sleep(50);}fail("PDF voice state did not become ready");}
 @Test public void installedBrazilianVoicesReadAllChunksAndRememberSelection()throws Exception{
  SharedPreferences prefs=context.getSharedPreferences("pdf_voice",0);Map<String,?> old=prefs.getAll();prefs.edit().clear().commit();PdfSpeech[] speech={null};CountDownLatch done=new CountDownLatch(1);List<String> heard=new CopyOnWriteArrayList<>(),voices=new CopyOnWriteArrayList<>();BroadcastReceiver receiver=new BroadcastReceiver(){public void onReceive(Context c,Intent i){heard.add(i.getStringExtra("text"));voices.add(i.getStringExtra("voice"));}};androidx.core.content.ContextCompat.registerReceiver(context,receiver,new IntentFilter("br.com.onda.PDF_TEST_SPOKEN"),androidx.core.content.ContextCompat.RECEIVER_EXPORTED);
  try{ins.runOnMainSync(()->{speech[0]=new PdfSpeech(context,new PdfSpeech.Listener(){public void changed(String s){}public void finished(){done.countDown();}},ins.getContext().getPackageName());speech[0].prepare();});waitFor(()->speech[0].ready());String text=String.join("",Collections.nCopies(140,"Texto brasileiro, ação e emoção. "));
   ins.runOnMainSync(()->{assertEquals(2,speech[0].voices().size());assertEquals("onda-br-a",speech[0].selectedName());speech[0].voice(speech[0].voices().get(1));speech[0].rate(1.4f);speech[0].continuous(false);speech[0].read(text);});assertTrue("Actual TTS did not finish",done.await(20,TimeUnit.SECONDS));assertEquals(text,String.join("",heard));assertTrue(heard.size()>1);for(String voice:voices)assertEquals("onda-br-b",voice);
   ins.runOnMainSync(()->{assertFalse(speech[0].playing());assertFalse(speech[0].resumable());assertFalse(speech[0].continuous());assertEquals(1.4f,speech[0].rate(),.01f);speech[0].close();speech[0]=new PdfSpeech(context,new PdfSpeech.Listener(){public void changed(String s){}public void finished(){}},ins.getContext().getPackageName());speech[0].prepare();});waitFor(()->speech[0].ready());ins.runOnMainSync(()->assertEquals("onda-br-b",speech[0].selectedName()));
  }finally{ins.runOnMainSync(()->{if(speech[0]!=null)speech[0].close();});context.unregisterReceiver(receiver);restore(prefs,old);}
 }
 @Test public void pauseResumeAndStopIgnoreInterruptedUtteranceCallbacks()throws Exception{
  PdfSpeech[] speech={null};CountDownLatch done=new CountDownLatch(1),started=new CountDownLatch(1);BroadcastReceiver receiver=new BroadcastReceiver(){public void onReceive(Context c,Intent i){if(i.getStringExtra("text").startsWith("PAUSE_"))started.countDown();}};androidx.core.content.ContextCompat.registerReceiver(context,receiver,new IntentFilter("br.com.onda.PDF_TEST_SPOKEN"),androidx.core.content.ContextCompat.RECEIVER_EXPORTED);
  try{ins.runOnMainSync(()->{speech[0]=new PdfSpeech(context,new PdfSpeech.Listener(){public void changed(String s){}public void finished(){done.countDown();}},ins.getContext().getPackageName());speech[0].prepare();});waitFor(()->speech[0].ready());ins.runOnMainSync(()->speech[0].read("PAUSE_ Leitura que deve poder pausar e retomar."));assertTrue(started.await(10,TimeUnit.SECONDS));ins.runOnMainSync(()->{speech[0].pause();assertFalse(speech[0].playing());assertTrue(speech[0].resumable());});Thread.sleep(300);assertEquals(1,done.getCount());ins.runOnMainSync(()->speech[0].resume());assertTrue(done.await(15,TimeUnit.SECONDS));ins.runOnMainSync(()->{speech[0].stop();assertFalse(speech[0].resumable());assertFalse(speech[0].playing());});
  }finally{ins.runOnMainSync(()->{if(speech[0]!=null)speech[0].close();});context.unregisterReceiver(receiver);}
 }
 @Test public void readerOffersAccessibleVoiceControlsWithoutAutoplay()throws Exception{
  PdfActivity screen=(PdfActivity)ins.startActivitySync(new Intent(context,PdfActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));try{ins.waitForIdleSync();Thread.sleep(200);ins.runOnMainSync(()->{View root=screen.getWindow().getDecorView();for(String name:new String[]{"Ouvir PDF em voz alta","Pausar leitura em voz alta do PDF","Escolher voz e velocidade do PDF"}){TextView button=find(root,name);assertNotNull(name,button);Layout layout=button.getLayout();assertNotNull(layout);assertEquals(1,layout.getLineCount());assertEquals(0,layout.getEllipsisCount(0));assertTrue(layout.getLineWidth(0)<=button.getWidth()-button.getCompoundPaddingLeft()-button.getCompoundPaddingRight()+1);}assertFalse(find(root,"Ouvir PDF em voz alta").isEnabled());assertFalse(find(root,"Pausar leitura em voz alta do PDF").isEnabled());});android.graphics.Bitmap capture=ins.getUiAutomation().takeScreenshot();assertNotNull(capture);try(java.io.OutputStream out=new java.io.FileOutputStream(new java.io.File(context.getFilesDir(),"pdf-voice-reader.png"))){capture.compress(android.graphics.Bitmap.CompressFormat.PNG,100,out);}finally{capture.recycle();}}finally{ins.runOnMainSync(screen::finish);}
 }
 private TextView find(View view,String name){if(view instanceof TextView&&name.contentEquals(view.getContentDescription()==null?"":view.getContentDescription()))return (TextView)view;if(view instanceof ViewGroup)for(int i=0;i<((ViewGroup)view).getChildCount();i++){TextView found=find(((ViewGroup)view).getChildAt(i),name);if(found!=null)return found;}return null;}
 private void restore(SharedPreferences prefs,Map<String,?> old){SharedPreferences.Editor edit=prefs.edit().clear();for(Map.Entry<String,?> e:old.entrySet()){Object v=e.getValue();if(v instanceof String)edit.putString(e.getKey(),(String)v);else if(v instanceof Float)edit.putFloat(e.getKey(),(Float)v);else if(v instanceof Boolean)edit.putBoolean(e.getKey(),(Boolean)v);}edit.commit();}
}
