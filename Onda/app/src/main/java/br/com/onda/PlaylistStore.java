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
                if(tracks!=null)for(int j=0;j<tracks.length()&&e.songs.size()<2000;j++){String track=tracks.optString(j,"");if(track.matches("(?:\\d+|download:-?\\d{1,11})")&&!e.songs.contains(track))e.songs.add(track);}
                lists.add(e);
            }
        }catch(JSONException ignored){}return lists;
    }
    static String encode(List<Entry> lists){JSONArray all=new JSONArray();try{for(Entry e:lists){JSONObject o=new JSONObject();o.put("id",e.id);o.put("name",e.name);o.put("songs",new JSONArray(e.songs));all.put(o);}}catch(JSONException e){throw new IllegalStateException(e);}return all.toString();}
    static String nameKey(String value){String normalized=SearchText.normalize(value);return normalized.isEmpty()?value.trim().toLowerCase(Locale.ROOT):normalized;}
    static List<Entry> matching(List<Entry> lists,String query){List<Entry> exact=new ArrayList<>(),partial=new ArrayList<>();if(SearchText.normalize(query).isEmpty())return exact;for(Entry e:lists){if(nameKey(e.name).equals(nameKey(query)))exact.add(e);else if(SearchText.matches(e.name,query))partial.add(e);}return exact.isEmpty()?partial:exact;}
    /** User-confirmed snapshot; reread current lists so another screen is never overwritten. */
    static synchronized Entry create(Context c,String rawName,List<String> songIds){
        String name=rawName==null?"":rawName.trim();
        if(name.isEmpty()||name.length()>60)throw new IllegalArgumentException("Digite um nome de até 60 caracteres");
        if(songIds==null||songIds.isEmpty()||songIds.size()>2000)throw new IllegalArgumentException("Seleção vazia ou grande demais para uma playlist");
        LinkedHashSet<String> unique=new LinkedHashSet<>();
        for(String id:songIds){if(id==null||!id.matches("(?:\\d+|download:-?\\d{1,11})"))throw new IllegalArgumentException("A seleção contém uma música que não pode ser salva");unique.add(id);}
        List<Entry> lists=read(c);
        if(lists.size()>=100)throw new IllegalArgumentException("A biblioteca já tem 100 playlists. Remova uma antes de salvar outra.");
        for(Entry other:lists)if(nameKey(other.name).equals(nameKey(name)))throw new IllegalArgumentException("Já existe uma playlist com esse nome");
        Entry entry=new Entry(UUID.randomUUID().toString(),name);entry.songs.addAll(unique);lists.add(entry);save(c,lists);return entry;
    }
    static void save(Context c,List<Entry> lists){c.getSharedPreferences("playlists",0).edit().putString("lists",encode(lists)).apply();}
}
