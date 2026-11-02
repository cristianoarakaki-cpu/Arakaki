package br.com.onda;
import android.os.Bundle;import androidx.media3.common.*;
@androidx.media3.common.util.UnstableApi
final class RadioMedia {
 static boolean is(MediaItem item){return item!=null&&item.mediaId.startsWith("radio:");}
 static MediaItem item(RadioStation s){Bundle extras=new Bundle();extras.putString("radio_country",s.country);extras.putString("radio_codec",s.codec);extras.putBoolean("radio_hls",s.hls);extras.putInt("radio_bitrate",s.bitrate);MediaItem.Builder item=new MediaItem.Builder().setMediaId("radio:"+s.id).setUri(s.url).setMediaMetadata(new MediaMetadata.Builder().setTitle(s.name).setArtist("Rádio online"+(s.country.isEmpty()?"":" • "+s.country)).setExtras(extras).build());if(s.hls)item.setMimeType(MimeTypes.APPLICATION_M3U8);return item.build();}
 static RadioStation station(MediaItem item){if(!is(item)||item.localConfiguration==null)return null;Bundle b=item.mediaMetadata.extras;try{return new RadioStation(item.mediaId.substring(6),String.valueOf(item.mediaMetadata.title),item.localConfiguration.uri.toString(),b==null?"":b.getString("radio_country",""),b==null?"":b.getString("radio_codec",""),b==null?0:b.getInt("radio_bitrate"),b!=null&&b.getBoolean("radio_hls"));}catch(Exception e){return null;}}
}
