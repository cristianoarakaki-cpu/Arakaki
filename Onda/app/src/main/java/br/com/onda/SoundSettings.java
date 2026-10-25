package br.com.onda;
import android.content.*;
import java.util.concurrent.CopyOnWriteArrayList;
final class SoundSettings {
    static final String[] ROUTES={"speaker","wired","bluetooth","usb","hdmi","other"};
    static final String[] LABELS={"Alto-falante do celular","Fone com fio","Bluetooth","Áudio USB","HDMI","Outras saídas"};
    private static volatile String current="";
    private static final CopyOnWriteArrayList<Runnable> observers=new CopyOnWriteArrayList<>();
    static String current(){return current;}
    static boolean valid(String key){for(String s:ROUTES)if(s.equals(key))return true;return false;}
    static boolean route(String key){String next=valid(key)?key:"";if(next.equals(current))return false;current=next;for(Runnable r:observers)r.run();return true;}
    static void observe(Runnable observer){observers.addIfAbsent(observer);}
    static void forget(Runnable observer){observers.remove(observer);}
    static String label(String key){for(int i=0;i<ROUTES.length;i++)if(ROUTES[i].equals(key))return LABELS[i];return "Saída ainda não identificada";}
    static boolean automatic(Context c){return c.getSharedPreferences("sound_profiles",0).getBoolean("automatic",false);}
    static void automatic(Context c,boolean value){SharedPreferences p=c.getSharedPreferences("sound_profiles",0);SharedPreferences.Editor edit=p.edit();
        if(value&&valid(current)&&!p.contains(current+".enabled"))write(edit,current+".",readGlobal(c));
        edit.putBoolean("automatic",value).apply();
    }
    static String name(Context c,String key){return c.getSharedPreferences("sound_profiles",0).getString(key+".name",label(key));}
    static void rename(Context c,String key,String name){if(!valid(key))return;String value=name==null?"":name.replaceAll("[\\p{Cntrl}\\s]+"," ").trim();if(value.length()>40)value=value.substring(0,40);c.getSharedPreferences("sound_profiles",0).edit().putString(key+".name",value.isEmpty()?label(key):value).apply();}
    static SoundProfile read(Context c){return automatic(c)?readProfile(c,current):readGlobal(c);}
    static SoundProfile readGlobal(Context c){return read(c.getSharedPreferences("sound",0),"");}
    static SoundProfile readProfile(Context c,String key){return valid(key)?read(c.getSharedPreferences("sound_profiles",0),key+"."):SoundProfile.preset(0,false);}
    private static SoundProfile read(SharedPreferences p,String prefix){int[] gains=new int[5];for(int i=0;i<5;i++)gains[i]=p.getInt(prefix+"gain_"+i,0);return new SoundProfile(p.getBoolean(prefix+"enabled",false),gains,p.getInt(prefix+"bass",0));}
    private static void write(SharedPreferences.Editor e,String prefix,SoundProfile profile){e.putBoolean(prefix+"enabled",profile.enabled).putInt(prefix+"bass",profile.bass);for(int i=0;i<5;i++)e.putInt(prefix+"gain_"+i,profile.gain(i));}
    static void save(Context c,SoundProfile profile){SharedPreferences.Editor e=c.getSharedPreferences("sound",0).edit();write(e,"",profile);e.apply();}
    static void saveProfile(Context c,String key,SoundProfile profile){if(!valid(key))return;SharedPreferences.Editor e=c.getSharedPreferences("sound_profiles",0).edit();write(e,key+".",profile);e.apply();}
}
