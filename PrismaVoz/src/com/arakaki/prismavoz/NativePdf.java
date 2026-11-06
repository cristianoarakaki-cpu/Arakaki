package com.arakaki.prismavoz;

import android.content.Context;
import android.graphics.*;
import android.graphics.pdf.PdfRenderer;
import android.net.Uri;
import android.os.*;
import com.google.android.gms.tasks.Tasks;
import com.google.android.gms.tasks.Task;
import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.text.*;
import com.google.mlkit.vision.text.latin.TextRecognizerOptions;
import java.io.*;
import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.function.BooleanSupplier;

/** Worker-thread only. System PDF renderer plus bundled, on-device Latin OCR. */
final class NativePdf implements AutoCloseable {
    private final File copy;
    private final ParcelFileDescriptor descriptor;
    private final PdfRenderer renderer;
    private TextRecognizer recognizer;
    final int pages;
    private NativePdf(File file,ParcelFileDescriptor fd,PdfRenderer pdf){copy=file;descriptor=fd;renderer=pdf;pages=pdf.getPageCount();}
    static NativePdf open(Context context,Uri source)throws IOException{
        File directory=new File(context.getCacheDir(),"native-reading");directory.mkdirs();File copy=File.createTempFile("reading-",".pdf",directory);
        ParcelFileDescriptor descriptor=null;
        try{
            try(InputStream input=context.getContentResolver().openInputStream(source);OutputStream output=new FileOutputStream(copy)){
                if(input==null)throw new IOException("Documento indisponível.");byte[] buffer=new byte[32768];int read;long total=0;
                while((read=input.read(buffer))!=-1){total+=read;if(total>25L*1024*1024)throw new IOException("Escolha um PDF de até 25 MB.");output.write(buffer,0,read);}
            }
            descriptor=ParcelFileDescriptor.open(copy,ParcelFileDescriptor.MODE_READ_ONLY);PdfRenderer renderer=new PdfRenderer(descriptor);
            if(renderer.getPageCount()==0){renderer.close();throw new IOException("O documento não possui páginas.");}
            return new NativePdf(copy,descriptor,renderer);
        }catch(Exception e){if(descriptor!=null)try{descriptor.close();}catch(Exception ignored){}copy.delete();if(e instanceof IOException)throw(IOException)e;throw new IOException("Não foi possível abrir este PDF. Se houver senha, escolha uma cópia desbloqueada.",e);}
    }
    Bitmap preview(int page)throws IOException{return render(page,1500);}
    private Bitmap render(int number,int longest)throws IOException{
        if(number<0||number>=pages)throw new IOException("Página inválida.");
        try(PdfRenderer.Page page=renderer.openPage(number)){
            double scale=Math.min((double)longest/Math.max(page.getWidth(),page.getHeight()),Math.sqrt(6000000d/((double)page.getWidth()*page.getHeight())));
            Bitmap bitmap=Bitmap.createBitmap(Math.max(1,(int)Math.ceil(page.getWidth()*scale)),Math.max(1,(int)Math.ceil(page.getHeight()*scale)),Bitmap.Config.ARGB_8888);
            bitmap.eraseColor(Color.WHITE);
            try{page.render(bitmap,null,null,PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY);return bitmap;}catch(Exception e){bitmap.recycle();throw e;}
        }catch(Exception e){throw new IOException("Não foi possível visualizar a página "+(number+1)+".",e);}
    }
    private String embeddedText(int number){
        if(Build.VERSION.SDK_INT<35)return "";
        // Optional system API: older Android versions fall back to bundled OCR.
        try(PdfRenderer.Page page=renderer.openPage(number)){
            Object contents=page.getClass().getMethod("getTextContents").invoke(page);StringBuilder text=new StringBuilder();
            if(contents instanceof List)for(Object item:(List<?>)contents){Object value=item.getClass().getMethod("getText").invoke(item);if(value!=null)text.append(value).append('\n');}
            return NativeSpeechText.normalize(text.toString());
        }catch(Exception unsupported){return "";}
    }
    String text(int number,boolean forceOcr,boolean sensitive,BooleanSupplier alive)throws Exception{
        if(!alive.getAsBoolean())throw new InterruptedException();
        String embedded=forceOcr?"":embeddedText(number);
        if(!forceOcr&&NativeSpeechText.letters(embedded)>=60&&!embedded.contains("\ufffd"))return embedded;
        if(recognizer==null)recognizer=TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS);
        Bitmap bitmap=render(number,sensitive?3200:2200);Task<Text> pending=null;
        try{
            if(!alive.getAsBoolean())throw new InterruptedException();
            pending=recognizer.process(InputImage.fromBitmap(bitmap,0));String recognized=NativeSpeechText.normalize(Tasks.await(pending,30,TimeUnit.SECONDS).getText());
            if(!alive.getAsBoolean())throw new InterruptedException();
            if(sensitive&&NativeSpeechText.letters(recognized)<60){
                Bitmap enhanced=enhance(bitmap);Task<Text> retryTask=null;
                if(enhanced!=null)try{
                    retryTask=recognizer.process(InputImage.fromBitmap(enhanced,0));String retry=NativeSpeechText.normalize(Tasks.await(retryTask,30,TimeUnit.SECONDS).getText());
                    if(!alive.getAsBoolean())throw new InterruptedException();
                    if(NativeSpeechText.letters(retry)>NativeSpeechText.letters(recognized)*1.3)recognized=retry;
                }finally{recycleAfter(enhanced,retryTask);}
            }
            if(forceOcr||NativeSpeechText.letters(recognized)>NativeSpeechText.letters(embedded)*1.3)return recognized.isEmpty()?embedded:recognized;
            return embedded;
        }finally{recycleAfter(bitmap,pending);}
    }
    private static Bitmap enhance(Bitmap bitmap){
        int width=bitmap.getWidth(),height=bitmap.getHeight();int[] pixels=new int[width*height],hist=new int[256];bitmap.getPixels(pixels,0,width,0,0,width,height);
        for(int color:pixels){int gray=(Color.red(color)*299+Color.green(color)*587+Color.blue(color)*114)/1000;hist[gray]++;}
        int low=0,high=255,count=0;for(int i=0;i<256;i++){count+=hist[i];if(count>pixels.length*.0005){low=i;break;}}
        count=0;for(int i=255;i>=0;i--){count+=hist[i];if(count>pixels.length*.0005){high=i;break;}}
        if(high-low<8)return null;
        for(int i=0;i<pixels.length;i++){int color=pixels[i],gray=(Color.red(color)*299+Color.green(color)*587+Color.blue(color)*114)/1000;int value=Math.max(0,Math.min(255,(gray-low)*255/(high-low)));pixels[i]=Color.rgb(value,value,value);}
        return Bitmap.createBitmap(pixels,width,height,Bitmap.Config.ARGB_8888);
    }
    private static void recycleAfter(Bitmap bitmap,Task<?> task){if(task==null||task.isComplete())bitmap.recycle();else task.addOnCompleteListener(Runnable::run,finished->bitmap.recycle());}
    @Override public void close(){if(recognizer!=null)recognizer.close();renderer.close();try{descriptor.close();}catch(Exception ignored){}copy.delete();}
}
