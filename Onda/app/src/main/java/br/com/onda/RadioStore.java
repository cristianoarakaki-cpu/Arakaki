package br.com.onda;
import android.content.*;import java.util.*;
final class RadioStore {
 static List<RadioStation> favorites(Context c){return read(c,"favorites");}static List<RadioStation> cached(Context c){return read(c,"catalog");}
 private static List<RadioStation> read(Context c,String key){try{return RadioStation.read(c.getSharedPreferences("radio",0).getString(key,"[]"),false);}catch(Exception e){return new ArrayList<>();}}
 static boolean favorite(Context c,String id){for(RadioStation s:favorites(c))if(s.id.equals(id))return true;return false;}
 static boolean toggle(Context c,RadioStation station){List<RadioStation> list=favorites(c);boolean removed=list.removeIf(s->s.id.equals(station.id));if(!removed)list.add(station);c.getSharedPreferences("radio",0).edit().putString("favorites",RadioStation.write(list)).apply();return !removed;}
 static void cache(Context c,List<RadioStation> stations,String query,boolean brazil){if(stations.isEmpty())return;c.getSharedPreferences("radio",0).edit().putString("catalog",RadioStation.write(stations)).putString("query",query).putBoolean("brazil",brazil).apply();}
}
