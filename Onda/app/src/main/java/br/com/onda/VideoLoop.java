package br.com.onda;
import java.util.Locale;
/** In-memory A–B range with bounded seek retries; no scheduler or background work. */
final class VideoLoop {
 static final long NONE=-1,FAILED=-2,MAX_TIME=604800000L;
 private long a,b,lastRequest;private boolean active,waiting;private int attempts;
 boolean active(){return active;}boolean waiting(){return waiting;}long start(){return a;}long end(){return b;}
 boolean arm(long start,long end,long duration){if(start<0||start>MAX_TIME||end<0||end>MAX_TIME||duration<=0||end>duration||end<=start||end-start<2000)return false;a=start;b=end;active=true;waiting=false;attempts=0;return true;}
 void clear(){active=false;waiting=false;attempts=0;a=0;b=0;}
 boolean manualSeek(long position){if(!active)return false;if(position<a||position>=b){clear();return true;}waiting=false;attempts=0;return false;}
 long correct(long position,long now){if(!active||position<0)return NONE;if(position>=a&&position<b){waiting=false;attempts=0;return NONE;}if(waiting&&now-lastRequest<1500)return NONE;return request(now);}
 long atEnd(long now){return active?request(now):NONE;}
 private long request(long now){if(++attempts>3){clear();return FAILED;}waiting=true;lastRequest=now;return a;}
 static long parse(String raw){if(raw==null)return NONE;String text=raw.trim();if(text.isEmpty()||text.length()>16||!text.matches("[0-9]+(?::[0-9]{1,2}){0,2}"))return NONE;String[] parts=text.split(":");try{long seconds=Long.parseLong(parts[0]);for(int i=1;i<parts.length;i++){int n=Integer.parseInt(parts[i]);if(n>59)return NONE;seconds=seconds*60+n;}return seconds<=MAX_TIME/1000?seconds*1000:NONE;}catch(NumberFormatException e){return NONE;}}
 static String time(long ms){long seconds=Math.max(0,ms)/1000;return seconds>=3600?String.format(Locale.ROOT,"%d:%02d:%02d",seconds/3600,seconds/60%60,seconds%60):String.format(Locale.ROOT,"%d:%02d",seconds/60,seconds%60);}
}
