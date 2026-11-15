package br.com.onda;
import java.io.*;import java.nio.charset.StandardCharsets;
/** Explicit optional inference; native memory is released after all in-flight work exits. */
final class LocalAiEngine implements AutoCloseable {
 static{System.loadLibrary("onda_ai");}
 @androidx.annotation.Keep interface Progress{void changed(byte[] text);}
 private long handle;private int calls;private boolean closed;
 LocalAiEngine(File model)throws IOException{this(model,new LocalAiModels.Cancel());}
 LocalAiEngine(File model,LocalAiModels.Cancel cancel)throws IOException{handle=open(model.getAbsolutePath(),Math.max(1,Math.min(2,Runtime.getRuntime().availableProcessors()-1)),cancel);if(handle==0)throw new IOException("Não foi possível abrir a IA local.");}
 String answer(String prompt,int tokens,Progress progress)throws IOException{long h;synchronized(this){if(closed)throw new IOException("IA encerrada");if(calls>0)throw new IOException("A IA já está trabalhando neste pedido");calls++;h=handle;}try{byte[] result=run(h,prompt.getBytes(StandardCharsets.UTF_8),tokens,progress);return result==null?"":new String(result,StandardCharsets.UTF_8).trim();}finally{synchronized(this){calls--;release();}}}
 synchronized void cancel(){if(handle!=0)abort(handle);}
 @Override public synchronized void close(){closed=true;cancel();release();}
 private void release(){if(closed&&calls==0&&handle!=0){destroy(handle);handle=0;}}
 private static native long open(String path,int threads,LocalAiModels.Cancel cancel)throws IOException;
 private static native byte[] run(long handle,byte[] input,int tokens,Progress progress)throws IOException;
 private static native void abort(long handle);
 private static native void destroy(long handle);
}
