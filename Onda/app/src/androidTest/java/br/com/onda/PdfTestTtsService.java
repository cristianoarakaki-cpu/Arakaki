package br.com.onda;
import android.content.Intent;
import android.media.AudioFormat;
import android.speech.tts.*;
import java.util.*;
/** Instrumentation-only engine: validates actual Android binding and speech callbacks. */
public class PdfTestTtsService extends TextToSpeechService {
 private volatile boolean stopped;private int pauseRequests;
 @Override protected int onIsLanguageAvailable(String language,String country,String variant){return language.equals("por")||language.equals("pt")?TextToSpeech.LANG_COUNTRY_AVAILABLE:TextToSpeech.LANG_NOT_SUPPORTED;}
 @Override protected String[] onGetLanguage(){return new String[]{"por","BRA",""};}
 @Override protected int onLoadLanguage(String language,String country,String variant){return onIsLanguageAvailable(language,country,variant);}
 @Override protected void onStop(){stopped=true;}
 @Override public List<Voice> onGetVoices(){return Arrays.asList(new Voice("onda-br-a",new Locale("pt","BR"),400,100,false,Collections.emptySet()),new Voice("onda-br-b",new Locale("pt","BR"),400,100,false,Collections.emptySet()),new Voice("onda-network",Locale.US,400,100,true,Collections.emptySet()));}
 @Override public String onGetDefaultVoiceNameFor(String language,String country,String variant){return "onda-br-a";}
 @Override public int onLoadVoice(String voice){return "onda-br-a".equals(voice)||"onda-br-b".equals(voice)?TextToSpeech.SUCCESS:TextToSpeech.ERROR;}
 @Override public int onIsValidVoiceName(String voice){return onLoadVoice(voice);}
 @Override protected void onSynthesizeText(SynthesisRequest request,SynthesisCallback callback){stopped=false;String text=request.getCharSequenceText().toString();sendBroadcast(new Intent("br.com.onda.PDF_TEST_SPOKEN").setPackage("br.com.onda.musica").putExtra("text",text).putExtra("voice",request.getVoiceName()));boolean slow=text.startsWith("PAUSE_")&&pauseRequests++==0;callback.start(16000,AudioFormat.ENCODING_PCM_16BIT,1);byte[] pcm=new byte[640];for(int n=0;n<(slow?200:1)&&!stopped;n++){if(callback.audioAvailable(pcm,0,pcm.length)!=TextToSpeech.SUCCESS)break;if(slow)try{Thread.sleep(10);}catch(InterruptedException e){Thread.currentThread().interrupt();break;}}if(!stopped)callback.done();}
}
