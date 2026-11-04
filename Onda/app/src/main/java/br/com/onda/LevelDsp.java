package br.com.onda;

/** Streaming RMS gain, linked channels and a sample-peak guard. No file scan or look-ahead. */
final class LevelDsp {
 private final int window;private final double down,up,limiterRelease,mixStep;
 private int count;private double energy,target=1,gain=1,limit=1,mix;
 LevelDsp(int rate){if(rate<8000||rate>384000)throw new IllegalArgumentException();window=Math.max(1,rate*2/5);down=1-Math.exp(-1.0/(rate*.2));up=1-Math.exp(-1.0/(rate*3.0));limiterRelease=1-Math.exp(-1.0/(rate*.12));mixStep=1.0/(rate*.02);}
 boolean bypassed(){return mix==0;}
 float gainDb(){return (float)(20*Math.log10(Math.max(.001,1+mix*(gain*limit-1))));}
 void process(short[] samples,boolean enabled){
  if(!enabled&&mix==0)return;
  mix=enabled?Math.min(1,mix+mixStep):Math.max(0,mix-mixStep);
  double peak=0,sum=0;for(short sample:samples){double value=sample/32768.0;sum+=value*value;peak=Math.max(peak,Math.abs(value));}
  energy+=sum/samples.length;
  if(++count>=window){double rms=Math.sqrt(energy/count);target=rms<.006?1:Math.max(.25,Math.min(2,.16/rms));count=0;energy=0;}
  gain+=(target-gain)*(target<gain?down:up);
  double safe=peak*gain>.92?.92/(peak*gain):1;
  if(safe<limit)limit=safe;else limit+=(safe-limit)*limiterRelease;
  double applied=1+mix*(gain*limit-1);
  for(int i=0;i<samples.length;i++)samples[i]=(short)Math.max(Short.MIN_VALUE,Math.min(Short.MAX_VALUE,Math.round(samples[i]*applied)));
  if(mix==0){count=0;energy=0;target=gain=limit=1;}
 }
}
