package br.com.onda;
import java.util.List;
/** Cadence only: never changes media quality, playback speed or transfer limits. */
final class PowerPolicy {
 static final long BACKGROUND_STATE_MS=15000;
 static long progressInterval(boolean visible){return visible?1000:10000;}
 static long lyricDelay(List<Lrc.Line> lines,int active,long position,float speed,long manualRemaining,boolean scrollPending){
  long delay=-1;int next=active+1;
  if(next>=0&&next<lines.size()){double rate=Float.isFinite(speed)&&speed>0?speed:1;double left=(lines.get(next).ms-Math.max(0,position))/rate;delay=Math.max(25,Math.min(60000,(long)Math.ceil(left)));}
  if(scrollPending&&manualRemaining>0){long resume=Math.max(25,Math.min(60000,manualRemaining));delay=delay<0?resume:Math.min(delay,resume);}return delay;
 }
}
