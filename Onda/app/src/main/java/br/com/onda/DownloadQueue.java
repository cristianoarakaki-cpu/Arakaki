package br.com.onda;
import org.json.*;
import java.util.*;
/** Bounded queue transferred without expiring media URLs. Resolve each video only when its turn arrives. */
final class DownloadQueue {
 static final int MAX=100;
 static String encode(List<YoutubeDownloads.Entry> entries)throws JSONException{JSONArray a=new JSONArray();for(YoutubeDownloads.Entry e:entries)a.put(new JSONObject().put("title",e.title).put("url",e.url));return validate(a.toString()).toString();}
 static JSONArray validate(String text)throws JSONException{if(text==null||text.length()>64000)throw new JSONException("Fila inválida");JSONArray a=new JSONArray(text);if(a.length()==0||a.length()>MAX)throw new JSONException("Selecione de 1 a 100 vídeos");Set<String> seen=new HashSet<>();for(int i=0;i<a.length();i++){JSONObject o=a.getJSONObject(i);String title=o.getString("title"),url=o.getString("url");if(title.isEmpty()||title.length()>160||!DownloadLinks.canonical(url).equals(url)||!seen.add(url))throw new JSONException("Item inválido ou repetido");}return a;}
}
