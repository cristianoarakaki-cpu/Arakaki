package br.com.onda;
import android.graphics.*;
import com.google.zxing.*;
import com.google.zxing.common.HybridBinarizer;
import com.google.zxing.multi.GenericMultipleBarcodeReader;
import java.util.*;
final class BoletoScanner {
 static List<BoletoCode> read(Bitmap image){List<BoletoCode> out=new ArrayList<>();Set<String> seen=new HashSet<>();scan(image,out,seen);if(out.isEmpty()){Matrix matrix=new Matrix();matrix.postRotate(90);Bitmap rotated=Bitmap.createBitmap(image,0,0,image.getWidth(),image.getHeight(),matrix,false);try{scan(rotated,out,seen);}finally{if(rotated!=image)rotated.recycle();}}return out;}
 private static void scan(Bitmap image,List<BoletoCode> out,Set<String> seen){int w=image.getWidth(),h=image.getHeight();int[] pixels=new int[w*h];image.getPixels(pixels,0,w,0,0,w,h);RGBLuminanceSource source=new RGBLuminanceSource(w,h,pixels);Map<DecodeHintType,Object> hints=new EnumMap<>(DecodeHintType.class);hints.put(DecodeHintType.POSSIBLE_FORMATS,Collections.singletonList(BarcodeFormat.ITF));hints.put(DecodeHintType.ALLOWED_LENGTHS,new int[]{44});hints.put(DecodeHintType.TRY_HARDER,Boolean.TRUE);try{Result[] results=new GenericMultipleBarcodeReader(new MultiFormatReader()).decodeMultiple(new BinaryBitmap(new HybridBinarizer(source)),hints);for(Result result:results){BoletoCode code=BoletoCode.from(result.getText());if(code!=null&&seen.add(code.barcode))out.add(code);}}catch(NotFoundException ignored){}}
}
