package br.com.onda;
import androidx.media3.common.C;
import androidx.media3.common.audio.*;
import java.nio.*;
/** PCM16 adapter. No file scanner, timer, microphone or allocation per audio frame. */
@androidx.media3.common.util.UnstableApi
final class SpeechProcessor extends BaseAudioProcessor {
 private volatile boolean enabled;volatile int rate,channels;volatile long processedFrames;
 private SpeechDsp dsp;private short[] frame;private byte[] partial;private int partialBytes;
 void enabled(boolean value){enabled=value;}
 @Override protected AudioFormat onConfigure(AudioFormat format){return format.encoding==C.ENCODING_PCM_16BIT&&format.sampleRate>=8000&&format.sampleRate<=384000&&format.channelCount>0&&format.channelCount<=8?format:AudioFormat.NOT_SET;}
 @Override protected void onFlush(){partialBytes=0;processedFrames=0;rate=channels=0;dsp=null;if(inputAudioFormat.encoding==C.ENCODING_PCM_16BIT&&inputAudioFormat.channelCount>0&&inputAudioFormat.channelCount<=8&&inputAudioFormat.sampleRate>=8000&&inputAudioFormat.sampleRate<=384000){rate=inputAudioFormat.sampleRate;channels=inputAudioFormat.channelCount;dsp=new SpeechDsp(rate,channels);frame=new short[channels];partial=new byte[channels*2];}}
 @Override protected void onReset(){dsp=null;frame=null;partial=null;partialBytes=0;rate=channels=0;processedFrames=0;}
 @Override public void queueInput(ByteBuffer input){if(!input.hasRemaining())return;if(dsp==null)throw new IllegalStateException("Unconfigured PCM audio");int bytes=channels*2;boolean requested=enabled;int size=(partialBytes+input.remaining())/bytes*bytes;ByteBuffer output=replaceOutputBuffer(size).order(ByteOrder.LITTLE_ENDIAN);
  if(!requested&&dsp.bypassed()&&partialBytes==0&&input.remaining()%bytes==0){output.put(input);output.flip();return;}
  long done=0;
  while(input.hasRemaining()){int copy=Math.min(bytes-partialBytes,input.remaining());input.get(partial,partialBytes,copy);partialBytes+=copy;if(partialBytes<bytes)break;for(int c=0;c<channels;c++)frame[c]=(short)((partial[c*2]&255)|(partial[c*2+1]<<8));dsp.process(frame,requested);for(short sample:frame)output.putShort(sample);partialBytes=0;if(requested)done++;}
  processedFrames+=done;output.flip();
 }
 @Override protected void onQueueEndOfStream(){if(partialBytes>0){ByteBuffer tail=replaceOutputBuffer(partialBytes);tail.put(partial,0,partialBytes).flip();partialBytes=0;}}
}
