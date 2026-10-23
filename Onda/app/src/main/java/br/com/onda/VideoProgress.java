package br.com.onda;
/** Positions near the beginning/end intentionally restart rather than offer a stale bookmark. */
final class VideoProgress {
    static long resume(long position,long storedDuration,long currentDuration){
        long duration=currentDuration>0?currentDuration:storedDuration;
        if(duration<=0||position<3000||position>=duration-Math.min(15000,Math.max(2000,duration/20)))return 0;
        if(storedDuration>0&&currentDuration>0&&Math.abs(storedDuration-currentDuration)>Math.max(2000,currentDuration/20))return 0;
        return position;
    }
    static float brightness(float start,float fraction){return Math.max(.02f,Math.min(1f,start+fraction));}
    static int volume(int start,float fraction){return Math.max(0,Math.min(100,Math.round(start+fraction*100)));}
}
