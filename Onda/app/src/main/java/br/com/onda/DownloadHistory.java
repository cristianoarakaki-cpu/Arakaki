package br.com.onda;

import android.content.Context;
import org.json.*;
import java.util.*;

/** Local journal only: source pages are reanalysed; temporary CDN URLs are never retained. */
final class DownloadHistory {
 static final int MAX=200;
 static final String PREF="download_history";
 static final class Entry {
  final String id,title,source,format,state,uri,detail;final long time,bytes,expected;
  Entry(JSONObject o){id=o.optString("id");title=o.optString("title");source=o.optString("source");format=o.optString("format");state=o.optString("state");uri=o.optString("uri");detail=o.optString("detail");time=o.optLong("time");bytes=o.optLong("bytes");expected=o.optLong("expected",-1);}
  boolean active(){return state.equals("queued")||state.equals("running");}
  boolean retryable(){return !source.isEmpty()&&(state.equals("failed")||state.equals("cancelled")||state.equals("interrupted"));}
 }
 static String text(String s,int max){if(s==null)return "";return s.substring(0,Math.min(max,s.length()));}
 private static JSONObject load(Context c)throws JSONException{String raw=c.getSharedPreferences(PREF,0).getString("data","{\"version\":1,\"items\":[]}");if(raw==null||raw.length()>512000)throw new JSONException("Histórico inválido");JSONObject root=new JSONObject(raw);if(root.optInt("version")!=1||root.getJSONArray("items").length()>MAX)throw new JSONException("Versão do histórico não suportada");return root;}
 private static void save(Context c,JSONObject root)throws JSONException{JSONArray items=root.getJSONArray("items");String raw=root.toString();while(raw.length()>512000){int remove=-1;for(int i=0;i<items.length();i++)if(!new Entry(items.getJSONObject(i)).active()){remove=i;break;}if(remove<0)return;items.remove(remove);raw=root.toString();}c.getSharedPreferences(PREF,0).edit().putString("data",raw).apply();}
 static synchronized List<Entry> read(Context c){ArrayList<Entry> out=new ArrayList<>();try{JSONArray items=load(c).getJSONArray("items");for(int i=items.length()-1;i>=0;i--)out.add(new Entry(items.getJSONObject(i)));}catch(JSONException ignored){}return out;}
 static synchronized String add(Context c,String title,String source,String format){try{JSONObject root=load(c);JSONArray items=root.getJSONArray("items");while(items.length()>=MAX){int remove=-1;for(int i=0;i<items.length();i++)if(!new Entry(items.getJSONObject(i)).active()){remove=i;break;}if(remove<0)return "";items.remove(remove);}String safe="";try{safe=MediaLinks.resolve(source);}catch(Exception ignored){}String id=UUID.randomUUID().toString();items.put(new JSONObject().put("id",id).put("title",text(title,160)).put("source",safe).put("format",text(format,8)).put("state","queued").put("time",System.currentTimeMillis()).put("bytes",0).put("expected",-1));save(c,root);return id;}catch(JSONException ignored){return "";}}
 static synchronized void update(Context c,String id,String state,String detail,long bytes,long expected,String uri){if(id==null||id.isEmpty())return;try{JSONObject root=load(c);JSONArray items=root.getJSONArray("items");for(int i=0;i<items.length();i++){JSONObject o=items.getJSONObject(i);if(!id.equals(o.optString("id")))continue;o.put("state",state).put("detail",text(detail,400)).put("bytes",Math.max(0,bytes)).put("expected",expected);if(uri!=null)o.put("uri",text(uri,4096));save(c,root);return;}}catch(JSONException ignored){}}
 static synchronized void settle(Context c,String state,String detail){try{JSONObject root=load(c);JSONArray items=root.getJSONArray("items");boolean changed=false;for(int i=0;i<items.length();i++){JSONObject o=items.getJSONObject(i);if(new Entry(o).active()){o.put("state",state).put("detail",text(detail,400));changed=true;}}if(changed)save(c,root);}catch(JSONException ignored){}}
 static synchronized void clearFinished(Context c){try{JSONObject root=load(c);JSONArray a=root.getJSONArray("items");for(int i=a.length()-1;i>=0;i--)if(!new Entry(a.getJSONObject(i)).active())a.remove(i);save(c,root);}catch(JSONException ignored){}}
 static String label(String state){switch(state){case "queued":return "Na fila";case "running":return "Em andamento";case "done":return "Concluído";case "failed":return "Falhou";case "cancelled":return "Cancelado";default:return "Interrompido";}}
}
