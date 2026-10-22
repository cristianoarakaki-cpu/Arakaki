package br.com.onda;

import java.util.*;

final class LibraryIntelligence {
    static final class Song {
        final String id,title,artist;final long duration;
        Song(String id,String title,String artist,long duration){this.id=id;this.title=title;this.artist=artist;this.duration=duration;}
    }
    /** Similar metadata suggests duplicates; audio is not compared and nothing is deleted. */
    static List<List<Song>> duplicates(List<Song> songs){
        Map<String,List<Song>> buckets=new LinkedHashMap<>();Set<String> seen=new HashSet<>();
        for(Song s:songs){String title=SearchText.normalize(s.title),artist=SearchText.normalize(s.artist);if(!seen.add(s.id)||s.duration<=0||title.isEmpty()||title.equals("sem titulo")||artist.isEmpty()||artist.equals("artista desconhecido")||artist.equals("unknown"))continue;buckets.computeIfAbsent(title+"|"+artist,k->new ArrayList<>()).add(s);}
        List<List<Song>> result=new ArrayList<>();
        for(List<Song> bucket:buckets.values()){
            bucket.sort(Comparator.comparingLong(s->s.duration));List<Song> group=new ArrayList<>();long anchor=-1;
            for(Song s:bucket){if(anchor<0||s.duration-anchor<=1500){if(anchor<0)anchor=s.duration;group.add(s);}else{if(group.size()>1)result.add(group);group=new ArrayList<>();group.add(s);anchor=s.duration;}}
            if(group.size()>1)result.add(group);
        }
        return result;
    }
}
