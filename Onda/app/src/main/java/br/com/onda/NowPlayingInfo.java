package br.com.onda;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import androidx.media3.common.*;

/** Uses existing player events/metadata, without network, microphone or polling. */
@androidx.media3.common.util.UnstableApi
final class NowPlayingInfo {
 static TrackIdentity read(Player player){MediaItem item=player.getCurrentMediaItem();if(item==null)return null;MediaMetadata initial=item.mediaMetadata,current=player.getMediaMetadata();if(RadioMedia.is(item))return TrackIdentity.radio(String.valueOf(initial.title),current.title,current.artist);return new TrackIdentity(TrackIdentity.choose(current.title,initial.title),TrackIdentity.choose(current.artist,initial.artist),TrackIdentity.choose(current.composer,initial.composer),TrackIdentity.choose(current.albumTitle,initial.albumTitle),YouTubeAudio.is(item)?"Metadados do vídeo":"Metadados do arquivo e do Android","");}
 static void show(Activity activity,Player player){if(player==null)return;TrackIdentity info=read(player);if(info==null){new AlertDialog.Builder(activity).setMessage("Selecione uma música ou rádio primeiro.").setPositiveButton("OK",null).show();return;}new AlertDialog.Builder(activity).setTitle("Que música é esta?").setMessage(info.details()).setPositiveButton("Fechar",null).setNeutralButton("Copiar informações",(dialog,which)->{ClipboardManager clipboard=(ClipboardManager)activity.getSystemService(Context.CLIPBOARD_SERVICE);if(clipboard!=null)clipboard.setPrimaryClip(ClipData.newPlainText("Música no Onda",info.details()));}).show();}
}
