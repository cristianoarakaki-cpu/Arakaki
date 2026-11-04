package br.com.onda;

import android.content.Context;
import android.net.Uri;
import androidx.media3.common.*;

/** Persist the public identity only. Signed media URLs expire and are never written to disk. */
@androidx.media3.common.util.UnstableApi
final class YouTubeAudio {
 static final String RESTORE="youtube_restore_music",LISTEN="youtube_listen_audio";
 static String canonical(String input){try{return DownloadLinks.canonical(input);}catch(Exception e){return "";}}
 static boolean is(MediaItem item){return item!=null&&item.mediaId.startsWith("youtube-audio:")&&!source(item).isEmpty();}
 static String source(MediaItem item){return item==null||item.requestMetadata.mediaUri==null?"":canonical(item.requestMetadata.mediaUri.toString());}
 static MediaItem item(String source,String title,String stream,String mime){String url=canonical(source);if(url.isEmpty())throw new IllegalArgumentException("Escolha um vídeo do YouTube.");return new MediaItem.Builder().setMediaId("youtube-audio:"+Uri.parse(url).getQueryParameter("v")).setUri(stream).setMimeType(mime).setRequestMetadata(new MediaItem.RequestMetadata.Builder().setMediaUri(Uri.parse(url)).build()).setMediaMetadata(new MediaMetadata.Builder().setTitle(title).setArtist("YouTube • áudio").build()).build();}
 static int repeat(Context c,String source){android.content.SharedPreferences p=c.getSharedPreferences("youtube_audio",0);return p.getBoolean("active",false)&&canonical(source).equals(saved(c))&&p.getInt("repeat",Player.REPEAT_MODE_OFF)==Player.REPEAT_MODE_ONE?Player.REPEAT_MODE_ONE:Player.REPEAT_MODE_OFF;}
 static void remember(Context c,MediaItem item,long position){remember(c,item,position,repeat(c,source(item)));}
 static void remember(Context c,MediaItem item,long position,int repetition){if(!is(item))return;android.content.SharedPreferences p=c.getSharedPreferences("youtube_audio",0);String url=source(item),title=String.valueOf(item.mediaMetadata.title);long at=Math.max(0,position);int mode=repetition==Player.REPEAT_MODE_ONE||repetition==Player.REPEAT_MODE_ALL?Player.REPEAT_MODE_ONE:Player.REPEAT_MODE_OFF;if(p.getBoolean("active",false)&&url.equals(p.getString("source",""))&&title.equals(p.getString("title",""))&&at==p.getLong("position",-1)&&mode==p.getInt("repeat",Player.REPEAT_MODE_OFF))return;p.edit().putBoolean("active",true).putString("source",url).putString("title",title).putLong("position",at).putInt("repeat",mode).apply();}
 static String saved(Context c){return canonical(c.getSharedPreferences("youtube_audio",0).getString("source",""));}
 static boolean active(Context c){return c.getSharedPreferences("youtube_audio",0).getBoolean("active",false)&&!saved(c).isEmpty();}
 static void clear(Context c){c.getSharedPreferences("youtube_audio",0).edit().putBoolean("active",false).putInt("repeat",Player.REPEAT_MODE_OFF).apply();}
 static boolean expired(MediaItem item){if(!is(item)||item.localConfiguration==null)return true;try{String end=item.localConfiguration.uri.getQueryParameter("expire");return end!=null&&Long.parseLong(end)*1000L<System.currentTimeMillis()+30000;}catch(Exception e){return true;}}
}
