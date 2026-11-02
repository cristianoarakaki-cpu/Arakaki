package br.com.onda;
import android.content.*;
final class SpeechSettings {
 static final String COMMAND="speech",STATUS="speech_status";
 static boolean voice(Context c){return c.getSharedPreferences("speech_audio",0).getBoolean("voice",false);}
 static boolean silence(Context c){return c.getSharedPreferences("speech_audio",0).getBoolean("silence",false);}
 static final String[] QUIET_LEVELS={"Desligado • som original","Suave • até +3 dB","Equilibrado • até +6 dB","Forte • até +9 dB"};
 static int quiet(Context c){return Math.max(0,Math.min(3,c.getSharedPreferences("speech_audio",0).getInt("quiet",0)));}
 static void quiet(Context c,int level){c.getSharedPreferences("speech_audio",0).edit().putInt("quiet",Math.max(0,Math.min(3,level))).apply();}
 static void save(Context c,boolean voice,boolean silence){c.getSharedPreferences("speech_audio",0).edit().putBoolean("voice",voice).putBoolean("silence",silence).apply();}
}
