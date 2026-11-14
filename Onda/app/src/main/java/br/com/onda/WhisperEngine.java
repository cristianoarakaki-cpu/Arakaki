package br.com.onda;
import java.io.*;import java.nio.charset.StandardCharsets;
/** Native lifetime permits cancellation without freeing an in-flight recognizer. */
final class WhisperEngine implements AutoCloseable {
 static {System.loadLibrary("onda_whisper");}
 private long handle;private int calls;private boolean closed;
 WhisperEngine(File model)throws IOException{handle=open(model.getAbsolutePath());if(handle==0)throw new IOException("Não foi possível abrir o modelo de reconhecimento.");}
 String recognize(float[] pcm,String language,int threads)throws IOException{long h;synchronized(this){if(closed)throw new IOException("Reconhecimento encerrado");calls++;h=handle;}try{byte[] result=run(h,pcm,language,Math.max(1,Math.min(2,threads)));return result==null?"":new String(result,StandardCharsets.UTF_8).trim();}finally{synchronized(this){calls--;releaseIfReady();}}}
 synchronized void cancel(){if(handle!=0)abort(handle);}
 @Override public synchronized void close(){closed=true;cancel();releaseIfReady();}
 private void releaseIfReady(){if(closed&&calls==0&&handle!=0){destroy(handle);handle=0;}}
 private static native long open(String path)throws IOException;
 private static native byte[] run(long handle,float[] pcm,String language,int threads)throws IOException;
 private static native void abort(long handle);
 private static native void destroy(long handle);
}
