package br.com.onda;
import java.io.File;import java.nio.ByteBuffer;import java.util.concurrent.*;import java.util.concurrent.atomic.AtomicInteger;
/** One worker, one waiting window: slow phones never build an ever-growing backlog. */
final class LiveRecognizer implements LiveAudioTap.Receiver,AutoCloseable {
 interface Listener {void ready();void text(String text,long audioMs,long processingMs,int epoch);void error(Throwable error);}
 private static final class Window {final float[] pcm;final long end;final int epoch;Window(float[] p,long e,int g){pcm=p;end=e;epoch=g;}}
 private final ArrayBlockingQueue<Window> waiting=new ArrayBlockingQueue<>(1);private final AtomicInteger generation=new AtomicInteger();private final Listener listener;private final Thread worker;private volatile boolean closed;private volatile WhisperEngine engine;private LivePcmWindow window;private int windowEpoch=-1,rate,channels;
 LiveRecognizer(File model,String language,int threads,Listener listener){this.listener=listener;worker=new Thread(()->work(model,language,threads),"Onda-live-recognition");worker.setPriority(Thread.MIN_PRIORITY);worker.start();}
 int epoch(){return generation.get();}
 @Override public void pcm(ByteBuffer pcm,int sampleRate,int count){if(closed)return;int g=generation.get();if(window==null||windowEpoch!=g||rate!=sampleRate||channels!=count){windowEpoch=g;rate=sampleRate;channels=count;window=new LivePcmWindow(rate,channels,(samples,end)->{if(closed||generation.get()!=g)return;Window next=new Window(samples,end,g);if(!waiting.offer(next)){waiting.poll();waiting.offer(next);}});}window.accept(pcm);}
 @Override public void reset(){generation.incrementAndGet();waiting.clear();WhisperEngine e=engine;if(e!=null)e.cancel();}
 @Override public void failed(Throwable error){close();listener.error(error);}
 private void work(File model,String language,int threads){try(WhisperEngine loaded=new WhisperEngine(model)){engine=loaded;if(closed)return;listener.ready();while(!closed){Window item=waiting.take();if(item.epoch!=generation.get())continue;String text="";long start=System.nanoTime();if(LivePcmWindow.audible(item.pcm))text=loaded.recognize(item.pcm,language,threads);if(!closed&&item.epoch==generation.get())listener.text(recognizable(text)?text:"",item.end*1000/LivePcmWindow.RATE,(System.nanoTime()-start)/1000000,item.epoch);}}catch(InterruptedException ignored){Thread.currentThread().interrupt();}catch(Exception|LinkageError|OutOfMemoryError error){if(!closed){closed=true;if(LiveAudioTap.receiver==this)LiveAudioTap.receiver=null;listener.error(error);}}finally{engine=null;}}
 static boolean recognizable(String text){return text!=null&&text.replaceAll("[^\\p{L}]","").length()>=3&&!text.trim().matches("(?is)[\\[(].*[\\])]");}
 @Override public void close(){closed=true;if(LiveAudioTap.receiver==this)LiveAudioTap.receiver=null;reset();worker.interrupt();}
}
