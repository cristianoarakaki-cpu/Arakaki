package com.arakaki.prismavoz;

import android.content.*;
import android.graphics.*;
import android.graphics.pdf.PdfDocument;
import android.net.Uri;
import android.os.SystemClock;
import android.provider.MediaStore;
import android.view.*;
import android.widget.*;
import androidx.test.core.app.ActivityScenario;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.platform.app.InstrumentationRegistry;
import org.junit.Test;
import org.junit.runner.RunWith;
import static org.junit.Assert.*;
import java.io.*;
import java.util.concurrent.atomic.AtomicBoolean;

@RunWith(AndroidJUnit4.class)
public class NativeReaderDeviceTest {
 private Uri fixture(Context context)throws Exception{
  ContentValues values=new ContentValues();values.put(MediaStore.Downloads.DISPLAY_NAME,"Prisma-Voz-Teste.pdf");values.put(MediaStore.Downloads.MIME_TYPE,"application/pdf");values.put(MediaStore.Downloads.RELATIVE_PATH,"Download");Uri uri=context.getContentResolver().insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI,values);assertNotNull(uri);
  PdfDocument document=new PdfDocument();try{
   for(int i=0;i<3;i++){PdfDocument.Page page=document.startPage(new PdfDocument.PageInfo.Builder(500,700,i+1).create());Paint paint=new Paint();paint.setColor(Color.BLACK);paint.setTextSize(i==2?14:22);page.getCanvas().drawColor(i==2?Color.rgb(245,245,245):Color.WHITE);if(i==2){paint.setColor(Color.rgb(220,220,220));page.getCanvas().rotate(3,250,350);}page.getCanvas().drawText(i==0?"PRISMA VOZ LEITURA NATIVA":i==1?"SEGUNDA PAGINA DO PDF":"MARIA DA SILVA AGENDAMENTO",25,120,paint);document.finishPage(page);}
   try(OutputStream out=context.getContentResolver().openOutputStream(uri)){document.writeTo(out);}
  }finally{document.close();}
  return uri;
 }
 @Test public void nativePdfRendererAndBundledOcrWorkOffline()throws Exception{
  Context context=InstrumentationRegistry.getInstrumentation().getTargetContext();Uri uri=fixture(context);
  try(NativePdf doc=NativePdf.open(context,uri)){
   assertEquals(3,doc.pages);Bitmap bitmap=doc.preview(0);assertTrue(bitmap.getWidth()>300);assertTrue(bitmap.getHeight()>500);bitmap.recycle();
   String first=doc.text(0,true,true,()->true).toUpperCase();assertTrue(first,first.contains("PRISMA")&&first.contains("NATIVA"));
   String second=doc.text(1,false,false,()->true).toUpperCase();assertTrue(second,second.contains("SEGUNDA")&&second.contains("PAGINA"));
   String faint=doc.text(2,true,true,()->true).toUpperCase();assertTrue(faint,faint.contains("MARIA")&&faint.contains("AGENDAMENTO"));
   try{doc.text(0,true,false,()->false);fail("Deveria cancelar");}catch(InterruptedException expected){}
  }finally{context.getContentResolver().delete(uri,null,null);}
 }
 private boolean noBrowser(View view){if(view instanceof android.webkit.WebView)return false;if(view instanceof ViewGroup){ViewGroup group=(ViewGroup)view;for(int i=0;i<group.getChildCount();i++)if(!noBrowser(group.getChildAt(i)))return false;}return true;}
 @Test public void androidInterfaceOpensPdfWithoutWebView()throws Exception{
  Context context=InstrumentationRegistry.getInstrumentation().getTargetContext();Uri uri=fixture(context);
  Intent intent=new Intent(context,MainActivity.class).setAction(Intent.ACTION_VIEW).setData(uri).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
  try(ActivityScenario<MainActivity> scenario=ActivityScenario.launch(intent)){
   AtomicBoolean ready=new AtomicBoolean();long deadline=SystemClock.uptimeMillis()+15000;
   while(!ready.get()&&SystemClock.uptimeMillis()<deadline){scenario.onActivity(a->{assertTrue(noBrowser(a.getWindow().getDecorView()));assertTrue(a.findViewById(MainActivity.OPEN_ID) instanceof Button);assertTrue(a.findViewById(MainActivity.VOICE_ID) instanceof Spinner);ImageView preview=a.findViewById(MainActivity.PREVIEW_ID);ready.set(preview.getDrawable()!=null);});SystemClock.sleep(150);}
   assertTrue("Prévia nativa não carregou",ready.get());
   Bitmap screen=InstrumentationRegistry.getInstrumentation().getUiAutomation().takeScreenshot();File output=new File(context.getExternalFilesDir(null),"native-reader.png");try(OutputStream out=new FileOutputStream(output)){screen.compress(Bitmap.CompressFormat.PNG,100,out);}screen.recycle();
  }finally{context.getContentResolver().delete(uri,null,null);}
 }
}
