package br.com.onda;
import android.content.Context;
import java.io.*;
final class AudioTestFixtures {
 static File tone(Context c,long ms)throws IOException{return wave(c,new long[]{ms});}
 static File collection(Context c)throws IOException{return wave(c,new long[]{31000,1800,31000,1800,31000});}
 private static void little(OutputStream out,long value,int bytes)throws IOException{for(int i=0;i<bytes;i++)out.write((int)(value>>(8*i))&255);}
 private static File wave(Context c,long[] periods)throws IOException{int rate=8000;long frames=0;for(long ms:periods)frames+=ms*rate/1000;File file=File.createTempFile("audio-native-",".wav",c.getCacheDir());try(OutputStream out=new BufferedOutputStream(new FileOutputStream(file),32768)){out.write("RIFF".getBytes("US-ASCII"));little(out,36+frames*2,4);out.write("WAVEfmt ".getBytes("US-ASCII"));little(out,16,4);little(out,1,2);little(out,1,2);little(out,rate,4);little(out,rate*2,4);little(out,2,2);little(out,16,2);out.write("data".getBytes("US-ASCII"));little(out,frames*2,4);long position=0;for(int part=0;part<periods.length;part++)for(long i=0;i<periods[part]*rate/1000;i++,position++){int sample=part%2==1?0:(int)(10000*Math.sin(2*Math.PI*440*position/rate));little(out,sample,2);}}return file;}
}
