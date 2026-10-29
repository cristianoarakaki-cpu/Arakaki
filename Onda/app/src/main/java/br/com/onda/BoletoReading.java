package br.com.onda;
import java.util.*;

/** Preserve every validated candidate and its independent sources; never correct digits. */
final class BoletoReading {
 static final int TEXT=1,BARS=2,OCR=4;
 final List<BoletoCode> codes=new ArrayList<>();
 private final Map<String,Integer> sources=new HashMap<>();
 boolean ocrUsed;String warning="";
 void add(List<BoletoCode> found,int source){for(BoletoCode code:found){Integer old=sources.get(code.barcode);if(old==null){if(codes.size()>=10)continue;codes.add(code);old=0;}sources.put(code.barcode,old|source);}}
 boolean hasSource(int source){for(int value:sources.values())if((value&source)!=0)return true;return false;}
 boolean agrees(BoletoCode code){int value=sources.get(code.barcode);return (value&BARS)!=0&&(value&(TEXT|OCR))!=0;}
 String description(BoletoCode code){int value=sources.get(code.barcode);if(agrees(code))return "Linha e barras coincidem";if((value&BARS)!=0)return "Código de barras";return (value&TEXT)!=0?"Texto original do PDF":"Texto reconhecido por OCR • confira os números";}
 boolean differentSources(){Set<String> lines=new HashSet<>(),bars=new HashSet<>();for(BoletoCode code:codes){int value=sources.get(code.barcode);if((value&(TEXT|OCR))!=0)lines.add(code.barcode);if((value&BARS)!=0)bars.add(code.barcode);}return !lines.isEmpty()&&!bars.isEmpty()&&!lines.equals(bars);}
}
