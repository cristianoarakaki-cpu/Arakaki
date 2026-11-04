package br.com.onda;

/** Collapse duplicate player callbacks without extending the existing 15-second resume cadence. */
final class ShelfCheckpoint {
 private String key="";private long position=-1,duration=-1,at=-1;
 boolean save(String next,long p,long d,long now){
  if(next.equals(key)&&p==position&&d==duration&&now>=at&&now-at<1000)return false;
  key=next;position=p;duration=d;at=now;return true;
 }
}
