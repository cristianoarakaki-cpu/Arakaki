package br.com.onda;
import android.media.*;
import java.io.*;
import java.nio.*;

/** Preserve AAC-LC packets with ADTS headers. No decoding or lossy re-encoding. */
final class AdtsAudio {
 static final int[] RATES={96000,88200,64000,48000,44100,32000,24000,22050,16000,12000,11025,8000,7350};
 static void extract(File source,File output,DownloadMux.Cancel cancel)throws IOException{
  MediaExtractor ex=new MediaExtractor();try(OutputStream out=new BufferedOutputStream(new FileOutputStream(output))){
   cancel.check();ex.setDataSource(source.getPath());MediaFormat format=null;for(int i=0;i<ex.getTrackCount();i++)if("audio/mp4a-latm".equals(ex.getTrackFormat(i).getString(MediaFormat.KEY_MIME))){format=ex.getTrackFormat(i);ex.selectTrack(i);break;}if(format==null)throw new IOException("Faixa AAC indisponível neste arquivo.");
   int rate=format.getInteger(MediaFormat.KEY_SAMPLE_RATE),channels=format.getInteger(MediaFormat.KEY_CHANNEL_COUNT),index=-1;for(int i=0;i<RATES.length;i++)if(RATES[i]==rate)index=i;
   ByteBuffer csd=format.getByteBuffer("csd-0");if(csd==null||csd.remaining()<2)throw new IOException("Configuração AAC indisponível.");ByteBuffer config=csd.duplicate();int a=config.get()&255,b=config.get()&255,profile=a>>3,frequency=((a&7)<<1)|(b>>7),channelConfig=(b>>3)&15;
   if(profile!=2||index<0||frequency!=index||channels<1||channels>2||channelConfig!=channels)throw new IOException("Extração ADTS disponível para AAC-LC mono/estéreo. Escolha M4A para este áudio.");
   ByteBuffer buffer=ByteBuffer.allocate(8192);byte[] bytes=new byte[8192];long written=0;while(true){cancel.check();buffer.clear();int n=ex.readSampleData(buffer,0);if(n<0)break;if(n==0){ex.advance();continue;}int size=n+7;if(size>8191)throw new IOException("Pacote AAC grande demais para ADTS.");byte[] header={(byte)255,(byte)241,(byte)((1<<6)|(index<<2)|(channels>>2)),(byte)(((channels&3)<<6)|(size>>11)),(byte)(size>>3),(byte)(((size&7)<<5)|31),(byte)252};out.write(header);buffer.position(0);buffer.get(bytes,0,n);out.write(bytes,0,n);written+=size;if(written>512L*1024*1024)throw new IOException("Áudio excede 512 MB.");ex.advance();}if(written==0)throw new IOException("Arquivo sem pacotes AAC.");cancel.check();
  }catch(RuntimeException error){throw new IOException("Não foi possível extrair AAC. Escolha M4A ou MP3.",error);}finally{ex.release();}
 }
}
