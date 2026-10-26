package br.com.onda;
import androidx.media3.common.C;
import androidx.media3.common.audio.AudioProcessor;
import java.nio.*;
import java.io.*;
import org.junit.Test;
import static org.junit.Assert.*;
@androidx.media3.common.util.UnstableApi
public class SpeechProcessorTest {
 @Test public void disabledFragmentedStereoIsBitExact()throws Exception{SpeechProcessor p=new SpeechProcessor();p.configure(new AudioProcessor.AudioFormat(48000,2,C.ENCODING_PCM_16BIT));p.flush();byte[] input=new byte[4096];new java.util.Random(42).nextBytes(input);ByteArrayOutputStream out=new ByteArrayOutputStream();for(int at=0;at<input.length;){int n=Math.min(13,input.length-at);ByteBuffer b=ByteBuffer.allocateDirect(n);b.put(input,at,n).flip();p.queueInput(b);ByteBuffer result=p.getOutput();while(result.hasRemaining())out.write(result.get());at+=n;}p.queueEndOfStream();ByteBuffer tail=p.getOutput();while(tail.hasRemaining())out.write(tail.get());assertArrayEquals(input,out.toByteArray());assertEquals(0,p.processedFrames);p.reset();}
 @Test public void enabledPcmReachesDspAndFlushClearsState()throws Exception{SpeechProcessor p=new SpeechProcessor();p.enabled(true);p.configure(new AudioProcessor.AudioFormat(16000,1,C.ENCODING_PCM_16BIT));p.flush();ByteBuffer b=ByteBuffer.allocateDirect(32000).order(ByteOrder.LITTLE_ENDIAN);for(int n=0;n<16000;n++)b.putShort((short)(1000*Math.sin(2*Math.PI*400*n/16000)));b.flip();p.queueInput(b);assertEquals(16000,p.processedFrames);assertEquals(32000,p.getOutput().remaining());p.flush();assertEquals(0,p.processedFrames);p.reset();assertEquals(0,p.rate);}
 @Test public void unsupportedInputDoesNotActivateProcessing()throws Exception{SpeechProcessor p=new SpeechProcessor();assertEquals(AudioProcessor.AudioFormat.NOT_SET,p.configure(new AudioProcessor.AudioFormat(48000,2,C.ENCODING_PCM_FLOAT)));assertFalse(p.isActive());p.flush();assertEquals(0,p.rate);p.reset();}
}
