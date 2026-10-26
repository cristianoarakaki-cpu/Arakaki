package br.com.onda;
/** Linked-channel speech dynamics; original samples bypass the processor when disabled. */
final class SpeechDsp {
 private final double[] previous,high,low;private final double highPass,lowPass,attack,release,blendStep;
 private double envelope,gain=1,mix;private int frame;
 SpeechDsp(int rate,int channels){if(rate<8000||rate>384000||channels<1||channels>8)throw new IllegalArgumentException();previous=new double[channels];high=new double[channels];low=new double[channels];highPass=Math.exp(-2*Math.PI*80/rate);lowPass=Math.exp(-2*Math.PI*1200/rate);attack=Math.exp(-1.0/(rate*.005));release=Math.exp(-1.0/(rate*.15));blendStep=1.0/(rate*.02);}
 boolean bypassed(){return mix==0;}
 void process(short[] samples,boolean enabled){
  if(!enabled&&mix==0)return;mix=enabled?Math.min(1,mix+blendStep):Math.max(0,mix-blendStep);double peak=0;
  for(int c=0;c<samples.length;c++){double x=samples[c]/32768.0;high[c]=highPass*(high[c]+x-previous[c]);previous[c]=x;low[c]=lowPass*low[c]+(1-lowPass)*high[c];peak=Math.max(peak,Math.abs(high[c]+.18*(high[c]-low[c])));}
  double coefficient=peak>envelope?attack:release;envelope=coefficient*envelope+(1-coefficient)*peak;
  if((frame++&15)==0)gain=1.7*(envelope>.16?Math.pow(envelope/.16,-.70):1);
  // A shared peak guard keeps stereo balance and avoids clipping transient peaks.
  double applied=peak*gain>.92?.92/peak:gain;
  for(int c=0;c<samples.length;c++){double processed=(high[c]+.18*(high[c]-low[c]))*applied;double result=(1-mix)*(samples[c]/32768.0)+mix*processed;samples[c]=(short)Math.max(Short.MIN_VALUE,Math.min(Short.MAX_VALUE,Math.round(result*32768)));}
  if(mix==0){java.util.Arrays.fill(previous,0);java.util.Arrays.fill(high,0);java.util.Arrays.fill(low,0);envelope=0;gain=1;frame=0;}
 }
}
