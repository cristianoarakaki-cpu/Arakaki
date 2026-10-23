package br.com.onda;

import android.content.Context;
import org.json.*;
import java.util.*;

/** Local ordered lists. Reading a missing library file never removes its saved membership. */
final class PlaylistStore {
    static final class Entry {
        final String id; String name; final List<String> songs=new ArrayList<>();
        Entry(String id,String name){this.id=id;this.name=name;}
    }
    static List<Entry> read(Context c){return decode(c.getSharedPreferences("playlists",0).getString("lists","[]"));}
    static List<Entry> decode(String raw){
        List<Entry> lists=new ArrayList<>();
        try {JSONArray all=new JSONArray(raw);Set<String> seen=new HashSet<>();
            for(int i=0;i<all.length()&&lists.size()<100;i++){
                JSONObject o=all.optJSONObject(i);if(o==null)continue;
                String id=o.optString("id",""),name=o.optString("name","").trim();
                if(id.isEmpty()||name.isEmpty()||!seen.add(id))continue;
                Entry e=new Entry(id,name);JSONArray tracks=o.optJSONArray("songs");
                if(tracks!=null)for(int j=0;j<tracks.length()&&e.songs.size()<2000;j++){String track=tracks.optString(j,"");if(track.matches("\\d+")&&!e.songs.contains(track))e.songs.add(track);}
                lists.add(e);
            }
        }catch(JSONException ignored){}return lists;
    }
    static String encode(List<Entry> lists){JSONArray all=new JSONArray();try{for(Entry e:lists){JSONObject o=new JSONObject();o.put("id",e.id);o.put("name",e.name);o.put("songs",new JSONArray(e.songs));all.put(o);}}catch(JSONException e){throw new IllegalStateException(e);}return all.toString();}
    static List<Entry> matching(List<Entry> lists,String query){List<Entry> exact=new ArrayList<>(),partial=new ArrayList<>();if(SearchText.normalize(query).isEmpty())return exact;for(Entry e:lists){if(SearchText.normalize(e.name).equals(SearchText.normalize(query)))exact.add(e);else if(SearchText.matches(e.name,query))partial.add(e);}return exact.isEmpty()?partial:exact;}
    static void save(Context c,List<Entry> lists){c.getSharedPreferences("playlists",0).edit().putString("lists",encode(lists)).apply();}
}
