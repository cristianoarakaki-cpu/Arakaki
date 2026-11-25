package br.com.onda;
import org.junit.Test;import static org.junit.Assert.*;
public class RestorationDspTest {
 private double tone(int profile,double hz,double amplitude){int rate=48000;short[] pcm=new short[rate];for(int i=0;i<pcm.length;i++)pcm[i]=(short)(Math.sin(2*Math.PI*hz*i/rate)*amplitude*32767);new RestorationDsp(rate,1,profile).process(pcm,pcm.length);double sum=0;for(int i=rate/2;i<rate;i++)sum+=(double)pcm[i]*pcm[i];return Math.sqrt(sum/(rate/2));}
 @Test public void voiceAttenuatesRumbleAndHissAndKeepsSpeechBand(){double reference=tone(1,1000,.2);assertTrue(reference>4000);assertTrue(tone(1,10,.2)<reference*.04);assertTrue(tone(1,18000,.2)<reference*.05);assertTrue(tone(2,10000,.2)>tone(1,10000,.2)*2);}
 @Test public void quietNoiseIsReducedWithoutHardGate(){double result=tone(1,1000,.001);assertTrue(result>6);assertTrue(result<15);}
 @Test public void stereoBalanceAndSilenceRemainStable(){short[] pcm=new short[96000];for(int i=0;i<48000;i++){pcm[i*2]=(short)(12000*Math.sin(i*.13));pcm[i*2+1]=(short)(pcm[i*2]/2);}new RestorationDsp(48000,2,2).process(pcm,pcm.length);for(int i=10000;i<pcm.length;i+=2)assertEquals(pcm[i]/2.0,pcm[i+1],2);short[] silence=new short[8000];new RestorationDsp(8000,1,1).process(silence,silence.length);assertArrayEquals(new short[8000],silence);}
 @Test public void peakProtectionAlsoWorksAcrossBlocks(){RestorationDsp dsp=new RestorationDsp(44100,2,1);short[] pcm=new short[8000];for(int round=0;round<5;round++){for(int i=0;i<pcm.length;i++)pcm[i]=(short)(i%4<2?32767:-32768);dsp.process(pcm,pcm.length);for(short value:pcm)assertTrue(Math.abs((int)value)<=31786);}}
}
