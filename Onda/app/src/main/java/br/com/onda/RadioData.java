package br.com.onda;
import java.util.*;
/** Metadata estimates only. Direct single-bitrate streams cannot be compressed by the receiver. */
final class RadioData {
 static final String KEY="economy";static final int ADAPTIVE_MAX=64000;
 static double megabytesPerHour(int kbps){return Math.max(0,kbps)*.45d;}
 static String estimate(int kbps){return kbps<=0?"Consumo não informado":String.format(new Locale("pt","BR"),"~%.1f MB/h",megabytesPerHour(kbps));}
 static List<RadioStation> order(Collection<RadioStation> stations,boolean economy){List<RadioStation> out=new ArrayList<>(stations);if(economy)out.sort(Comparator.comparingInt((RadioStation s)->s.bitrate>0?s.bitrate:Integer.MAX_VALUE));return out;}
}
