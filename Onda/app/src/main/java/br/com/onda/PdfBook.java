package br.com.onda;

import android.content.Context;
import android.graphics.*;
import android.graphics.pdf.PdfRenderer;
import android.os.ParcelFileDescriptor;
import java.io.*;
import java.util.function.BooleanSupplier;

/** Worker-thread-only PDF renderer. One temporary file; one page bitmap at a time. */
final class PdfBook implements Closeable {
 static final long MAX_BYTES=64L*1024*1024;static final int MAX_PAGES=5000,MAX_PIXELS=2500000;
 private static final java.util.Set<File> ACTIVE=new java.util.HashSet<>();
 private final File file;private final PdfRenderer renderer;
 private PdfBook(File f,PdfRenderer r){file=f;renderer=r;}
 static PdfBook open(Context context,InputStream input,BooleanSupplier cancelled)throws IOException{
  File file; synchronized(PdfBook.class){File[] abandoned=context.getCacheDir().listFiles((d,n)->n.startsWith("onda-pdf-"));if(abandoned!=null)for(File old:abandoned)if(!ACTIVE.contains(old))old.delete();file=File.createTempFile("onda-pdf-",".pdf",context.getCacheDir());ACTIVE.add(file);}
  ParcelFileDescriptor descriptor=null;PdfRenderer renderer=null;
  try{
   try(OutputStream out=new FileOutputStream(file)){byte[] buffer=new byte[8192];long size=0;int n;while((n=input.read(buffer))!=-1){if(cancelled.getAsBoolean())throw new InterruptedIOException("Leitura cancelada");size+=n;if(size>MAX_BYTES)throw new IOException("O PDF ultrapassa o limite de 64 MB.");out.write(buffer,0,n);}if(size==0)throw new IOException("O arquivo está vazio.");}
   if(cancelled.getAsBoolean())throw new InterruptedIOException("Leitura cancelada");
   descriptor=ParcelFileDescriptor.open(file,ParcelFileDescriptor.MODE_READ_ONLY);renderer=new PdfRenderer(descriptor);
   if(renderer.getPageCount()<1||renderer.getPageCount()>MAX_PAGES)throw new IOException("O PDF precisa ter entre 1 e 5.000 páginas.");
   return new PdfBook(file,renderer);
  }catch(IOException|RuntimeException|OutOfMemoryError e){if(renderer!=null)renderer.close();else if(descriptor!=null)descriptor.close();file.delete();synchronized(PdfBook.class){ACTIVE.remove(file);}throw e;}
 }
 private final java.util.LinkedHashMap<Integer,LocalOcr.Reading> ocrCache=new java.util.LinkedHashMap<>();
 static final class PageText {final String value;final boolean ocr;PageText(String value,boolean ocr){this.value=value;this.ocr=ocr;}}
 PageText readableText(Context context,int index,boolean forceOcr,BooleanSupplier cancelled)throws IOException{
  check(cancelled);String original=text(context,index);check(cancelled);
  if(!forceOcr&&!original.isEmpty())return new PageText(original,false);
  return new PageText(ocr(context,index,cancelled,false).text,true);
 }
 private static void check(BooleanSupplier cancelled)throws InterruptedIOException{if(cancelled.getAsBoolean())throw new InterruptedIOException("Leitura cancelada");}
 private LocalOcr.Reading ocr(Context context,int index,BooleanSupplier cancelled,boolean boleto)throws IOException{
  check(cancelled);LocalOcr.Reading cached=ocrCache.get(index);if(cached!=null)return cached;
  Bitmap bitmap=render(index,1800);
  try(LocalOcr engine=new LocalOcr(context,cancelled)){
   LocalOcr.Reading best=new LocalOcr.Reading("",0);
   for(int angle:new int[]{0,90,180,270}){
    engine.check();LocalOcr.Reading reading=engine.read(bitmap,angle,false);
    if(best.text.isEmpty()||reading.confidence>best.confidence)best=reading;
    if(boleto&&!BoletoCode.find(reading.text).isEmpty()){best=reading;break;}
    if(!boleto&&reading.confidence>=65&&!reading.text.isEmpty())break;
   }
   check(cancelled);if(!best.text.isEmpty()){if(ocrCache.size()>=2)ocrCache.remove(ocrCache.keySet().iterator().next());ocrCache.put(index,best);}return best;
  }finally{bitmap.recycle();}
 }
 BoletoReading recognizeBoleto(Context context,int index,BooleanSupplier cancelled)throws IOException{
  check(cancelled);BoletoReading out=new BoletoReading();
  // Also checks the PDF extraction permission and the 16 MB text/OCR limit.
  out.add(BoletoCode.find(text(context,index)),BoletoReading.TEXT);check(cancelled);
  Bitmap bitmap=render(index,1800);try{out.add(BoletoScanner.read(bitmap,cancelled),BoletoReading.BARS);}finally{bitmap.recycle();}check(cancelled);
  boolean hasText=out.hasSource(BoletoReading.TEXT);
  if(!hasText){out.ocrUsed=true;try{out.add(BoletoCode.find(ocr(context,index,cancelled,true).text),BoletoReading.OCR);}catch(InterruptedIOException cancelledError){throw cancelledError;}catch(IOException|RuntimeException error){out.warning="Não foi possível concluir o OCR. Confira os códigos encontrados ou tente uma página mais nítida.";}}
  check(cancelled);return out;
 }
 String text(Context context,int index)throws IOException{return PdfText.read(context,file,index);}
 int pages(){return renderer.getPageCount();}
 Bitmap render(int index,int requestedWidth){
  if(index<0||index>=pages())throw new IllegalArgumentException("Página inválida");
  try(PdfRenderer.Page page=renderer.openPage(index)){
   double w=Math.max(1,page.getWidth()),h=Math.max(1,page.getHeight());
   double scale=Math.min(Math.max(1,Math.min(2200,requestedWidth))/w,Math.min(Math.sqrt(MAX_PIXELS/(w*h)),Math.min(4096/w,4096/h)));
   int width=Math.max(1,(int)Math.floor(w*scale)),height=Math.max(1,(int)Math.floor(h*scale));
   Bitmap image=Bitmap.createBitmap(width,height,Bitmap.Config.ARGB_8888);
   try{image.eraseColor(Color.WHITE);page.render(image,null,null,PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY);return image;}catch(RuntimeException|OutOfMemoryError e){image.recycle();throw e;}
  }
 }
 @Override public void close(){try{ocrCache.clear();renderer.close();}finally{file.delete();synchronized(PdfBook.class){ACTIVE.remove(file);}}}
}
