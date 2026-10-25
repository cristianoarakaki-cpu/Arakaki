package br.com.onda;
import android.content.Context;
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader;
import com.tom_roush.pdfbox.io.MemoryUsageSetting;
import com.tom_roush.pdfbox.pdmodel.PDDocument;
import com.tom_roush.pdfbox.text.PDFTextStripper;
import java.io.*;
/** On-demand extraction of the current page; no OCR or document upload. */
final class PdfText {
 static final int LIMIT=100000;
 static String read(Context context,File file,int index)throws IOException{
  if(file.length()>16L*1024*1024)throw new IOException("A cópia de texto está disponível para PDFs de até 16 MB.");
  PDFBoxResourceLoader.init(context.getApplicationContext());
  try(PDDocument doc=PDDocument.load(file,MemoryUsageSetting.setupTempFileOnly().setTempDir(context.getCacheDir()))){
   if(!doc.getCurrentAccessPermission().canExtractContent())throw new IOException("Este PDF não permite copiar texto.");
   if(index<0||index>=doc.getNumberOfPages())throw new IOException("Página indisponível.");
   PDFTextStripper stripper=new PDFTextStripper();stripper.setStartPage(index+1);stripper.setEndPage(index+1);stripper.setSortByPosition(true);
   final StringBuilder text=new StringBuilder();Writer writer=new Writer(){public void write(char[] chars,int offset,int count)throws IOException{int copy=Math.min(count,LIMIT-text.length());if(copy>0)text.append(chars,offset,copy);if(copy<count)throw new LimitReached();}public void flush(){}public void close(){}};
   try{stripper.writeText(doc,writer);}catch(LimitReached complete){}return text.toString().trim();
  }
 }
 private static final class LimitReached extends IOException {}
}
