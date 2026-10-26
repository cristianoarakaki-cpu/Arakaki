package br.com.onda;
import android.content.*;
final class SpeechSettings {
 static final String COMMAND="speech",STATUS="speech_status";
 static boolean voice(Context c){return c.getSharedPreferences("speech_audio",0).getBoolean("voice",false);}
 static boolean silence(Context c){return c.getSharedPreferences("speech_audio",0).getBoolean("silence",false);}
 static void save(Context c,boolean voice,boolean silence){c.getSharedPreferences("speech_audio",0).edit().putBoolean("voice",voice).putBoolean("silence",silence).apply();}
}
