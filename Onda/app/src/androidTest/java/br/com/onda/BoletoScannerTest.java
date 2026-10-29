package br.com.onda;
import android.graphics.*;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.oned.ITFWriter;
import org.junit.Test;
import static org.junit.Assert.*;
import java.util.*;
public class BoletoScannerTest {
 @Test public void readsInterleavedBarcodeAndRotatedCopy()throws Exception{String barcode="00193373700000001000500940144816060680935031",line="00190500954014481606906809350314337370000000100";BitMatrix bits=new ITFWriter().encode(barcode,BarcodeFormat.ITF,1200,180);Bitmap image=Bitmap.createBitmap(bits.getWidth(),bits.getHeight(),Bitmap.Config.ARGB_8888);for(int y=0;y<bits.getHeight();y++)for(int x=0;x<bits.getWidth();x++)image.setPixel(x,y,bits.get(x,y)?Color.BLACK:Color.WHITE);Matrix m=new Matrix();m.postRotate(90);Bitmap rotated=Bitmap.createBitmap(image,0,0,image.getWidth(),image.getHeight(),m,false);try{for(Bitmap b:new Bitmap[]{image,rotated}){List<BoletoCode> found=BoletoScanner.read(b);assertEquals(1,found.size());assertEquals(line,found.get(0).line);}Bitmap inverted=Bitmap.createBitmap(image.getWidth(),image.getHeight(),Bitmap.Config.ARGB_8888);Canvas canvas=new Canvas(inverted);Paint paint=new Paint();paint.setColorFilter(new ColorMatrixColorFilter(new ColorMatrix(new float[]{-1,0,0,0,255,0,-1,0,0,255,0,0,-1,0,255,0,0,0,1,0})));canvas.drawBitmap(image,0,0,paint);try{assertEquals(line,BoletoScanner.read(inverted).get(0).line);}finally{inverted.recycle();}}finally{image.recycle();rotated.recycle();}}
}
