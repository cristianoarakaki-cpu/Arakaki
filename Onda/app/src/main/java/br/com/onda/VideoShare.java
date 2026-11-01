package br.com.onda;
import android.content.Context;
import android.media.MediaExtractor;
import android.media.MediaFormat;
import android.net.Uri;
/** A completed local MP4 is handed to Android, never a CDN URL or partial file. */
final class VideoShare {
 static final String EXTRA="share_video_source",REQUEST="share_video_request",READY="share_video_ready_request";
 static String source(String raw){try{if(MediaLinks.isYoutube(raw)){String video=YouTubeShare.video(raw);if(!video.isEmpty())return video;}return MediaLinks.resolve(raw);}catch(Exception e){return "";}}
 static boolean canFile(String raw){String value=source(raw);if(value.isEmpty()||DownloadLinks.isPlaylist(value))return false;String extension=MediaLinks.extension(value);return extension.isEmpty()||extension.equals("mp4");}
 static boolean eligible(YoutubeDownloads.Option option,String source){return "mp4".equals(option.extension)&&(!MediaLinks.isYoutube(source)||option.combinedAudio||option.second!=null&&!option.second.isEmpty());}
 static boolean same(String a,String b){String first=source(a),second=source(b);return !first.isEmpty()&&first.equals(second);}
 static DownloadHistory.Entry cached(Context c,String source)throws Exception{int checked=0;for(DownloadHistory.Entry entry:DownloadHistory.read(c)){if(!entry.state.equals("done")||!entry.format.equals("mp4")||!same(source,entry.source)||entry.uri.isEmpty())continue;if(Thread.currentThread().isInterrupted())throw new InterruptedException();if(checked++>=3)break;MediaExtractor reader=new MediaExtractor();try{Uri uri=Uri.parse(entry.uri);if(!"content".equals(uri.getScheme())&&!"file".equals(uri.getScheme()))continue;reader.setDataSource(c,uri,null);for(int i=0;i<reader.getTrackCount();i++){String mime=reader.getTrackFormat(i).getString(MediaFormat.KEY_MIME);if(mime!=null&&mime.startsWith("video/"))return entry;}}catch(Exception unavailable){}finally{reader.release();}}return null;}
 static void complete(Context c,String request,String format,Uri uri,String title){if(request==null||!request.matches("[A-Fa-f0-9-]{36}")||!"mp4".equals(format))return;c.getSharedPreferences("downloads",0).edit().putString(READY,request).putString("share_video_uri",uri.toString()).putString("share_video_title",title==null?"Vídeo":title).apply();}
 static String ready(Context c,String request){if(request==null||request.isEmpty()||MediaDownloadService.activeDownload)return "";android.content.SharedPreferences p=c.getSharedPreferences("downloads",0);return request.equals(p.getString(READY,""))&&!p.getBoolean("busy",false)?p.getString("share_video_uri",""):"";}
}
