package br.com.onda;

import android.content.Context;
import android.content.SharedPreferences;
import android.net.Uri;
import androidx.media3.common.MediaItem;
import androidx.media3.common.MediaMetadata;
import java.util.*;
import org.json.*;

/** User-selected documents need not be indexed by Android's MediaStore. */
@androidx.media3.common.util.UnstableApi
final class DownloadedAudio {
    static String id(String uri) { return "download:" + uri.hashCode(); }
    static synchronized void remember(Context context, String uri, String title, String mime) {
        if (uri == null || !"content".equals(Uri.parse(uri).getScheme()) || mime == null || !mime.startsWith("audio/")) return;
        SharedPreferences prefs=context.getSharedPreferences("downloaded_audio",0);
        try {
            JSONObject all=new JSONObject(prefs.getString("documents","{}"));
            JSONObject entry=new JSONObject().put("title",title==null?"Áudio baixado":title).put("mime",mime);
            if (!entry.toString().equals(all.optJSONObject(uri)==null?"":all.optJSONObject(uri).toString())) {
                all.put(uri,entry);
                prefs.edit().putString("documents",all.toString()).apply();
            }
        } catch (JSONException ignored) { }
    }
    static List<MediaItem> read(Context context) {
        // Recover the last audio opened by older releases, keeping its existing favorite ID.
        SharedPreferences last=context.getSharedPreferences("downloads",0);
        remember(context,last.getString("last_uri",""),last.getString("last_title","Áudio baixado"),last.getString("last_mime",""));
        List<MediaItem> items=new ArrayList<>();
        try {
            JSONObject all=new JSONObject(context.getSharedPreferences("downloaded_audio",0).getString("documents","{}"));
            Iterator<String> keys=all.keys();
            while(keys.hasNext()) {
                String uri=keys.next();JSONObject entry=all.optJSONObject(uri);
                if(entry==null||!"content".equals(Uri.parse(uri).getScheme())||!entry.optString("mime").startsWith("audio/"))continue;
                items.add(new MediaItem.Builder().setMediaId(id(uri)).setUri(uri).setMimeType(entry.optString("mime"))
                    .setMediaMetadata(new MediaMetadata.Builder().setTitle(entry.optString("title","Áudio baixado")).setArtist("Download local").build()).build());
            }
        } catch(JSONException ignored) { }
        return items;
    }
    static void merge(Context context,List<MediaItem> songs) {
        Set<String> ids=new HashSet<>();for(MediaItem song:songs)ids.add(song.mediaId);
        for(MediaItem song:read(context))if(ids.add(song.mediaId))songs.add(song);
    }
}
