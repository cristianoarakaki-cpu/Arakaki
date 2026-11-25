package br.com.onda;
/** Bounded, local cleanup. Gentle filters and linked expansion, not lost-detail reconstruction. */
final class RestorationDsp {
 static final int NONE=0,VOICE=1,MUSIC=2;
 static boolean valid(int profile){return profile>=NONE&&profile<=MUSIC;}
 private final int channels;private final Biquad[] high,low;private final double attack,release,opening,closing,threshold,floor,limiterRelease;
 private double envelope,gain=1,limit=1;
 RestorationDsp(int rate,int channels,int profile){
  if(rate<8000||rate>192000||channels<1||channels>2||profile<1||profile>2)throw new IllegalArgumentException("Perfil de restauração inválido");
  this.channels=channels;boolean voice=profile==VOICE;high=new Biquad[channels];low=new Biquad[channels];
  for(int c=0;c<channels;c++){high[c]=new Biquad(rate,voice?70:25,true);low[c]=new Biquad(rate,Math.min(rate*.43,voice?6500:14000),false);}
  attack=coefficient(rate,.005);release=coefficient(rate,.1);opening=coefficient(rate,.002);closing=coefficient(rate,.08);limiterRelease=coefficient(rate,.2);threshold=voice?.006:.002;floor=voice?.45:.65;
 }
 private static double coefficient(int rate,double seconds){return Math.exp(-1/(rate*seconds));}
 void process(short[] pcm,int count){
  if(count<0||count>pcm.length||count%channels!=0)throw new IllegalArgumentException("PCM inválido");
  // One frame on the stack as scalars: no allocations in the audio loop.
  for(int i=0;i<count;i+=channels){
   double left=low[0].next(high[0].next(pcm[i]/32768.0));double right=channels==2?low[1].next(high[1].next(pcm[i+1]/32768.0)):0;
   double peak=Math.max(Math.abs(left),Math.abs(right)),a=peak>envelope?attack:release;envelope=a*envelope+(1-a)*peak;
   double ratio=Math.min(1,envelope/threshold),target=floor+(1-floor)*ratio*ratio;a=target>gain?opening:closing;gain=a*gain+(1-a)*target;
   double wanted=peak*gain>.97?.97/(peak*gain):1;limit=wanted<limit?wanted:limiterRelease*limit+(1-limiterRelease)*wanted;
   pcm[i]=sample(left*gain*limit);if(channels==2)pcm[i+1]=sample(right*gain*limit);
  }
 }
 private static short sample(double x){return (short)Math.max(-32768,Math.min(32767,Math.round(x*32768)));}
 private static final class Biquad {
  final double b0,b1,b2,a1,a2;double z1,z2;
  Biquad(int rate,double frequency,boolean high){double w=2*Math.PI*frequency/rate,c=Math.cos(w),alpha=Math.sin(w)/Math.sqrt(2),a0=1+alpha;
   b0=(high?(1+c):(1-c))/2/a0;b1=(high?-(1+c):(1-c))/a0;b2=b0;a1=-2*c/a0;a2=(1-alpha)/a0;}
  double next(double x){double y=b0*x+z1;z1=b1*x-a1*y+z2;z2=b2*x-a2*y;return y;}
 }
}
