package br.com.onda;

import android.content.*;
import android.media.*;
import android.os.*;
import android.speech.tts.*;
import java.util.*;

/** Activity-scoped, on-demand Android TTS. No polling, permanent wake lock or cloud SDK. */
final class PdfSpeech implements AutoCloseable {
 interface Listener {void changed(String message);void finished();}
 private final Context context;private final Listener listener;private final Handler main=new Handler(Looper.getMainLooper());
 private final SharedPreferences preferences;private final AudioManager audio;private final AudioFocusRequest focus;
 private final String enginePackage;private TextToSpeech engine;private boolean initialized,initializing,closed,playing;private String text="",utterance="";private int cursor,end,range,session;
 private final BroadcastReceiver noisy=new BroadcastReceiver(){@Override public void onReceive(Context c,Intent i){pause();}};
 PdfSpeech(Context context,Listener listener){this(context,listener,null);}
 PdfSpeech(Context context,Listener listener,String enginePackage){
  this.enginePackage=enginePackage;
  this.context=context;this.listener=listener;preferences=context.getSharedPreferences("pdf_voice",0);audio=(AudioManager)context.getSystemService(Context.AUDIO_SERVICE);
  AudioAttributes attributes=new AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build();
  focus=new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT).setAudioAttributes(attributes).setWillPauseWhenDucked(true).setOnAudioFocusChangeListener(change->{if(change!=AudioManager.AUDIOFOCUS_GAIN)pause();},main).build();
  androidx.core.content.ContextCompat.registerReceiver(context,noisy,new IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY),androidx.core.content.ContextCompat.RECEIVER_NOT_EXPORTED);
 }
 void prepare(){if(initializing||initialized||closed)return;if(engine!=null)engine.shutdown();initializing=true;listener.changed("Preparando as vozes do Android…");
  engine=new TextToSpeech(context,result->main.post(()->{if(closed)return;initializing=false;initialized=result==TextToSpeech.SUCCESS;
   if(!initialized){playing=false;releaseFocus();listener.changed("Voz indisponível. Confira o mecanismo de texto para voz do Android.");return;}
   engine.setAudioAttributes(new AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build());
   engine.setOnUtteranceProgressListener(new UtteranceProgressListener(){
    @Override public void onStart(String id){}
    @Override public void onDone(String id){main.post(()->{if(!current(id))return;cursor=end;range=cursor;if(cursor<text.length())speakNext();else{playing=false;utterance="";releaseFocus();listener.changed("Página lida");listener.finished();}});}
    @Override public void onError(String id){main.post(()->{if(current(id)){invalidate();playing=false;releaseFocus();listener.changed("Não foi possível falar este trecho. Confira a voz instalada e tente novamente.");}});}
    @Override public void onRangeStart(String id,int start,int finish,int frame){main.post(()->{if(current(id))range=Math.min(end,cursor+Math.max(0,start));});}
   });
   Voice selected=selectedVoice();if(selected!=null)engine.setVoice(selected);
   listener.changed(selected==null?"Instale uma voz offline em português brasileiro nas configurações do Android.":"Voz pronta • "+label(selected));
   if(playing){if(selected==null){playing=false;releaseFocus();}else speakNext();}
  }),enginePackage);
 }
 boolean ready(){return initialized&&!closed;}
 boolean playing(){return playing;}
 boolean resumable(){return !text.isEmpty()&&cursor<text.length();}
 float rate(){return preferences.getFloat("rate",1f);}
 boolean continuous(){return preferences.getBoolean("continuous",true);}
 void continuous(boolean value){preferences.edit().putBoolean("continuous",value).apply();}
 void rate(float value){boolean resume=playing;pause();preferences.edit().putFloat("rate",Math.max(.5f,Math.min(2f,value))).apply();if(resume)resume();}
 List<Voice> voices(){ArrayList<Voice> out=new ArrayList<>();if(!ready())return out;Set<Voice> voices=engine.getVoices();if(voices!=null)for(Voice voice:voices){Set<String> features=voice.getFeatures();if(!voice.isNetworkConnectionRequired()&&(features==null||!features.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED)))out.add(voice);}
  out.sort(Comparator.comparingInt(PdfSpeech::rank).thenComparing(Voice::getName));return out;}
 private static int rank(Voice voice){Locale locale=voice.getLocale();return locale.getLanguage().equals("pt")?(locale.getCountry().equals("BR")?0:1):2;}
 private Voice selectedVoice(){List<Voice> options=voices();String wanted=preferences.getString("voice","");for(Voice voice:options)if(voice.getName().equals(wanted))return voice;for(Voice voice:options)if(rank(voice)==0)return voice;return null;}
 String selectedName(){Voice voice=selectedVoice();return voice==null?"":voice.getName();}
 static String label(Voice voice){return voice.getLocale().getDisplayName(new Locale("pt","BR"))+" • "+voice.getName()+" • offline";}
 void voice(Voice voice){boolean resume=playing;pause();preferences.edit().putString("voice",voice.getName()).apply();engine.setVoice(voice);listener.changed("Voz escolhida • "+label(voice));if(resume)resume();}
 void read(String value){stop();text=value==null?"":value;cursor=range=0;if(text.trim().isEmpty()){listener.changed("Esta página não contém texto legível para ouvir.");return;}resume();}
 void resume(){if(closed||!resumable())return;playing=true;prepare();if(!ready())return;if(selectedVoice()==null){playing=false;listener.changed("Escolha uma voz offline disponível ou instale português brasileiro no Android.");return;}speakNext();}
 private boolean current(String id){return !closed&&playing&&id.equals(utterance);}
 private void speakNext(){if(!playing||closed||!ready())return;
  if(audio==null||audio.requestAudioFocus(focus)!=AudioManager.AUDIOFOCUS_REQUEST_GRANTED){playing=false;listener.changed("Áudio ocupado. Toque em Ouvir para tentar novamente.");return;}
  Voice voice=selectedVoice();if(voice==null||engine.setVoice(voice)==TextToSpeech.ERROR){playing=false;releaseFocus();listener.changed("A voz escolhida não está disponível. Escolha outra voz.");return;}
  engine.setSpeechRate(rate());int max=Math.min(1000,TextToSpeech.getMaxSpeechInputLength());end=PdfSpeechText.end(text,cursor,max);range=cursor;utterance="pdf-"+(++session);listener.changed("Lendo em voz alta • "+Math.round(rate()*100)+"%");
  if(engine.speak(text.substring(cursor,end),TextToSpeech.QUEUE_FLUSH,null,utterance)==TextToSpeech.ERROR){invalidate();playing=false;releaseFocus();listener.changed("A voz não conseguiu iniciar. Confira as configurações do Android.");}
 }
 private void invalidate(){session++;utterance="";}
 void pause(){if(!playing)return;playing=false;cursor=range;invalidate();if(engine!=null)engine.stop();releaseFocus();listener.changed("Leitura pausada • retoma o trecho atual");}
 void stop(){playing=false;invalidate();if(engine!=null)engine.stop();text="";cursor=range=end=0;releaseFocus();}
 private void releaseFocus(){if(audio!=null)audio.abandonAudioFocusRequest(focus);}
 @Override public void close(){if(closed)return;stop();closed=true;context.unregisterReceiver(noisy);if(engine!=null){engine.shutdown();engine=null;}main.removeCallbacksAndMessages(null);}
}
