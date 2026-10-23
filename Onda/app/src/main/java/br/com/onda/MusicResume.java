package br.com.onda;
import org.json.*;
import java.util.*;
/** Local IDs only: never persist online URLs or temporary access tokens. */
final class MusicResume {
 static final int LIMIT=10000;
 static List<String> decode(String raw){List<String> ids=new ArrayList<>();try{JSONArray a=new JSONArray(raw);if(a.length()>LIMIT)return ids;for(int i=0;i<a.length();i++){String id=a.optString(i,"");if(!id.matches("\\d+"))return new ArrayList<>();ids.add(id);}}catch(JSONException e){ids.clear();}return ids;}
 static String encode(List<String> ids){if(ids.size()>LIMIT)return "[]";for(String id:ids)if(id==null||!id.matches("\\d+"))return "[]";return new JSONArray(ids).toString();}
 static final class Selection {final List<String> ids;final int index;final long position;Selection(List<String> ids,int index,long position){this.ids=ids;this.index=index;this.position=position;}}
 static Selection select(List<String> saved,int current,long position,Map<String,Long> available){
  List<String> kept=new ArrayList<>();int target=-1,fallback=-1;boolean exact=false;
  current=Math.max(0,Math.min(saved.size()-1,current));
  for(int i=0;i<saved.size();i++)if(available.containsKey(saved.get(i))){if(i==current){target=kept.size();exact=true;}if(i>=current&&fallback<0)fallback=kept.size();kept.add(saved.get(i));}
  if(target<0)target=fallback>=0?fallback:0;
  long resume=exact?Math.max(0,position):0;
  if(!kept.isEmpty()){long duration=available.get(kept.get(target));if(duration>0&&resume>=duration)resume=0;}
  return new Selection(kept,target,resume);
 }
}
