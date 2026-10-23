package br.com.onda;
import java.io.*;
/** Sequential bounded batch: preserve successes, skip failures, stop on cancellation or repeated failure. */
final class BatchDownloads {
 interface Work {void run(int index)throws Exception;}
 interface Progress {void done(int index,boolean success);}
 static final class Summary {int success,failed,processed;boolean stopped;String text(int total){return success+" concluídos • "+failed+" falhas • "+(total-processed)+" não iniciados";}}
 static Summary run(int count,Work work,Progress progress,DownloadMux.Cancel cancel)throws IOException{
  if(count<1||count>100)throw new IOException("Fila inválida");Summary s=new Summary();int consecutive=0;
  for(int i=0;i<count;i++){cancel.check();boolean ok=false;try{work.run(i);ok=true;consecutive=0;s.success++;}catch(Exception e){cancel.check();s.failed++;consecutive++;}s.processed++;progress.done(i,ok);if(consecutive>=3){s.stopped=true;break;}}
  return s;
 }
}
