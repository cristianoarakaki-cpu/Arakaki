package br.com.onda;

final class FadeMath {
    static float gain(long elapsed,long duration,float from,float to){double t=duration<=0?1:Math.max(0,Math.min(1,(double)elapsed/duration));double smooth=(1-Math.cos(Math.PI*t))/2;return (float)Math.max(0,Math.min(1,from+(to-from)*smooth));}
    static long delay(long duration,long position,float speed,int fade){if(duration<=0||fade<=0||duration<=fade*2L||speed<=0||Float.isNaN(speed)||Float.isInfinite(speed))return -1;return Math.max(0,(long)((duration-Math.max(0,position)-fade)/speed));}
}
