package br.com.onda;
import java.nio.ByteBuffer;
/** Same-process, opt-in observation of decoded playback. Never opens a microphone. */
final class LiveAudioTap {
 interface Receiver {void pcm(ByteBuffer data,int rate,int channels);void reset();default void failed(Throwable error){}}
 static volatile Receiver receiver;
 private LiveAudioTap(){}
}
