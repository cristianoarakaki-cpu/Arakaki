package br.com.onda;

import android.content.Context;
import android.graphics.*;
import android.os.SystemClock;
import com.googlecode.tesseract.android.TessBaseAPI;
import java.io.*;
import java.security.*;
import java.util.function.BooleanSupplier;

/** One requested page, one worker, bundled Portuguese fast model. No network or service. */
final class LocalOcr implements Closeable {
 static final int MAX_PIXELS=2500000;
 private final BooleanSupplier cancelled;
 private final long deadline=SystemClock.elapsedRealtime()+45000;
 private final TessBaseAPI tess;
 LocalOcr(Context context,BooleanSupplier cancelled)throws IOException{
  this.cancelled=cancelled;check();
  File root=install(context,cancelled);
  TessBaseAPI[] holder=new TessBaseAPI[1];
  tess=new TessBaseAPI(progress->{if(cancelled.getAsBoolean()||SystemClock.elapsedRealtime()>deadline)holder[0].stop();});holder[0]=tess;
  try{if(!tess.init(root.getAbsolutePath(),"por",TessBaseAPI.OEM_LSTM_ONLY))throw new IOException("Não foi possível iniciar o OCR local.");check();}
  catch(IOException|RuntimeException|Error e){tess.recycle();throw e;}
 }
 private static synchronized File install(Context context,BooleanSupplier cancelled)throws IOException{
  File root=new File(context.getFilesDir(),"ocr-por-87416418"),data=new File(root,"tessdata"),model=new File(data,"por.traineddata");
  if(model.isFile()&&model.length()==1982756)return root;
  if(!data.isDirectory()&&!data.mkdirs())throw new IOException("Não foi possível preparar o OCR.");
  File partial=new File(data,"por.part");
  try{
   MessageDigest sha=MessageDigest.getInstance("SHA-256");long size=0;
   try(InputStream input=context.getAssets().open("ocr/por.traineddata");OutputStream output=new FileOutputStream(partial)){
    byte[] buffer=new byte[16384];int count;while((count=input.read(buffer))!=-1){if(cancelled.getAsBoolean())throw new InterruptedIOException("OCR cancelado");size+=count;if(size>1982756)throw new IOException("Modelo de OCR inválido.");sha.update(buffer,0,count);output.write(buffer,0,count);}
   }
   String expected;try(InputStream input=context.getAssets().open("ocr/por.sha256");ByteArrayOutputStream output=new ByteArrayOutputStream()){byte[] b=new byte[256];int n;while((n=input.read(b))!=-1){if(output.size()+n>256)throw new IOException("Modelo inválido");output.write(b,0,n);}expected=output.toString("UTF-8").trim();}
   StringBuilder actual=new StringBuilder();for(byte b:sha.digest())actual.append(String.format(java.util.Locale.ROOT,"%02x",b&255));
   if(size!=1982756||!actual.toString().equals(expected)||!partial.renameTo(model))throw new IOException("Não foi possível conferir o modelo de OCR.");return root;
  }catch(NoSuchAlgorithmException error){throw new IOException(error);}finally{partial.delete();}
 }
 void check()throws IOException{if(cancelled.getAsBoolean())throw new InterruptedIOException("OCR cancelado");if(SystemClock.elapsedRealtime()>deadline)throw new IOException("O OCR atingiu o tempo de leitura. Tente uma página mais nítida.");}
 static final class Reading {final String text;final int confidence;Reading(String text,int confidence){this.text=text;this.confidence=confidence;}}
 Reading read(Bitmap image,int rotation,boolean digits)throws IOException{
  check();if((long)image.getWidth()*image.getHeight()>MAX_PIXELS)throw new IOException("Página grande demais para OCR.");
  Bitmap prepared=prepare(image,rotation);
  try{
   tess.clear();tess.setPageSegMode(TessBaseAPI.PageSegMode.PSM_AUTO);
   tess.setVariable("tessedit_char_whitelist",digits?"0123456789 .-":"");
   tess.setVariable("preserve_interword_spaces","1");tess.setImage(prepared);
   // HOCR runs recognition with the native cancellation monitor. UTF8 reuses that result.
   tess.getHOCRText(0);check();String text=tess.getUTF8Text();int confidence=tess.meanConfidence();
   return new Reading(text==null?"":text.substring(0,Math.min(PdfText.LIMIT,text.length())).trim(),confidence);
  }finally{prepared.recycle();}
 }
 private static Bitmap prepare(Bitmap image,int rotation){
  Matrix matrix=new Matrix();matrix.postRotate(rotation);Bitmap oriented=Bitmap.createBitmap(image,0,0,image.getWidth(),image.getHeight(),matrix,false);
  Bitmap out=null;
  try{
   out=Bitmap.createBitmap(oriented.getWidth(),oriented.getHeight(),Bitmap.Config.ARGB_8888);
   Paint paint=new Paint();ColorMatrix gray=new ColorMatrix();gray.setSaturation(0);paint.setColorFilter(new ColorMatrixColorFilter(gray));new Canvas(out).drawBitmap(oriented,0,0,paint);
   // Bounded row buffer: stretch contrast without throwing away anti-aliased strokes.
   int[] row=new int[out.getWidth()],hist=new int[256];long count=(long)out.getWidth()*out.getHeight();
   for(int y=0;y<out.getHeight();y++){out.getPixels(row,0,row.length,0,y,row.length,1);for(int pixel:row)hist[pixel&255]++;}
   long target=Math.max(1,count/1000),sum=0;int low=0,high=255;for(;low<255;low++){sum+=hist[low];if(sum>=target)break;}sum=0;for(;high>0;high--){sum+=hist[high];if(sum>=target)break;}
   if(high-low>=24)for(int y=0;y<out.getHeight();y++){out.getPixels(row,0,row.length,0,y,row.length,1);for(int x=0;x<row.length;x++){int v=Math.max(0,Math.min(255,((row[x]&255)-low)*255/(high-low)));row[x]=Color.rgb(v,v,v);}out.setPixels(row,0,row.length,0,y,row.length,1);}return out;
  }catch(RuntimeException|Error error){if(out!=null)out.recycle();throw error;}finally{if(oriented!=image)oriented.recycle();}
 }
 @Override public void close(){tess.recycle();}
}
