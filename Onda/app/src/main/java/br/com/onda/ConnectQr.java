package br.com.onda;
import android.graphics.Bitmap;
import com.google.zxing.*;
import com.google.zxing.common.*;
import java.util.*;
final class ConnectQr {
 static Bitmap make(String text,int size)throws Exception{BitMatrix matrix=new MultiFormatWriter().encode(text,BarcodeFormat.QR_CODE,size,size);int[] pixels=new int[size*size];for(int y=0;y<size;y++)for(int x=0;x<size;x++)pixels[y*size+x]=matrix.get(x,y)?0xff000000:0xffffffff;return Bitmap.createBitmap(pixels,size,size,Bitmap.Config.ARGB_8888);}
 static String read(Bitmap bitmap)throws Exception{int w=bitmap.getWidth(),h=bitmap.getHeight();int[] data=new int[w*h];bitmap.getPixels(data,0,w,0,0,w,h);return decode(new RGBLuminanceSource(w,h,data));}
 static String decode(LuminanceSource source)throws Exception{Map<DecodeHintType,Object> hints=new EnumMap<>(DecodeHintType.class);hints.put(DecodeHintType.POSSIBLE_FORMATS,Collections.singletonList(BarcodeFormat.QR_CODE));hints.put(DecodeHintType.TRY_HARDER,Boolean.TRUE);return new MultiFormatReader().decode(new BinaryBitmap(new HybridBinarizer(source)),hints).getText();}
}
