package br.com.onda;
import android.os.Bundle;
import androidx.media3.common.*;
/** Preserves raw stream metadata: MediaItem's station title overrides it in ExoPlayer. */
@androidx.media3.common.util.UnstableApi
final class RadioTrackMetadata {
 static final String ID="radio_now_id",TITLE="radio_now_title",ARTIST="radio_now_artist";
 static Bundle from(MediaItem item,Metadata metadata){Bundle out=new Bundle();if(!RadioMedia.is(item))return out;MediaMetadata fields=new MediaMetadata.Builder().populateFromMetadata(metadata).build();out.putString(ID,item.mediaId);out.putString(TITLE,TrackIdentity.clean(fields.title));out.putString(ARTIST,TrackIdentity.clean(fields.artist));return out;}
 static boolean same(Bundle a,Bundle b){return a.getString(ID,"").equals(b.getString(ID,""))&&a.getString(TITLE,"").equals(b.getString(TITLE,""))&&a.getString(ARTIST,"").equals(b.getString(ARTIST,""));}
 static TrackIdentity read(MediaItem item,MediaMetadata current,Bundle extras){boolean matched=item.mediaId.equals(extras.getString(ID,""));return TrackIdentity.radio(String.valueOf(item.mediaMetadata.title),matched?extras.getString(TITLE,""):current.title,matched?extras.getString(ARTIST,""):current.artist);}
}
