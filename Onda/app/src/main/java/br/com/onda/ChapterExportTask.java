package br.com.onda;
import android.content.*;import android.content.res.AssetFileDescriptor;import android.provider.DocumentsContract;import android.system.*;import java.io.*;
/** Keeps the selected destination descriptor open; never truncates a URI resolved a second time. */
@androidx.media3.common.util.UnstableApi
final class ChapterExportTask {
 interface Control extends ChapterMp3Exporter.Control {void stage(String message);}
 static void run(Context c,ChapterExportJob job,AssetFileDescriptor destination,Control control)throws IOException {
  File temporary=null;boolean complete=false,owned=false;long dev=-1,inode=-1;
  AssetFileDescriptor target=destination;try{
   control.check();if(!job.valid()||target==null)throw new IOException("Conversão inválida");
   try(AssetFileDescriptor original=c.getContentResolver().openAssetFileDescriptor(job.source,"r")){
    if(original==null)throw new IOException("O arquivo original não está acessível");
    StructStat a=Os.fstat(original.getFileDescriptor()),b=Os.fstat(target.getFileDescriptor());
    if(a.st_dev==b.st_dev&&a.st_ino==b.st_ino||b.st_size!=0||target.getStartOffset()!=0)throw new IOException("Escolha um novo arquivo vazio; o original não será sobrescrito.");
    dev=b.st_dev;inode=b.st_ino;owned=true;
   }
   if(!job.stamp.equals(AudioChapterStore.stamp(c,job.source)))throw new IOException("O arquivo original mudou. Selecione a faixa novamente.");
   AudioChapterStore.Data data=AudioChapterStore.load(c,job.source,job.stamp,job.duration);boolean matching=false;
   if(data!=null)for(int i=0;i<data.chapters.size();i++)if(data.chapters.get(i).start==job.start&&(i+1<data.chapters.size()?data.chapters.get(i+1).start:data.duration)==job.end)matching=true;
   if(!matching)throw new IOException("Os horários foram alterados. Selecione a faixa novamente.");
   File[] leftovers=c.getCacheDir().listFiles();if(leftovers!=null)for(File old:leftovers)if(old.getName().matches("chapter-export-job-[0-9a-f-]+\\.mp3")&&old.lastModified()<System.currentTimeMillis()-86400000L)old.delete();
   temporary=new File(c.getCacheDir(),"chapter-export-job-"+java.util.UUID.randomUUID()+".mp3");
   control.stage("Convertendo o trecho • "+job.bitrate+" kbps. Pode apagar a tela.");
   try(MediaInput.Direct input=MediaInput.open(c,job.source)){if(input==null)throw new IOException("Este arquivo não permite leitura direta. Salve-o no celular e tente novamente.");ChapterMp3Exporter.convert(input,temporary,job.bitrate,job.start,job.end,control);}
   control.check();if(!job.stamp.equals(AudioChapterStore.stamp(c,job.source)))throw new IOException("O arquivo original mudou durante a conversão.");
   control.stage("Salvando o MP3 no destino escolhido…");
   try(InputStream in=new BufferedInputStream(new FileInputStream(temporary));OutputStream out=new android.os.ParcelFileDescriptor.AutoCloseOutputStream(android.os.ParcelFileDescriptor.dup(target.getFileDescriptor()))){
    byte[] bytes=new byte[65536];int count;while((count=in.read(bytes))!=-1){control.check();out.write(bytes,0,count);}out.flush();control.check();complete=true;
   }
  }catch(ErrnoException error){throw new IOException("Não foi possível conferir o destino",error);}
  finally{
   if(temporary!=null)temporary.delete();
   if(owned&&!complete){
    try{if(destination!=null)Os.ftruncate(destination.getFileDescriptor(),0);}catch(Exception ignored){}
    // Delete only the empty document we validated, never another file selected by a provider.
    try(AssetFileDescriptor check=c.getContentResolver().openAssetFileDescriptor(job.target,"r")){
     if(check!=null){StructStat b=Os.fstat(check.getFileDescriptor());if(b.st_dev==dev&&b.st_ino==inode){if(DocumentsContract.isDocumentUri(c,job.target))DocumentsContract.deleteDocument(c.getContentResolver(),job.target);else c.getContentResolver().delete(job.target,null,null);}}
    }catch(Exception ignored){}
   }
   if(destination!=null)try{destination.close();}catch(IOException ignored){}
  }
 }
}
