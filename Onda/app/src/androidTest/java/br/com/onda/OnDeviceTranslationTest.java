package br.com.onda;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
public class OnDeviceTranslationTest {
 @Test public void downloadsSelectedModelsAndTranslatesOnDevice()throws Exception{
  LocalLyricTranslator[] translator={null};CountDownLatch finished=new CountDownLatch(1);AtomicReference<String> text=new AtomicReference<>();AtomicReference<Exception> error=new AtomicReference<>();
  getInstrumentation().runOnMainSync(()->{translator[0]=new LocalLyricTranslator("en","pt");translator[0].prepare(false,()->translator[0].translate("Good morning",new LyricTranslation.Result(){public void success(String value){text.set(value);finished.countDown();}public void failure(Exception failure){error.set(failure);finished.countDown();}}),failure->{error.set(failure);finished.countDown();});});
  try{assertTrue("Language model download/translation timed out",finished.await(240,TimeUnit.SECONDS));if(error.get()!=null)throw error.get();assertNotNull(text.get());assertTrue("Unexpected actual model output: "+text.get(),text.get().toLowerCase(java.util.Locale.ROOT).contains("bom dia"));java.io.File proof=new java.io.File(getInstrumentation().getTargetContext().getFilesDir(),"on-device-translation.json");try(java.io.FileOutputStream out=new java.io.FileOutputStream(proof)){out.write(new org.json.JSONObject().put("engine","Google ML Kit on-device").put("source","en").put("target","pt").put("input","Good morning").put("actualOutput",text.get()).put("realModelDownloaded",true).toString(2).getBytes(java.nio.charset.StandardCharsets.UTF_8));}}
  finally{getInstrumentation().runOnMainSync(()->{if(translator[0]!=null)translator[0].close();});}
 }
}
