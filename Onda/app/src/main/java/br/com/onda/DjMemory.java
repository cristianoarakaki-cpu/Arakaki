package br.com.onda;
import org.json.*;
import java.util.*;
/** Recommendation context only: never store file paths or remote URLs here. */
final class DjMemory {
 static final int MAX_RAW=1024*1024;
 static final class Cue {final String reason;final int mode;Cue(String reason,int mode){this.reason=reason;this.mode=mode;}}
 static String encode(Map<String,Cue> cues){
  if(cues.size()>MusicResume.LIMIT)return "{}";JSONObject all=new JSONObject();
  try{for(Map.Entry<String,Cue> e:cues.entrySet()){Cue c=e.getValue();if(!MusicResume.deviceId(e.getKey())||c==null||c.reason==null||c.reason.isEmpty()||c.reason.length()>280||c.mode<0||c.mode>4)continue;all.put(e.getKey(),new JSONObject().put("reason",c.reason).put("mode",c.mode));}}catch(JSONException e){return "{}";}
  String result=all.toString();return result.length()<=MAX_RAW?result:"{}";
 }
 static Map<String,Cue> decode(String raw){
  Map<String,Cue> result=new HashMap<>();if(raw==null||raw.length()>MAX_RAW)return result;
  try{JSONObject all=new JSONObject(raw);if(all.length()>MusicResume.LIMIT)return result;Iterator<String> keys=all.keys();while(keys.hasNext()){String id=keys.next();JSONObject c=all.optJSONObject(id);if(!MusicResume.deviceId(id)||c==null)continue;Object text=c.opt("reason"),mode=c.opt("mode");if(!(text instanceof String)||!(mode instanceof Integer))continue;String reason=(String)text;int m=(Integer)mode;if(!reason.isEmpty()&&reason.length()<=280&&m>=0&&m<=4)result.put(id,new Cue(reason,m));}}catch(JSONException ignored){}
  return result;
 }
}
