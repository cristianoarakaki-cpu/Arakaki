package br.com.onda;
final class PlaybackContinuity {
 static long resume(long position,long duration,boolean ended){long p=Math.max(0,position);return ended||duration>0&&p>=Math.max(0,duration-250)?0:p;}
}
