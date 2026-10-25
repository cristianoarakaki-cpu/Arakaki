package br.com.onda;
import org.json.*;
import java.util.*;
/** Bounded local scene markers. No media data or remote URLs are stored here. */
final class VideoMoments {
 static final int LIMIT=30,LABEL_LIMIT=80,NOTE_LIMIT=1000;static final long MAX_TIME=604800000L;
 static final class Moment {final String id,label,note;final long position;Moment(String id,String label,long position){this(id,label,position,"");}Moment(String id,String label,long position,String note){this.id=id;this.label=label;this.position=position;this.note=note;}}
 static String label(String raw){return raw==null?"":raw.replaceAll("[\\p{Cntrl}\\s]+"," ").trim();}
 static String note(String raw){return raw==null?"":raw.replace("\r\n","\n").replace("\r","\n").replaceAll("[\\p{Cntrl}&&[^\n\t]]", "").trim();}
 static boolean valid(Moment m){return m!=null&&m.id!=null&&m.id.matches("[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}")&&m.label!=null&&!m.label.isEmpty()&&m.label.length()<=LABEL_LIMIT&&m.label.equals(label(m.label))&&m.position>=0&&m.position<=MAX_TIME&&m.note!=null&&m.note.length()<=NOTE_LIMIT&&m.note.equals(note(m.note));}
 static List<Moment> decode(String raw){List<Moment> out=new ArrayList<>();if(raw==null||raw.length()>262144)return out;try{JSONArray array=new JSONArray(raw);Set<String> ids=new HashSet<>();for(int i=0;i<Math.min(array.length(),LIMIT);i++){JSONObject o=array.optJSONObject(i);if(o==null||!(o.opt("id") instanceof String)||!(o.opt("label") instanceof String)||!(o.opt("position") instanceof Number))continue;Number number=(Number)o.opt("position");long position=number.longValue();if(number.doubleValue()!=position)continue;Moment m=new Moment(o.getString("id"),o.getString("label"),position,o.has("note")&&!(o.opt("note") instanceof String)?null:o.optString("note",""));if(valid(m)&&ids.add(m.id))out.add(m);}}catch(JSONException ignored){}out.sort(Comparator.comparingLong(m->m.position));return out;}
 static String encode(List<Moment> moments){JSONArray out=new JSONArray();Set<String> ids=new HashSet<>();for(Moment m:moments){if(out.length()>=LIMIT)break;if(!valid(m)||!ids.add(m.id))continue;try{JSONObject o=new JSONObject();o.put("id",m.id);o.put("label",m.label);o.put("position",m.position);if(!m.note.isEmpty())o.put("note",m.note);out.put(o);}catch(JSONException ignored){}}return out.toString();}
}
