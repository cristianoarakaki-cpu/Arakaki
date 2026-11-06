package com.arakaki.prismavoz;

import android.app.*;
import android.content.*;
import android.media.*;
import android.media.session.MediaSession;
import android.media.session.PlaybackState;
import android.os.*;
import android.speech.tts.*;
import org.json.*;
import java.io.*;
import java.util.*;

/** Explicit user-started foreground playback. Text exists only for the current session. */
public final class SpeechService extends Service {
    static final String START="prismavoz.speech.START", PAUSE="prismavoz.speech.PAUSE", RESUME="prismavoz.speech.RESUME", STOP="prismavoz.speech.STOP";
    private static final int NOTIFICATION=201;
    private static volatile String snapshot="{\"status\":\"idle\"}";
    private static volatile boolean networkVoice;
    private final Handler main=new Handler(Looper.getMainLooper());
    private TextToSpeech engine;
    private boolean ready, paused, foreground, destroyed;
    private JSONArray segments=new JSONArray();
    private String voiceId="", title="PDF", status="idle", session="";
    private int index, generation, resumeOffset, utteranceBase;
    private float rate=1, pitch=1;
    private AudioManager audio;
    private AudioFocusRequest focus;
    private boolean hasFocus;
    private PowerManager.WakeLock wake;
    private MediaSession media;
    static String state(){return snapshot;}
    static void startError(String session,String text){try{snapshot=new JSONObject().put("session",session).put("status","error").put("message",text).toString();}catch(Exception ignored){}}
    static void stopIfNetwork(Context c){if(networkVoice)c.stopService(new Intent(c,SpeechService.class));}
    @Override public void onCreate(){super.onCreate();
        NotificationManager nm=(NotificationManager)getSystemService(NOTIFICATION_SERVICE);
        nm.createNotificationChannel(new NotificationChannel("pdf-reading","Leitura em voz alta",NotificationManager.IMPORTANCE_LOW));
        audio=(AudioManager)getSystemService(AUDIO_SERVICE);
        AudioAttributes attributes=new AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build();
        focus=new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN).setAudioAttributes(attributes).setOnAudioFocusChangeListener(change->{if(change<0){hasFocus=false;pause();}}).build();
        wake=((PowerManager)getSystemService(POWER_SERVICE)).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK,"PrismaVoz:Reading");
        media=new MediaSession(this,"PrismaVozReading");
        media.setCallback(new MediaSession.Callback(){@Override public void onPause(){pause();}@Override public void onPlay(){resume();}@Override public void onStop(){finish("stopped","");}});
        media.setFlags(MediaSession.FLAG_HANDLES_MEDIA_BUTTONS|MediaSession.FLAG_HANDLES_TRANSPORT_CONTROLS);
        showNotification();
        engine=new TextToSpeech(this,code->main.post(()->{
            if(destroyed)return;
            if(code!=TextToSpeech.SUCCESS){finish("error","O motor de voz não iniciou. Confira as configurações de texto para fala do Android.");return;}
            ready=true;
            engine.setAudioAttributes(attributes);
            engine.setOnUtteranceProgressListener(new UtteranceProgressListener(){
                @Override public void onStart(String id){}
                @Override public void onDone(String id){main.post(()->{if(valid(id)&&!paused){index++;resumeOffset=0;speakNext();}});}
                @Override public void onRangeStart(String id,int start,int end,int frame){main.post(()->{if(valid(id)&&!paused)resumeOffset=utteranceBase+Math.max(0,start);});}
                @Override public void onError(String id){main.post(()->{if(valid(id))finish("error","Não foi possível falar este trecho. Confira a voz e a conexão, se for online.");});}
            });
            if(segments.length()>0&&!paused)configureAndSpeak();
        }));
    }
    @Override public int onStartCommand(Intent intent,int flags,int startId){
        if(intent==null){stopSelf();return START_NOT_STICKY;}
        String action=intent.getAction();
        if(START.equals(action)){
            File input=new File(getCacheDir(),"speech-input.json");
            try{
                if(!input.isFile()||input.length()>4000000)throw new IOException("Texto de leitura inválido.");
                JSONObject data=new JSONObject(new String(MainActivity.readLimited(new FileInputStream(input),4000000),"UTF-8"));
                session=data.optString("session","");segments=data.getJSONArray("segments");
                if(segments.length()==0||segments.length()>10000)throw new IOException("Não há texto para ler.");
                int total=0;for(int i=0;i<segments.length();i++){JSONObject part=segments.getJSONObject(i);String text=part.getString("text");total+=text.length();if(text.trim().isEmpty()||text.length()>2800||part.getInt("page")<1)throw new IOException("Trecho de leitura inválido.");}
                if(total>500000)throw new IOException("Selecione menos páginas para esta leitura.");
                voiceId=data.getString("voice");title=data.optString("name","PDF");if(title.length()>120)title=title.substring(0,120);
                rate=(float)data.optDouble("rate",1);pitch=(float)data.optDouble("pitch",1);
                if(Float.isNaN(rate)||Float.isInfinite(rate)||rate<0.5f||rate>2f||Float.isNaN(pitch)||Float.isInfinite(pitch)||pitch<0.5f||pitch>2f)throw new IOException("Ajuste de voz inválido.");
                networkVoice=data.optBoolean("allowNetwork",false);
                if(networkVoice&&!online())throw new IOException("Ative as ações online antes de usar uma voz online.");
                generation++;if(engine!=null)engine.stop();index=0;resumeOffset=0;utteranceBase=0;paused=false;publish("preparing","");
                if(ready)configureAndSpeak();
            }catch(Exception e){finish("error",e.getMessage()==null?"Não foi possível preparar a leitura.":e.getMessage());}
            finally{input.delete();}
        }else if(PAUSE.equals(action))pause();else if(RESUME.equals(action))resume();else if(STOP.equals(action))finish("stopped","");
        return START_NOT_STICKY;
    }
    private boolean online(){return getSharedPreferences("MainActivity",MODE_PRIVATE).getBoolean("online",false);}
    private boolean valid(String id){return id.equals(generation+":"+index);}
    private void configureAndSpeak(){
        try{
            Voice selected=null;
            if(engine.getVoices()!=null)for(Voice v:engine.getVoices())if(v.getName().equals(voiceId))selected=v;
            if(selected==null)throw new IOException("A voz escolhida não está disponível. Atualize a lista de vozes.");
            if(selected.getFeatures().contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED))throw new IOException("Instale os dados desta voz nas configurações do Android.");
            boolean wantsNetwork=selected.isNetworkConnectionRequired();
            if(wantsNetwork&&(!networkVoice||!online()))throw new IOException("Esta voz precisa de internet e da sua autorização.");
            networkVoice=wantsNetwork;
            if(engine.setVoice(selected)!=TextToSpeech.SUCCESS||engine.setSpeechRate(rate)!=TextToSpeech.SUCCESS||engine.setPitch(pitch)!=TextToSpeech.SUCCESS)throw new IOException("Este motor não aceitou a voz ou os ajustes escolhidos.");
            speakNext();
        }catch(Exception e){finish("error",e.getMessage());}
    }
    private void speakNext(){
        if(paused||!ready)return;
        if(index>=segments.length()){finish("completed","");return;}
        if(networkVoice&&!online()){finish("error","Ações online desativadas. Escolha uma voz offline.");return;}
        if(!hasFocus){hasFocus=audio.requestAudioFocus(focus)==AudioManager.AUDIOFOCUS_REQUEST_GRANTED;if(!hasFocus){paused=true;publish("paused","Outro aplicativo está usando o áudio. Toque em Continuar quando estiver disponível.");showNotification();return;}}
        if(!wake.isHeld())wake.acquire(30*60*1000L);
        media.setActive(true);publish("playing","");showNotification();
        String fullText=segments.optJSONObject(index).optString("text");
        resumeOffset=Math.max(0,Math.min(resumeOffset,Math.max(0,fullText.length()-1)));
        if(resumeOffset>0&&Character.isLowSurrogate(fullText.charAt(resumeOffset))&&Character.isHighSurrogate(fullText.charAt(resumeOffset-1)))resumeOffset--;
        utteranceBase=resumeOffset;
        String text=fullText.substring(resumeOffset);
        if(engine.speak(text,TextToSpeech.QUEUE_FLUSH,null,generation+":"+index)!=TextToSpeech.SUCCESS)finish("error","O motor de voz recusou a leitura.");
    }
    private void pause(){if(segments.length()==0)return;generation++;paused=true;if(engine!=null)engine.stop();releaseAudio();publish("paused","");showNotification();}
    private void resume(){if(segments.length()==0||!paused)return;paused=false;if(ready)configureAndSpeak();else publish("preparing","");}
    private void releaseAudio(){if(wake!=null&&wake.isHeld())wake.release();if(audio!=null&&focus!=null&&hasFocus)audio.abandonAudioFocusRequest(focus);hasFocus=false;}
    private void publish(String next,String error){status=next;try{JSONObject state=new JSONObject().put("session",session).put("status",next).put("page",index<segments.length()?segments.optJSONObject(index).optInt("page"):0).put("index",index).put("total",segments.length()).put("message",error==null?"":error);snapshot=state.toString();}catch(Exception ignored){}if(media!=null)media.setPlaybackState(new PlaybackState.Builder().setActions(PlaybackState.ACTION_PLAY|PlaybackState.ACTION_PAUSE|PlaybackState.ACTION_STOP).setState("playing".equals(next)?PlaybackState.STATE_PLAYING:"paused".equals(next)?PlaybackState.STATE_PAUSED:PlaybackState.STATE_STOPPED,PlaybackState.PLAYBACK_POSITION_UNKNOWN,1).build());}
    private PendingIntent command(String action,int id){return PendingIntent.getService(this,id,new Intent(this,SpeechService.class).setAction(action),PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);}
    private void showNotification(){
        PendingIntent open=PendingIntent.getActivity(this,0,new Intent(this,MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
        boolean stopped=paused;
        Notification n=new Notification.Builder(this,"pdf-reading").setSmallIcon(android.R.drawable.ic_lock_silent_mode_off).setContentTitle("Prisma Voz — leitura em voz alta").setContentText(title).setContentIntent(open).setOnlyAlertOnce(true).setOngoing(true).setVisibility(Notification.VISIBILITY_PRIVATE).addAction(new Notification.Action.Builder(null,stopped?"Continuar":"Pausar",command(stopped?RESUME:PAUSE,1)).build()).addAction(new Notification.Action.Builder(null,"Parar",command(STOP,2)).build()).setStyle(new Notification.MediaStyle().setMediaSession(media.getSessionToken()).setShowActionsInCompactView(0,1)).build();
        if(!foreground){startForeground(NOTIFICATION,n);foreground=true;}else ((NotificationManager)getSystemService(NOTIFICATION_SERVICE)).notify(NOTIFICATION,n);
    }
    private void finish(String state,String error){generation++;if(engine!=null)engine.stop();releaseAudio();publish(state,error);segments=new JSONArray();networkVoice=false;if(media!=null)media.setActive(false);stopForeground(STOP_FOREGROUND_REMOVE);foreground=false;stopSelf();}
    @Override public void onTaskRemoved(Intent intent){finish("stopped","");}
    @Override public IBinder onBind(Intent intent){return null;}
    @Override public void onDestroy(){destroyed=true;generation++;if(engine!=null){engine.stop();engine.shutdown();engine=null;}releaseAudio();networkVoice=false;segments=new JSONArray();if(!Arrays.asList("completed","error","stopped").contains(status))publish("stopped","");if(media!=null){media.release();media=null;}super.onDestroy();}
}
