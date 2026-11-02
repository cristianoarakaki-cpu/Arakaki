package br.com.onda;
/** Linked stereo/multichannel gain for quiet passages. No timers, allocations or whole-file analysis. */
final class QuietDsp {
 private final double attack,release,rise,fall,mixStep;private double envelope,gain=1,mix;
 QuietDsp(int rate){if(rate<8000||rate>384000)throw new IllegalArgumentException();attack=Math.exp(-1.0/(rate*.005));release=Math.exp(-1.0/(rate*.12));rise=1-Math.exp(-1.0/(rate*.08));fall=1-Math.exp(-1.0/(rate*.002));mixStep=1.0/(rate*.02);}
 boolean bypassed(){return mix==0;}
 void process(short[] frame,int level){int selected=Math.max(0,Math.min(3,level));if(selected==0&&mix==0)return;mix=selected>0?Math.min(1,mix+mixStep):Math.max(0,mix-mixStep);double peak=0;for(short sample:frame)peak=Math.max(peak,Math.abs(sample/32768.0));double coefficient=peak>envelope?attack:release;envelope=coefficient*envelope+(1-coefficient)*peak;
  double maximum=selected==1?1.412537545:selected==2?1.995262315:selected==3?2.818382931:1;double target=envelope<.001?1:1+(maximum-1)*Math.max(0,1-envelope/.25);gain+=(target-gain)*(target<gain?fall:rise);double applied=peak*gain>.92?.92/peak:gain;
  for(int i=0;i<frame.length;i++){double value=frame[i]*(1+mix*(applied-1));frame[i]=(short)Math.max(Short.MIN_VALUE,Math.min(Short.MAX_VALUE,Math.round(value)));}if(mix==0){gain=1;envelope=0;}
 }
}
