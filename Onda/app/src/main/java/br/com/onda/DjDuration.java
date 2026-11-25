package br.com.onda;

import java.util.*;

/** Whole-track duration budget at 1x. Uses metadata only, on the existing DJ worker. */
final class DjDuration {
    private static final int[] MINUTES={0,0,0,15,30,60,90};
    static int minutes(int index){return index>=0&&index<MINUTES.length?MINUTES[index]:0;}
    static List<DjPlanner.Song> plan(List<DjPlanner.Song> library,DjPlanner.Mode mode,int minutes,long seed,long now){
        if(minutes<=0||minutes>1440)throw new IllegalArgumentException("Duração inválida");
        long budget=minutes*60000L;List<DjPlanner.Song> eligible=new ArrayList<>();
        for(DjPlanner.Song song:library){if(Thread.currentThread().isInterrupted())return Collections.emptyList();if(song!=null&&song.duration>0&&song.duration<=budget)eligible.add(song);}
        List<DjPlanner.Song> ranked=DjPlanner.build(eligible,mode,60,seed,now),result=new ArrayList<>();
        long used=0;for(DjPlanner.Song song:ranked)if(song.duration<=budget-used){result.add(song);used+=song.duration;}
        return result;
    }
    static String time(long duration){long seconds=Math.max(0,duration)/1000;long hours=seconds/3600,minutes=seconds/60%60;return hours>0?hours+" h "+minutes+" min":seconds>=60?seconds/60+" min "+seconds%60+" s":seconds+" s";}
    private DjDuration(){}
}
