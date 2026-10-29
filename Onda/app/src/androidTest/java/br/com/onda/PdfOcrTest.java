package br.com.onda;

import android.content.Context;
import android.graphics.*;
import android.graphics.pdf.PdfDocument;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
import java.io.*;
import java.util.*;

public class PdfOcrTest {
 private final Context context=getInstrumentation().getTargetContext();
 private static final String LINE="00190500954014481606906809350314337370000000100";
 private Bitmap sample(){Bitmap image=Bitmap.createBitmap(1600,2000,Bitmap.Config.ARGB_8888);Canvas canvas=new Canvas(image);canvas.drawColor(Color.WHITE);Paint ink=new Paint(Paint.ANTI_ALIAS_FLAG);ink.setColor(Color.BLACK);ink.setTypeface(Typeface.create("sans-serif",Typeface.NORMAL));ink.setTextSize(62);canvas.drawText("ONDA LEITURA LOCAL",80,160,ink);ink.setTextSize(42);canvas.drawText("Documento para leitura em português",80,250,ink);ink.setTextSize(40);canvas.drawText("00190.50095 40144.816069 06809.350314 3",80,380,ink);canvas.drawText("37370000000100",80,450,ink);return image;}
 private byte[] scanned(Bitmap image)throws IOException{PdfDocument document=new PdfDocument();try{PdfDocument.Page page=document.startPage(new PdfDocument.PageInfo.Builder(image.getWidth()/2,image.getHeight()/2,1).create());page.getCanvas().drawBitmap(image,null,new Rect(0,0,image.getWidth()/2,image.getHeight()/2),new Paint(Paint.FILTER_BITMAP_FLAG));document.finishPage(page);ByteArrayOutputStream bytes=new ByteArrayOutputStream();document.writeTo(bytes);return bytes.toByteArray();}finally{document.close();}}
 @Test public void readsScannedPortuguesePageAndValidatesLineWithoutTextLayer()throws Exception{
  Bitmap image=sample();byte[] fixture=scanned(image);try(FileOutputStream output=new FileOutputStream(new File(context.getFilesDir(),"ocr-ui.pdf"))){output.write(fixture);}try(PdfBook book=PdfBook.open(context,new ByteArrayInputStream(fixture),()->false)){
   assertEquals("",book.text(context,0));PdfBook.PageText result=book.readableText(context,0,false,()->false);assertTrue(result.ocr);assertTrue(result.value,result.value.contains("ONDA LEITURA LOCAL"));assertTrue(result.value,result.value.contains("portugu"));
   assertEquals(result.value,book.readableText(context,0,true,()->false).value);
   BoletoReading reading=book.recognizeBoleto(context,0,()->false);assertTrue(reading.ocrUsed);assertEquals(result.value,1,reading.codes.size());assertEquals(LINE,reading.codes.get(0).line);assertFalse(reading.agrees(reading.codes.get(0)));
  }finally{image.recycle();}
 }
 @Test public void readsRotatedImageAndHonorsCancellationBeforeLoadingModel()throws Exception{
  Bitmap original=sample();Matrix matrix=new Matrix();matrix.postRotate(90);Bitmap rotated=Bitmap.createBitmap(original,0,0,original.getWidth(),original.getHeight(),matrix,false);
  try(PdfBook book=PdfBook.open(context,new ByteArrayInputStream(scanned(rotated)),()->false)){
   try{book.readableText(context,0,true,()->true);fail("Cancellation ignored");}catch(InterruptedIOException expected){}
   PdfBook.PageText text=book.readableText(context,0,true,()->false);assertTrue(text.value,text.value.contains("ONDA LEITURA LOCAL"));
  }finally{original.recycle();rotated.recycle();}
 }
 @Test public void nativeTextStaysNativeAndCopyRestrictionsAlsoBlockOcr()throws Exception{
  com.tom_roush.pdfbox.android.PDFBoxResourceLoader.init(context);
  try(com.tom_roush.pdfbox.pdmodel.PDDocument pdf=new com.tom_roush.pdfbox.pdmodel.PDDocument()){
   com.tom_roush.pdfbox.pdmodel.PDPage page=new com.tom_roush.pdfbox.pdmodel.PDPage();pdf.addPage(page);
   try(com.tom_roush.pdfbox.pdmodel.PDPageContentStream stream=new com.tom_roush.pdfbox.pdmodel.PDPageContentStream(pdf,page)){stream.beginText();stream.setFont(com.tom_roush.pdfbox.pdmodel.font.PDType1Font.HELVETICA,18);stream.newLineAtOffset(30,700);stream.showText("ONDA TEXTO ORIGINAL");stream.endText();}
   ByteArrayOutputStream clear=new ByteArrayOutputStream();pdf.save(clear);try(PdfBook book=PdfBook.open(context,new ByteArrayInputStream(clear.toByteArray()),()->false)){PdfBook.PageText text=book.readableText(context,0,false,()->false);assertFalse(text.ocr);assertTrue(text.value.contains("ONDA TEXTO ORIGINAL"));}
   // Android PdfRenderer cannot open encrypted PDFs on all API levels; test extraction's permission gate directly.
   com.tom_roush.pdfbox.pdmodel.encryption.AccessPermission permission=new com.tom_roush.pdfbox.pdmodel.encryption.AccessPermission();permission.setCanExtractContent(false);
   com.tom_roush.pdfbox.pdmodel.encryption.StandardProtectionPolicy policy=new com.tom_roush.pdfbox.pdmodel.encryption.StandardProtectionPolicy("onda-owner-test","",permission);policy.setEncryptionKeyLength(128);pdf.protect(policy);
   File protectedFile=File.createTempFile("ocr-protected-",".pdf",context.getCacheDir());try{pdf.save(protectedFile);try{PdfText.read(context,protectedFile,0);fail("Copy restriction ignored");}catch(IOException expected){assertTrue(expected.getMessage(),expected.getMessage().contains("não permite"));}}finally{protectedFile.delete();}
  }
 }
 @Test public void preservesConflictingSourcesAndRejectsWrongCheckDigit(){
  BoletoCode bank=BoletoCode.from(LINE),other=BoletoCode.from("846600000018234512345674890123456786901234567898");assertNotNull(bank);assertNotNull(other);
  BoletoReading reading=new BoletoReading();reading.add(Collections.singletonList(bank),BoletoReading.TEXT);reading.add(Collections.singletonList(bank),BoletoReading.BARS);assertTrue(reading.agrees(bank));assertFalse(reading.differentSources());
  reading.add(Collections.singletonList(other),BoletoReading.BARS);assertTrue(reading.differentSources());assertEquals(2,reading.codes.size());assertFalse(reading.agrees(other));
  assertTrue(BoletoCode.find("00190500964014481606906809350314337370000000100").isEmpty());
 }
}
