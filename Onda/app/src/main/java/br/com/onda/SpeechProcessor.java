package br.com.onda;
import androidx.media3.common.C;
import androidx.media3.common.audio.*;
import java.nio.*;
/** PCM16 adapter. No file scanner, timer, microphone or allocation per audio frame. */
@androidx.media3.common.util.UnstableApi
final class SpeechProcessor extends BaseAudioProcessor {
 private volatile boolean enabled,leveling;volatile long levelFrames,bypassBytes;volatile float levelGainDb;private volatile int quietLevel;volatile long quietFrames;volatile int rate,channels;volatile long processedFrames;
 private LevelDsp level;private SpeechDsp dsp;private QuietDsp quiet;private short[] frame;private byte[] partial;private int partialBytes;
 void enabled(boolean value){enabled=value;}
 void leveling(boolean value){leveling=value;}
 void quiet(int level){quietLevel=Math.max(0,Math.min(3,level));}
 @Override protected AudioFormat onConfigure(AudioFormat format){return format.encoding==C.ENCODING_PCM_16BIT&&format.sampleRate>=8000&&format.sampleRate<=384000&&format.channelCount>0&&format.channelCount<=8?format:AudioFormat.NOT_SET;}
 @Override protected void onFlush(){partialBytes=0;processedFrames=0;quietFrames=0;levelFrames=bypassBytes=0;levelGainDb=0;rate=channels=0;dsp=null;if(inputAudioFormat.encoding==C.ENCODING_PCM_16BIT&&inputAudioFormat.channelCount>0&&inputAudioFormat.channelCount<=8&&inputAudioFormat.sampleRate>=8000&&inputAudioFormat.sampleRate<=384000){rate=inputAudioFormat.sampleRate;channels=inputAudioFormat.channelCount;dsp=new SpeechDsp(rate,channels);level=new LevelDsp(rate);quiet=new QuietDsp(rate);frame=new short[channels];partial=new byte[channels*2];}}
 @Override protected void onReset(){dsp=null;quiet=null;level=null;frame=null;partial=null;partialBytes=0;rate=channels=0;processedFrames=quietFrames=levelFrames=bypassBytes=0;levelGainDb=0;}
 @Override public void queueInput(ByteBuffer input){if(!input.hasRemaining())return;if(dsp==null)throw new IllegalStateException("Unconfigured PCM audio");int bytes=channels*2;boolean requested=enabled;int quietRequested=quietLevel;boolean levelingRequested=leveling;int size=(partialBytes+input.remaining())/bytes*bytes;ByteBuffer output=replaceOutputBuffer(size).order(ByteOrder.LITTLE_ENDIAN);
  if(!requested&&quietRequested==0&&!levelingRequested&&dsp.bypassed()&&quiet.bypassed()&&level.bypassed()){
   if(partialBytes>0){int n=Math.min(bytes-partialBytes,input.remaining());input.get(partial,partialBytes,n);partialBytes+=n;if(partialBytes==bytes){output.put(partial,0,bytes);partialBytes=0;}}
   int aligned=input.remaining()/bytes*bytes;
   if(aligned>0){int limit=input.limit();input.limit(input.position()+aligned);output.put(input);input.limit(limit);}
   if(input.hasRemaining()){partialBytes=input.remaining();input.get(partial,0,partialBytes);}
   bypassBytes+=output.position();output.flip();deliver(output);return;
  }
  long done=0,quietDone=0,leveled=0;
  while(input.hasRemaining()){int copy=Math.min(bytes-partialBytes,input.remaining());input.get(partial,partialBytes,copy);partialBytes+=copy;if(partialBytes<bytes)break;for(int c=0;c<channels;c++)frame[c]=(short)((partial[c*2]&255)|(partial[c*2+1]<<8));dsp.process(frame,requested);quiet.process(frame,quietRequested);level.process(frame,levelingRequested);for(short sample:frame)output.putShort(sample);partialBytes=0;if(requested)done++;if(quietRequested>0)quietDone++;if(levelingRequested)leveled++;}
  processedFrames+=done;quietFrames+=quietDone;levelFrames+=leveled;levelGainDb=level.gainDb();output.flip();deliver(output);
 }
 private void deliver(ByteBuffer output){LiveAudioTap.Receiver target=LiveAudioTap.receiver;if(target!=null)try{target.pcm(output.asReadOnlyBuffer(),rate,channels);}catch(RuntimeException|OutOfMemoryError error){if(LiveAudioTap.receiver==target)LiveAudioTap.receiver=null;try{target.failed(error);}catch(RuntimeException|OutOfMemoryError ignored){}}}
 @Override protected void onQueueEndOfStream(){if(partialBytes>0){ByteBuffer tail=replaceOutputBuffer(partialBytes);tail.put(partial,0,partialBytes).flip();partialBytes=0;}}
}
