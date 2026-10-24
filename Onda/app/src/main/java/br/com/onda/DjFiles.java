package br.com.onda;
import android.content.*;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;
import androidx.media3.common.MediaItem;
/** Resolve only Android's local media/document providers; never contact cloud providers. */
@androidx.media3.common.util.UnstableApi
final class DjFiles {
 static String key(Context c,MediaItem item){
  if(item.localConfiguration==null)return "id:"+item.mediaId;
  Uri uri=item.localConfiguration.uri;String authority=uri.getAuthority();
  if(!"content".equals(uri.getScheme()))return "id:"+item.mediaId;
  if(Build.VERSION.SDK_INT>=29&&("com.android.externalstorage.documents".equals(authority)||"com.android.providers.media.documents".equals(authority)||"com.android.providers.downloads.documents".equals(authority))){try{Uri media=MediaStore.getMediaUri(c,uri);if(media!=null)uri=media;}catch(RuntimeException ignored){}}
  if("media".equals(uri.getAuthority())){try{long id=ContentUris.parseId(uri);if(id>=0)return "media:"+id;}catch(RuntimeException ignored){}}
  return uri.toString();
 }
}
