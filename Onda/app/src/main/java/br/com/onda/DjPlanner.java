package br.com.onda;

import java.util.*;

/** Local, explainable weighted selection. No audio analysis or remote recommendation service. */
final class DjPlanner {
    enum Mode { PERSONAL, FAVORITES, REDISCOVER, TRAVEL, DOWNLOADS }
    static final class Song {
        final String id,title,artist;final long duration,last;final int count,completed;final boolean favorite;
        Song(String id,String title,String artist,long duration,int count,long last,boolean favorite){this(id,title,artist,duration,count,last,favorite,0);}
        Song(String id,String title,String artist,long duration,int count,long last,boolean favorite,int completed){this.completed=Math.max(0,completed);this.id=id;this.title=title;this.artist=artist;this.duration=duration;this.count=Math.max(0,count);this.last=Math.max(0,last);this.favorite=favorite;}
        String artistKey(){String value=SearchText.normalize(artist);return value.isEmpty()||value.equals("artista desconhecido")||value.equals("download local")||value.equals("unknown")||value.equals("null")?"":value;}
    }
    private static final class Candidate {final Song song;final double weight;Candidate(Song song,double weight){this.song=song;this.weight=weight;}}
    static List<Song> build(List<Song> library,Mode mode,int limit,long seed,long now){
        return build(library,mode,limit,seed,now,Collections.emptySet(),false,false,"");
    }
    static List<Song> build(List<Song> library,Mode mode,int limit,long seed,long now,Set<String> excluded,boolean strictArtist,boolean variety,String preferredArtist){
        List<Song> result=new ArrayList<>();if(limit<=0)return result;limit=Math.min(60,limit);
        List<Candidate> pool=new ArrayList<>();Set<String> ids=new HashSet<>();Map<String,List<Song>> versions=new HashMap<>();
        for(Song song:library){
            if(Thread.currentThread().isInterrupted())return result;
            if(song==null||song.id==null||song.id.isEmpty()||(song.duration<=0&&!song.id.startsWith("download:"))||excluded.contains(song.id)||(mode==Mode.FAVORITES&&!song.favorite)||!ids.add(song.id))continue;
            String title=SearchText.normalize(song.title),artist=song.artistKey();
            if(song.duration>0&&!title.isEmpty()&&!title.equals("sem titulo")&&!title.equals("null")&&!artist.isEmpty()){
                List<Song> same=versions.computeIfAbsent(title+"|"+artist,k->new ArrayList<>());boolean duplicate=false;
                for(int i=0;i<same.size();i++){Song other=same.get(i);if(Math.abs(song.duration-other.duration)<=1500){duplicate=true;if(song.favorite&&!other.favorite){same.set(i,song);pool.removeIf(c->c.song==other);pool.add(new Candidate(song,tunedWeight(song,mode,now,variety,preferredArtist)));}break;}}
                if(duplicate)continue;same.add(song);
            }
            pool.add(new Candidate(song,tunedWeight(song,mode,now,variety,preferredArtist)));
        }
        Random random=new Random(seed);Deque<String> recentArtists=new ArrayDeque<>();Set<String> usedArtists=new HashSet<>();
        while(!pool.isEmpty()&&result.size()<limit){
            if(Thread.currentThread().isInterrupted())return result;
            if(strictArtist)pool.removeIf(c->!c.song.artistKey().isEmpty()&&usedArtists.contains(c.song.artistKey()));
            if(pool.isEmpty())break;
            boolean spaced=false;for(Candidate c:pool)if(c.song.artistKey().isEmpty()||!recentArtists.contains(c.song.artistKey())){spaced=true;break;}
            String previous=result.isEmpty()?"":result.get(result.size()-1).artistKey();boolean alternate=false;
            if(!spaced)for(Candidate c:pool)if(c.song.artistKey().isEmpty()||!c.song.artistKey().equals(previous)){alternate=true;break;}
            double total=0;for(Candidate c:pool)if(allowed(c,spaced,alternate,recentArtists,previous))total+=c.weight;
            double choice=random.nextDouble()*total;Candidate selected=null;
            for(Candidate c:pool)if(allowed(c,spaced,alternate,recentArtists,previous)){selected=c;choice-=c.weight;if(choice<=0)break;}
            if(selected==null)break;result.add(selected.song);pool.remove(selected);
            usedArtists.add(selected.song.artistKey());recentArtists.addLast(selected.song.artistKey());while(recentArtists.size()>(variety?4:2))recentArtists.removeFirst();
        }
        return result;
    }
    private static boolean allowed(Candidate c,boolean spaced,boolean alternate,Deque<String> recent,String previous){String artist=c.song.artistKey();return artist.isEmpty()||(spaced?!recent.contains(artist):!alternate||!artist.equals(previous));}
    private static double tunedWeight(Song song,Mode mode,long now,boolean variety,String preferredArtist){
        double value=weight(song,mode,now);
        if(variety)value*=song.count==0?3:1.0/(1+Math.log1p(song.count));
        if(!preferredArtist.isEmpty()&&song.artistKey().equals(preferredArtist))value*=8;
        return value;
    }
    static String explain(Song song,Mode mode,long now){
        if(song.favorite)return song.completed>0?"Favorita • você já ouviu até o fim "+song.completed+" vez(es) no Onda":"Está nas suas favoritas";
        if(song.completed>0)return "Você já ouviu até o fim "+song.completed+" vez(es) no Onda";
        if(song.id.startsWith("download:"))return "Áudio baixado no Onda";
        if(song.count==0)return "Ainda sem escuta registrada no Onda";
        long days=song.last>0?Math.max(0,(now-song.last)/86400000):0;
        if(days>=7)return "Para redescobrir • última escuta há "+days+" dias";
        return "Para variar sua seleção local";
    }
    static double weight(Song song,Mode mode,long now){
        double age=song.last==0?365:Math.max(0,(now-song.last)/86400000.0);
        double weight=mode==Mode.REDISCOVER?(1+Math.min(90,age)/15)/(1+Math.log1p(song.count)):(song.favorite?4:1)*(1+Math.min(2,Math.log1p(song.count)/2));
        if(song.last>0)weight*=age<2.0/24?.15:age<1?.4:1;
        weight*=1+Math.min(2,Math.log1p(song.completed));
        if(mode==Mode.TRAVEL)weight*=song.favorite||song.completed>0?2:1;
        if(mode==Mode.DOWNLOADS)weight*=song.id.startsWith("download:")?4:1+Math.min(60,age)/20;
        return Math.max(.01,weight);
    }
}
