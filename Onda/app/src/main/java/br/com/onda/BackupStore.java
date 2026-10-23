package br.com.onda;
import android.content.*;
import androidx.media3.common.MediaItem;
import java.util.*;
@androidx.media3.common.util.UnstableApi
final class BackupStore {
 static List<BackupData.Track> tracks(Context c){List<BackupData.Track> out=new ArrayList<>();for(MediaItem m:LibraryStore.scan(c))out.add(new BackupData.Track(m.mediaId,String.valueOf(m.mediaMetadata.title),String.valueOf(m.mediaMetadata.artist),m.mediaMetadata.albumTitle==null?"":m.mediaMetadata.albumTitle.toString(),LibraryStore.number(m,"durationMs")));return out;}
 static BackupData.Archive snapshot(Context c){BackupData.Archive a=new BackupData.Archive();Map<String,BackupData.Track> available=new HashMap<>();for(BackupData.Track t:tracks(c))available.put(t.id,t);Set<String> references=new LinkedHashSet<>();
  for(PlaylistStore.Entry e:PlaylistStore.read(c)){PlaylistStore.Entry copy=new PlaylistStore.Entry(e.id,e.name);for(String id:e.songs)if(available.containsKey(id)){copy.songs.add(id);references.add(id);}else a.unavailable++;a.lists.add(copy);}
  for(String id:c.getSharedPreferences("library",0).getStringSet("favorites",Collections.emptySet()))if(available.containsKey(id)){a.favorites.add(id);references.add(id);}else a.unavailable++;
  for(String id:references)a.tracks.add(available.get(id));if(a.tracks.size()>BackupData.MAX_TRACKS)throw new IllegalArgumentException("O backup excede 20.000 músicas referenciadas.");a.phrases=VoicePhrases.read(c);return a;
 }
 static BackupData.Plan plan(Context c,BackupData.Archive a,List<BackupData.Track> available){return BackupData.merge(a,available,PlaylistStore.read(c),new HashSet<>(c.getSharedPreferences("library",0).getStringSet("favorites",Collections.emptySet())),VoicePhrases.read(c));}
 static void apply(Context c,BackupData.Plan p){PlaylistStore.save(c,p.lists);c.getSharedPreferences("library",0).edit().putStringSet("favorites",p.favorites).apply();c.getSharedPreferences("voice_phrases",0).edit().putString("entries",p.phrases.json()).apply();}
}
