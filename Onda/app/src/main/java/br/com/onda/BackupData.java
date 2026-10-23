package br.com.onda;
import org.json.*;
import java.util.*;

/** Portable metadata, never device paths or trusted MediaStore IDs from another phone. */
final class BackupData {
 static final int MAX_BYTES=8*1024*1024,MAX_TRACKS=20000;
 static final class Track {final String id,title,artist,album;final long duration;Track(String id,String title,String artist,String album,long duration){this.id=id;this.title=title;this.artist=artist;this.album=album;this.duration=duration;}}
 static final class Archive {final List<Track> tracks=new ArrayList<>();final List<PlaylistStore.Entry> lists=new ArrayList<>();final Set<String> favorites=new LinkedHashSet<>();VoicePhraseBook phrases=new VoicePhraseBook("[]");int unavailable;}
 static String text(JSONObject o,String key,int max,boolean empty)throws JSONException{Object v=o.get(key);if(!(v instanceof String))throw new JSONException("Texto inválido");String s=(String)v;if(s.length()>max||(!empty&&SearchText.normalize(s).isEmpty()))throw new JSONException("Texto inválido");return s;}
 static Archive parse(String raw)throws JSONException{
  JSONObject root=new JSONObject(raw);if(!"onda-backup".equals(root.getString("format"))||!Integer.valueOf(1).equals(root.get("version")))throw new JSONException("Formato de backup não suportado");
  Archive a=new Archive();JSONArray tracks=root.getJSONArray("tracks"),lists=root.getJSONArray("playlists"),favorites=root.getJSONArray("favorites"),phrases=root.getJSONArray("phrases");
  if(tracks.length()>MAX_TRACKS||lists.length()>100||favorites.length()>MAX_TRACKS||phrases.length()>100)throw new JSONException("Limites excedidos");
  Set<String> keys=new HashSet<>();for(int i=0;i<tracks.length();i++){JSONObject t=tracks.getJSONObject(i);String id=text(t,"key",32,false);Object d=t.get("duration");if(!id.matches("\\d+")||!keys.add(id)||!(d instanceof Number))throw new JSONException("Faixa inválida");long duration=((Number)d).longValue();if(duration<=0||duration>Long.MAX_VALUE/2||((Number)d).doubleValue()!=(double)duration)throw new JSONException("Duração inválida");a.tracks.add(new Track(id,text(t,"title",512,false),text(t,"artist",512,false),text(t,"album",512,true),duration));}
  Set<String> names=new HashSet<>();for(int i=0;i<lists.length();i++){JSONObject l=lists.getJSONObject(i);String name=text(l,"name",60,false).trim();if(!names.add(SearchText.normalize(name)))throw new JSONException("Lista repetida");PlaylistStore.Entry e=new PlaylistStore.Entry(UUID.randomUUID().toString(),name);JSONArray songs=l.getJSONArray("songs");if(songs.length()>2000)throw new JSONException("Lista muito grande");for(int j=0;j<songs.length();j++){Object id=songs.get(j);if(!(id instanceof String)||!keys.contains(id)||e.songs.contains(id))throw new JSONException("Referência inválida");e.songs.add((String)id);}a.lists.add(e);}
  for(int i=0;i<favorites.length();i++){Object id=favorites.get(i);if(!(id instanceof String)||!keys.contains(id))throw new JSONException("Favorita inválida");a.favorites.add((String)id);}
  VoicePhraseBook validated=new VoicePhraseBook("[]");Set<String> phraseIds=new HashSet<>();for(int i=0;i<phrases.length();i++){JSONObject p=phrases.getJSONObject(i);try{String id=text(p,"id",80,false);if(!phraseIds.add(id))throw new JSONException("Frase repetida");validated.put(id,text(p,"phrase",120,false),VoiceCommand.Action.valueOf(p.getString("action")),text(p,"query",160,true),p.getInt("minutes"));}catch(IllegalArgumentException e){throw new JSONException("Frase inválida");}}
  a.phrases=validated;return a;
 }
 static String json(Archive a)throws JSONException{JSONObject root=new JSONObject().put("format","onda-backup").put("version",1);JSONArray tracks=new JSONArray(),lists=new JSONArray();for(Track t:a.tracks)tracks.put(new JSONObject().put("key",t.id).put("title",t.title).put("artist",t.artist).put("album",t.album).put("duration",t.duration));for(PlaylistStore.Entry e:a.lists)lists.put(new JSONObject().put("name",e.name).put("songs",new JSONArray(e.songs)));return root.put("tracks",tracks).put("playlists",lists).put("favorites",new JSONArray(a.favorites)).put("phrases",new JSONArray(a.phrases.json())).toString(2);}
 static final class Plan {
  List<PlaylistStore.Entry> lists;Set<String> favorites;VoicePhraseBook phrases;int matched,missing,ambiguous,addedLists,addedSongs,addedFavorites,addedPhrases,conflicts;
  String summary(){return matched+" músicas localizadas; "+missing+" ausentes; "+ambiguous+" ambíguas.\n\nSerão acrescentadas:\n"+addedLists+" playlists, "+addedSongs+" faixas nas listas, "+addedFavorites+" favoritas e "+addedPhrases+" frases.\n\n"+conflicts+" itens ignorados por conflito ou limite. Os dados atuais serão mantidos.";}
 }
 static String identity(Track t){return SearchText.normalize(t.title)+"\u0000"+SearchText.normalize(t.artist);}
 static Plan merge(Archive source,List<Track> available,List<PlaylistStore.Entry> current,Set<String> favorites,VoicePhraseBook phrases){
  Plan p=new Plan();p.lists=PlaylistStore.decode(PlaylistStore.encode(current));p.favorites=new HashSet<>(favorites);p.phrases=new VoicePhraseBook(phrases.json());Map<String,List<Track>> index=new HashMap<>();for(Track t:available)index.computeIfAbsent(identity(t),k->new ArrayList<>()).add(t);Map<String,String> remap=new HashMap<>();
  for(Track t:source.tracks){if(Thread.currentThread().isInterrupted())throw new IllegalStateException("Operação cancelada");Track match=null;int count=0;for(Track candidate:index.getOrDefault(identity(t),Collections.emptyList()))if(Math.abs(candidate.duration-t.duration)<=1500&&(SearchText.normalize(t.album).isEmpty()||SearchText.normalize(t.album).equals(SearchText.normalize(candidate.album)))){match=candidate;count++;}if(count==1){remap.put(t.id,match.id);p.matched++;}else if(count==0)p.missing++;else p.ambiguous++;}
  for(PlaylistStore.Entry imported:source.lists){PlaylistStore.Entry target=null;for(PlaylistStore.Entry e:p.lists)if(SearchText.normalize(e.name).equals(SearchText.normalize(imported.name))){target=e;break;}if(target==null){if(p.lists.size()>=100){p.conflicts++;continue;}target=new PlaylistStore.Entry(UUID.randomUUID().toString(),imported.name);p.lists.add(target);p.addedLists++;}for(String key:imported.songs){String id=remap.get(key);if(id==null||target.songs.contains(id))continue;if(target.songs.size()>=2000){p.conflicts++;continue;}target.songs.add(id);p.addedSongs++;}}
  for(String key:source.favorites){String id=remap.get(key);if(id!=null&&p.favorites.add(id))p.addedFavorites++;}
  for(VoicePhraseBook.Entry e:source.phrases.entries){VoiceCommand existing=p.phrases.find(e.phrase);if(existing!=null){if(existing.action!=e.command.action||existing.minutes!=e.command.minutes||!existing.query.equals(e.command.query))p.conflicts++;continue;}try{p.phrases.put(null,e.phrase,e.command.action,e.command.query,e.command.minutes);p.addedPhrases++;}catch(IllegalArgumentException ex){p.conflicts++;}}
  return p;
 }
}
