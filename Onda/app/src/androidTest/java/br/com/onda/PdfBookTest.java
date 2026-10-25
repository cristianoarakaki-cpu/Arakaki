package br.com.onda;
import android.content.Context;
import android.graphics.*;
import android.graphics.pdf.PdfDocument;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
import java.io.*;
import java.util.*;
public class PdfBookTest {
 private final Context context=getInstrumentation().getTargetContext();
 private byte[] sample()throws Exception{ByteArrayOutputStream out=new ByteArrayOutputStream();PdfDocument pdf=new PdfDocument();try{for(int i=0;i<2;i++){PdfDocument.Page page=pdf.startPage(new PdfDocument.PageInfo.Builder(300,400,i+1).create());Paint paint=new Paint();paint.setColor(i==0?Color.BLUE:Color.RED);page.getCanvas().drawRect(0,0,300,400,paint);if(i==0){paint.setColor(Color.BLACK);paint.setTextSize(18);page.getCanvas().drawText("ONDA COPIAR",20,70,paint);}pdf.finishPage(page);}pdf.writeTo(out);}finally{pdf.close();}return out.toByteArray();}
 private Set<String> cached(){String[] files=context.getCacheDir().list((d,n)->n.startsWith("onda-pdf-"));return new HashSet<>(Arrays.asList(files==null?new String[0]:files));}
 @Test public void rendersRealPagesWithinPixelBudgetAndDeletesTemporaryCopy()throws Exception{Set<String> before=cached();try(PdfBook pdf=PdfBook.open(context,new ByteArrayInputStream(sample()),()->false)){assertEquals(2,pdf.pages());Bitmap blue=pdf.render(0,300);assertEquals(Color.BLUE,blue.getPixel(150,200));blue.recycle();Bitmap red=pdf.render(1,8000);assertEquals(Color.RED,red.getPixel(red.getWidth()/2,red.getHeight()/2));assertTrue((long)red.getWidth()*red.getHeight()<=PdfBook.MAX_PIXELS);red.recycle();}assertEquals(before,cached());}
 @Test public void corruptAndCancelledDocumentsLeaveNoTemporaryFiles()throws Exception{Set<String> before=cached();try{PdfBook.open(context,new ByteArrayInputStream("not a PDF".getBytes()),()->false);fail("Corrupt PDF was accepted");}catch(IOException|RuntimeException expected){}try{PdfBook.open(context,new ByteArrayInputStream(sample()),()->true);fail("Cancellation was ignored");}catch(InterruptedIOException expected){}assertEquals(before,cached());}
 @Test public void extractsOnlyCurrentPageAndReportsImageOnlyPageAsEmpty()throws Exception{try(PdfBook pdf=PdfBook.open(context,new ByteArrayInputStream(sample()),()->false)){assertTrue(pdf.text(context,0).contains("ONDA COPIAR"));assertEquals("",pdf.text(context,1));}}
}
