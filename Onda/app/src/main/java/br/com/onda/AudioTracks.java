package br.com.onda;
import android.media.*;
import java.io.IOException;
/** Bounded track inspection, only when a user requests conversion. No file scanning. */
final class AudioTracks {
 static boolean aac(MediaFormat f){return "audio/mp4a-latm".equals(f.getString(MediaFormat.KEY_MIME));}
 static boolean supported(MediaFormat f){
  try{String mime=f.getString(MediaFormat.KEY_MIME);if(mime==null||!mime.startsWith("audio/"))return false;
   int channels=f.getInteger(MediaFormat.KEY_CHANNEL_COUNT),rate=f.getInteger(MediaFormat.KEY_SAMPLE_RATE);
   if(channels<1||channels>2||rate<8000||rate>192000)return false;
   if("audio/raw".equals(mime))return !f.containsKey(MediaFormat.KEY_PCM_ENCODING)||f.getInteger(MediaFormat.KEY_PCM_ENCODING)==android.media.AudioFormat.ENCODING_PCM_16BIT;
   return new MediaCodecList(MediaCodecList.REGULAR_CODECS).findDecoderForFormat(f)!=null;
  }catch(RuntimeException e){return false;}
 }
 static int select(MediaExtractor ex)throws IOException{
  // Prefer AAC to keep the existing lossless M4A extraction choice consistent.
  int other=-1;for(int i=0;i<ex.getTrackCount();i++){MediaFormat f=ex.getTrackFormat(i);if(supported(f)){if(aac(f))return i;if(other<0)other=i;}}
  if(other>=0)return other;throw new IOException("Nenhuma faixa de áudio conversível foi encontrada. É necessário áudio mono/estéreo com decoder disponível, ou WAV PCM de 16 bits. DRM e arquivos danificados não são convertidos.");
 }
}
