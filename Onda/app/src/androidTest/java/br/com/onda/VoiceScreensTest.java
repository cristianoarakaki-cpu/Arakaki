package br.com.onda;

import android.app.*;
import android.content.*;
import android.speech.RecognizerIntent;
import android.widget.EditText;
import java.util.*;
import org.junit.*;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;

@androidx.media3.common.util.UnstableApi
public class VoiceScreensTest {
    private final Instrumentation ins=getInstrumentation();
    private final Context c=ins.getTargetContext();
    private MainActivity main;
    private final List<Activity> opened=new ArrayList<>();
    private String oldPhrases;
    @Before public void before(){oldPhrases=c.getSharedPreferences("voice_phrases",0).getString("entries",null);main=(MainActivity)ins.startActivitySync(new Intent(c,MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));}
    @After public void after(){ins.runOnMainSync(()->{for(int i=opened.size()-1;i>=0;i--)opened.get(i).finish();if(main!=null)main.finish();});ins.waitForIdleSync();android.content.SharedPreferences.Editor edit=c.getSharedPreferences("voice_phrases",0).edit();if(oldPhrases==null)edit.remove("entries");else edit.putString("entries",oldPhrases);edit.commit();}
    private Intent result(String phrase){return new Intent().putStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS,new ArrayList<>(Arrays.asList(phrase)));}
    private Activity navigate(Class<? extends Activity> target,Runnable request)throws Exception{
        Instrumentation.ActivityMonitor monitor=ins.addMonitor(target.getName(),null,false);
        try{ins.runOnMainSync(request);Activity activity=ins.waitForMonitorWithTimeout(monitor,8000);assertNotNull("Voice did not open "+target.getSimpleName(),activity);assertEquals(target,activity.getClass());opened.add(activity);ins.waitForIdleSync();return activity;}
        finally{ins.removeMonitor(monitor);}
    }
    @Test public void recognizerResultsOpenYouTubeImagesAndUpdatesFromExistingMicrophones()throws Exception{
        YouTubeActivity youtube=(YouTubeActivity)navigate(YouTubeActivity.class,()->main.onActivityResult(VoiceSearch.REQUEST,Activity.RESULT_OK,result("abrir YouTube")));
        ImageSearchActivity images=(ImageSearchActivity)navigate(ImageSearchActivity.class,()->youtube.onActivityResult(VoiceSearch.REQUEST,Activity.RESULT_OK,result("abrir imagens")));
        navigate(UpdateActivity.class,()->images.onActivityResult(VoiceSearch.REQUEST,Activity.RESULT_OK,result("abrir atualizações")));
    }
    @Test public void editableScreenAliasWorksAndOrdinaryImagePhraseRemainsASearch()throws Exception{
        VoicePhraseBook book=new VoicePhraseBook("[]");book.put(null,"minhas mensagens bonitas",VoiceCommand.Action.OPEN_IMAGES,"",0);assertTrue(VoicePhrases.save(c,book));
        ImageSearchActivity images=(ImageSearchActivity)navigate(ImageSearchActivity.class,()->main.onActivityResult(VoiceSearch.REQUEST,Activity.RESULT_OK,result("minhas mensagens bonitas")));
        ins.runOnMainSync(()->images.onActivityResult(VoiceSearch.REQUEST,Activity.RESULT_OK,result("mensagens de motivação")));
        ins.runOnMainSync(()->{try{java.lang.reflect.Field f=ImageSearchActivity.class.getDeclaredField("query");f.setAccessible(true);assertEquals("mensagens de motivação",((EditText)f.get(images)).getText().toString());}catch(Exception e){throw new RuntimeException(e);}});
    }
}
