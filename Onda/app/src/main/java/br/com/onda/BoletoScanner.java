package br.com.onda;
import android.graphics.*;
import com.google.zxing.*;
import com.google.zxing.common.*;
import com.google.zxing.multi.GenericMultipleBarcodeReader;
import java.util.*;
import java.util.function.BooleanSupplier;
final class BoletoScanner {
 static List<BoletoCode> read(Bitmap image){return read(image,()->false);}
 static List<BoletoCode> read(Bitmap image,BooleanSupplier cancelled){
  List<BoletoCode> out=new ArrayList<>();Set<String> seen=new HashSet<>();
  if((long)image.getWidth()*image.getHeight()>PdfBook.MAX_PIXELS)throw new IllegalArgumentException("Imagem grande demais");
  for(int angle:new int[]{0,90}){if(cancelled.getAsBoolean())break;Matrix matrix=new Matrix();matrix.postRotate(angle);Bitmap rotated=angle==0?image:Bitmap.createBitmap(image,0,0,image.getWidth(),image.getHeight(),matrix,false);try{scan(rotated,out,seen,cancelled);}finally{if(rotated!=image)rotated.recycle();}}return out;
 }
 private static void scan(Bitmap image,List<BoletoCode> out,Set<String> seen,BooleanSupplier cancelled){
  int w=image.getWidth(),h=image.getHeight();int[] pixels=new int[w*h];image.getPixels(pixels,0,w,0,0,w,h);LuminanceSource source=new RGBLuminanceSource(w,h,pixels);
  Map<DecodeHintType,Object> hints=new EnumMap<>(DecodeHintType.class);hints.put(DecodeHintType.POSSIBLE_FORMATS,Collections.singletonList(BarcodeFormat.ITF));hints.put(DecodeHintType.ALLOWED_LENGTHS,new int[]{44});hints.put(DecodeHintType.TRY_HARDER,Boolean.TRUE);
  int before=out.size();decode(new HybridBinarizer(source),hints,out,seen,cancelled);
  if(out.size()==before)decode(new GlobalHistogramBinarizer(source),hints,out,seen,cancelled);
  if(out.size()==before)decode(new HybridBinarizer(source.invert()),hints,out,seen,cancelled);
 }
 private static void decode(Binarizer binarizer,Map<DecodeHintType,Object> hints,List<BoletoCode> out,Set<String> seen,BooleanSupplier cancelled){
  if(cancelled.getAsBoolean()||out.size()>=10)return;
  try{Result[] results=new GenericMultipleBarcodeReader(new MultiFormatReader()).decodeMultiple(new BinaryBitmap(binarizer),hints);for(Result result:results){if(cancelled.getAsBoolean()||out.size()>=10)return;BoletoCode code=BoletoCode.from(result.getText());if(code!=null&&seen.add(code.barcode))out.add(code);}}catch(NotFoundException ignored){}
 }
}
