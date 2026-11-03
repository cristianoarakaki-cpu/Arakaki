package br.com.onda;

import java.util.*;

/** Conservative pause boundaries, not song recognition. Times are positions in the original audio. */
final class SilenceChapters {
    static final long MIN_TRACK_MS=30000,SILENCE_MS=1500;
    static final double QUIET_POWER=Math.pow(10,-4.5); // -45 dBFS RMS
    private final long minTrack,silence;
    private final ArrayList<Long> starts=new ArrayList<>();
    private long quietStart=-1,lastEnd;
    SilenceChapters(){this(MIN_TRACK_MS,SILENCE_MS);}
    SilenceChapters(long minTrack,long silence){if(minTrack<1||silence<1)throw new IllegalArgumentException();this.minTrack=minTrack;this.silence=silence;starts.add(0L);}
    void window(long start,long length,double power){if(start<0||length<1||!Double.isFinite(power)||power<0)throw new IllegalArgumentException();if(start<lastEnd-2)throw new IllegalArgumentException("Audio timestamps moved backwards");if(quietStart>=0&&start>lastEnd+250)quietStart=-1;lastEnd=Math.max(lastEnd,start+length);if(power<=QUIET_POWER){if(quietStart<0)quietStart=start;return;}if(quietStart>=0&&start-quietStart>=silence&&quietStart-starts.get(starts.size()-1)>=minTrack){long cut=Math.max(quietStart,start-150);starts.add(cut);}quietStart=-1;}
    List<Long> finish(long duration){long end=Math.max(duration,lastEnd);ArrayList<Long> result=new ArrayList<>(starts);while(result.size()>1&&end-result.get(result.size()-1)<minTrack)result.remove(result.size()-1);return result;}
}
