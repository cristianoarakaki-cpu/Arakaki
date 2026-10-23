package br.com.onda;
import android.content.*;
final class SoundSettings {
    static SoundProfile read(Context c){SharedPreferences p=c.getSharedPreferences("sound",0);int[] gains=new int[5];for(int i=0;i<5;i++)gains[i]=p.getInt("gain_"+i,0);return new SoundProfile(p.getBoolean("enabled",false),gains,p.getInt("bass",0));}
    static void save(Context c,SoundProfile profile){SharedPreferences.Editor e=c.getSharedPreferences("sound",0).edit().putBoolean("enabled",profile.enabled).putInt("bass",profile.bass);for(int i=0;i<5;i++)e.putInt("gain_"+i,profile.gain(i));e.apply();}
}
