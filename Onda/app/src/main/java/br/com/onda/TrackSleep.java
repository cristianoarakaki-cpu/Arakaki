package br.com.onda;
/** Counts natural ends only; pauses and skips never call completed(). */
final class TrackSleep {
 private int remaining;
 void arm(int tracks){remaining=Math.max(0,Math.min(20,tracks));}
 int remaining(){return remaining;}
 boolean completed(){if(remaining==0)return false;return --remaining==0;}
}
