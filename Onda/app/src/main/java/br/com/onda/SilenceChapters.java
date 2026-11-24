package br.com.onda;

import java.util.*;

/** Conservative pause boundaries, not song recognition. Times are positions in the original audio. */
final class SilenceChapters {
    static final long MIN_TRACK_MS=30000,SILENCE_MS=1500;
    static final double QUIET_POWER=Math.pow(10,-4.5); // -45 dBFS RMS
    private final long minTrack,silence;
    private final double ceiling,relative;private final long confirmation;private double reference;private long onset=-1;
    private final ArrayList<Long> starts=new ArrayList<>();
    private long quietStart=-1,lastEnd;
    SilenceChapters(){this(MIN_TRACK_MS,SILENCE_MS);}
    SilenceChapters(long minTrack,long silence){this(minTrack,silence,QUIET_POWER,0,0);}
    SilenceChapters(int mode){this(mode==0?30000:mode==1?25000:20000,mode==0?1500:mode==1?1200:700,mode==0?QUIET_POWER:Math.pow(10,mode==1?-3.6:-3.2),mode==0?0:Math.pow(10,mode==1?-2:-1.6),mode==0?0:500);if(mode<0||mode>2)throw new IllegalArgumentException();}
    private SilenceChapters(long minTrack,long silence,double ceiling,double relative,long confirmation){if(minTrack<1||silence<1)throw new IllegalArgumentException();this.minTrack=minTrack;this.silence=silence;this.ceiling=ceiling;this.relative=relative;this.confirmation=confirmation;starts.add(0L);}
    void window(long start,long length,double power){
        if(start<0||length<1||!Double.isFinite(power)||power<0)throw new IllegalArgumentException();if(start<lastEnd-2)throw new IllegalArgumentException("Audio timestamps moved backwards");
        if(quietStart>=0&&start>lastEnd+250){quietStart=-1;onset=-1;}lastEnd=Math.max(lastEnd,start+length);
        if(quietStart<0)reference=Math.max(power,reference*Math.exp(-length/30000.0));
        double threshold=relative==0?ceiling:Math.min(ceiling,reference*relative);
        if(power<=threshold){if(quietStart<0)quietStart=start;onset=-1;return;}
        if(quietStart<0)return;
        if(onset<0)onset=start;
        if(start+length-onset<confirmation)return;
        if(onset-quietStart>=silence&&quietStart-starts.get(starts.size()-1)>=minTrack){long cut=Math.max(quietStart,onset-150);starts.add(cut);}
        quietStart=-1;onset=-1;reference=Math.max(power,reference);
    }
    List<Long> finish(long duration){long end=Math.max(duration,lastEnd);ArrayList<Long> result=new ArrayList<>(starts);while(result.size()>1&&end-result.get(result.size()-1)<minTrack)result.remove(result.size()-1);return result;}
}
