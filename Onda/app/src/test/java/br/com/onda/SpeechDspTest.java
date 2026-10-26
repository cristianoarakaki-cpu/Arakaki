package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
public class SpeechDspTest {
 private double rms(double amplitude){SpeechDsp dsp=new SpeechDsp(48000,1);double sum=0;short[] f=new short[1];for(int n=0;n<96000;n++){f[0]=(short)Math.round(amplitude*32767*Math.sin(2*Math.PI*400*n/48000));dsp.process(f,true);if(n>=48000)sum+=(double)f[0]*f[0];}return Math.sqrt(sum/48000)/32768;}
 @Test public void disabledPreservesEverySample(){SpeechDsp dsp=new SpeechDsp(48000,2);for(int n=Short.MIN_VALUE;n<=Short.MAX_VALUE;n++){short[] f={(short)n,(short)-n};short a=f[0],b=f[1];dsp.process(f,false);assertEquals(a,f[0]);assertEquals(b,f[1]);}}
 @Test public void boostsQuietSpeechAndNarrowsLoudnessDifference(){double quiet=rms(.03),loud=rms(.85);assertTrue(quiet>.03/Math.sqrt(2)*1.25);assertTrue(loud<.85/Math.sqrt(2)*.85);assertTrue(loud/quiet<18);}
 @Test public void linkedGainPreservesStereoBalance(){SpeechDsp dsp=new SpeechDsp(48000,2);short[] f=new short[2];for(int n=0;n<48000;n++){f[0]=(short)(30000*Math.sin(2*Math.PI*400*n/48000));f[1]=(short)(f[0]/2);dsp.process(f,true);if(n>2000)assertTrue(Math.abs(f[0]-2*f[1])<=5);}}
 @Test public void settledPeakGuardPreventsClipping(){SpeechDsp dsp=new SpeechDsp(48000,1);short[] f=new short[1];for(int n=0;n<2000;n++)dsp.process(f,true);for(int n=0;n<10000;n++){f[0]=(short)(n%2==0?32767:-32768);dsp.process(f,true);assertTrue(Math.abs((int)f[0])<=30148);}}
 @Test public void turningOffReturnsToExactOriginalSamples(){SpeechDsp dsp=new SpeechDsp(48000,1);short[] f=new short[1];for(int n=0;n<3000;n++){f[0]=1000;dsp.process(f,true);}for(int n=0;n<2000;n++){f[0]=1234;dsp.process(f,false);}assertTrue(dsp.bypassed());for(short v:new short[]{Short.MIN_VALUE,-1,0,1,Short.MAX_VALUE}){f[0]=v;dsp.process(f,false);assertEquals(v,f[0]);}}
 @Test public void zeroInputStaysSilent(){SpeechDsp dsp=new SpeechDsp(16000,1);short[] f={0};for(int n=0;n<16000;n++){dsp.process(f,true);assertEquals(0,f[0]);}}
}
