package br.com.onda;
import java.net.URI;
import java.util.*;
import org.json.*;

/** Selection belongs to video IDs, never to recycled list rows. */
final class PlaylistSelection {
 final List<YoutubeDownloads.Entry> items;private final Set<String> marked=new HashSet<>();
 PlaylistSelection(List<YoutubeDownloads.Entry> entries){if(entries.isEmpty()||entries.size()>100)throw new IllegalArgumentException("Lista inválida");items=Collections.unmodifiableList(new ArrayList<>(entries));}
 int count(){return marked.size();}
 boolean contains(int index){return marked.contains(items.get(index).url);}
 void set(int index,boolean value){String id=items.get(index).url;if(value)marked.add(id);else marked.remove(id);}
 void all(boolean value){marked.clear();if(value)for(YoutubeDownloads.Entry e:items)marked.add(e.url);}
 List<YoutubeDownloads.Entry> chosen(){List<YoutubeDownloads.Entry> out=new ArrayList<>();for(YoutubeDownloads.Entry e:items)if(marked.contains(e.url))out.add(e);return out;}
 String encode()throws JSONException{JSONArray a=new JSONArray();for(int i=0;i<items.size();i++){YoutubeDownloads.Entry e=items.get(i);a.put(new JSONObject().put("title",e.title).put("url",e.url).put("image",e.thumbnail).put("duration",e.duration).put("selected",contains(i)));}return a.toString();}
 static PlaylistSelection decode(String json)throws JSONException{if(json==null||json.length()>180000)throw new JSONException("Lista inválida");JSONArray a=new JSONArray(json);if(a.length()==0||a.length()>100)throw new JSONException("Lista inválida");List<YoutubeDownloads.Entry> entries=new ArrayList<>();Set<String> seen=new HashSet<>();for(int i=0;i<a.length();i++){JSONObject o=a.getJSONObject(i);String title=o.getString("title");if(title.length()>160)throw new JSONException("Título inválido");YoutubeDownloads.Entry e=new YoutubeDownloads.Entry(title,o.getString("url"),o.optString("image",""),o.optLong("duration",0));if(!seen.add(e.url))throw new JSONException("Vídeo repetido");entries.add(e);}PlaylistSelection s=new PlaylistSelection(entries);for(int i=0;i<a.length();i++)s.set(i,a.getJSONObject(i).optBoolean("selected",false));return s;}
 static String artwork(String input){try{if(input==null||input.length()>1024)return "";URI u=new URI(input);String h=u.getHost();if(!"https".equalsIgnoreCase(u.getScheme())||u.getUserInfo()!=null||u.getPort()!=-1||h==null)return "";h=h.toLowerCase(Locale.ROOT);return h.equals("ytimg.com")||h.endsWith(".ytimg.com")||h.equals("googleusercontent.com")||h.endsWith(".googleusercontent.com")?input:"";}catch(Exception e){return "";}}
 static String duration(long seconds){if(seconds<=0)return "";return seconds>=3600?String.format(Locale.ROOT,"%d:%02d:%02d",seconds/3600,seconds/60%60,seconds%60):String.format(Locale.ROOT,"%d:%02d",seconds/60,seconds%60);}
}
