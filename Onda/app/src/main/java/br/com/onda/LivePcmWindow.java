package br.com.onda;
import java.nio.*;
/** Audio-thread-only downmix/resampler; bounded 8s windows with 2s overlap. */
final class LivePcmWindow {
 interface Output {void ready(float[] pcm,long endSample);}
 static final int RATE=16000,SAMPLES=RATE*8,OVERLAP=RATE*2;
 private final int rate,channels;private final Output output;private final byte[] partial;private int partialCount,count;private long inputIndex,total;private double next;private float previous;private float[] samples=new float[SAMPLES];
 LivePcmWindow(int rate,int channels,Output output){if(rate<8000||rate>384000||channels<1||channels>8)throw new IllegalArgumentException();this.rate=rate;this.channels=channels;this.output=output;partial=new byte[channels*2];}
 void accept(ByteBuffer pcm){while(pcm.hasRemaining()){int n=Math.min(partial.length-partialCount,pcm.remaining());pcm.get(partial,partialCount,n);partialCount+=n;if(partialCount<partial.length)break;int sum=0;for(int c=0;c<channels;c++)sum+=(short)((partial[c*2]&255)|(partial[c*2+1]<<8));partialCount=0;float value=(float)(sum/(32768.0*channels));while(next<=inputIndex){float out=inputIndex==0?value:previous+(value-previous)*(float)(next-(inputIndex-1));samples[count++]=out;total++;next+=(double)rate/RATE;if(count==SAMPLES){float[] complete=samples;samples=new float[SAMPLES];System.arraycopy(complete,SAMPLES-OVERLAP,samples,0,OVERLAP);count=OVERLAP;output.ready(complete,total);}}previous=value;inputIndex++;}}
 static boolean audible(float[] pcm){double energy=0;for(float f:pcm)energy+=f*f;return pcm.length>0&&energy/pcm.length>.000009;}
}
