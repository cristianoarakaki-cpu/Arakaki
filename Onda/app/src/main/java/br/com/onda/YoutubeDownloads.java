package br.com.onda;

import org.schabi.newpipe.extractor.*;
import org.schabi.newpipe.extractor.stream.*;
import org.schabi.newpipe.extractor.playlist.PlaylistInfo;
import org.schabi.newpipe.extractor.ListExtractor.InfoItemsPage;
import java.util.*;

final class YoutubeDownloads {
 static final class Option {
  final String title,first,second,extension,mime,referer,requestCookies;final boolean original,combinedAudio,photoVideo;
  Option(String title,String first,String second,String extension,String mime){this(title,first,second,extension,mime,false,"");}
  Option(String title,String first,String second,String extension,String mime,boolean original,String referer){this(title,first,second,extension,mime,original,referer,false);}
  Option(String title,String first,String second,String extension,String mime,boolean original,String referer,boolean combinedAudio){this(title,first,second,extension,mime,original,referer,combinedAudio,"");}
  Option(String title,String first,String second,String extension,String mime,boolean original,String referer,boolean combinedAudio,String requestCookies){this(title,first,second,extension,mime,original,referer,combinedAudio,requestCookies,false);}
  Option(String title,String first,String second,String extension,String mime,boolean original,String referer,boolean combinedAudio,String requestCookies,boolean photoVideo){this.photoVideo=photoVideo;this.requestCookies=requestCookies==null?"":requestCookies;this.combinedAudio=combinedAudio;this.title=title;this.first=first;this.second=second;this.extension=extension;this.mime=mime;this.original=original;this.referer=referer;}
 }
 static final class Result {final String title;final List<Option> options;Result(String t,List<Option> o){title=t;options=o;}}
 private static boolean ready;
 private static synchronized void init(){if(!ready){NewPipe.init(new ExtractorHttp());ready=true;}}
 private static boolean usable(Stream s){return s.isUrl()&&s.getContent().startsWith("https://")&&s.getDeliveryMethod()==DeliveryMethod.PROGRESSIVE_HTTP;}
 @androidx.media3.common.util.UnstableApi
 static androidx.media3.common.MediaItem audioInfo(String link)throws Exception {
  String url=DownloadLinks.canonical(link);init();ExtractorHttp.begin();try{
   StreamExtractor extractor=ServiceList.YouTube.getStreamExtractor(url);extractor.forceLocalization(new org.schabi.newpipe.extractor.localization.Localization("pt","BR"));extractor.forceContentCountry(new org.schabi.newpipe.extractor.localization.ContentCountry("BR"));StreamInfo info=StreamInfo.getInfo(extractor);AudioStream best=YoutubeAudioChoice.select(info.getAudioStreams());
   if(best==null)throw new Exception("O YouTube não disponibilizou áudio separado acessível para este vídeo. A reprodução na página continua disponível.");
   ExtractorHttp.remaining();androidx.media3.common.MediaItem item=YouTubeAudio.item(url,info.getName(),best.getContent(),best.getFormat().getMimeType());android.os.Bundle extras=new android.os.Bundle();long seconds=info.getDuration();extras.putLong("durationMs",seconds>0&&seconds<=Long.MAX_VALUE/1000?seconds*1000:0);String language=YoutubeAudioChoice.notice(best);extras.putString("audio_language",language);return item.buildUpon().setMediaMetadata(item.mediaMetadata.buildUpon().setArtist("YouTube • "+language).setExtras(extras).build()).build();
  }finally{ExtractorHttp.end();}
 }
 static Result inspect(String link)throws Exception {
  init();ExtractorHttp.begin();try{String url=DownloadLinks.canonical(link);StreamInfo info=StreamInfo.getInfo(ServiceList.YouTube,url);
  if(info.getStreamType()!=StreamType.VIDEO_STREAM||info.getDuration()<=0)throw new Exception("Esta versão aceita vídeos gravados, sem transmissão ao vivo.");
  List<Option> options=new ArrayList<>();AudioStream audio=null;
  for(AudioStream a:info.getAudioStreams())if(usable(a)&&a.getFormat()==MediaFormat.M4A&&(audio==null||a.getAverageBitrate()>audio.getAverageBitrate()))audio=a;
  if(audio!=null){options.add(new Option("Áudio MP3 • taxa configurada • converter",audio.getContent(),null,"mp3","audio/mpeg"));}
  if(audio!=null)options.add(new Option("Áudio AAC • sem recodificar",audio.getContent(),null,"aac","audio/aac"));
  if(audio!=null)options.add(new Option("Áudio M4A • "+audio.getAverageBitrate()+" kbps",audio.getContent(),null,"m4a","audio/mp4"));
  Set<String> resolutions=new HashSet<>();
  for(VideoStream v:info.getVideoStreams())if(usable(v)&&v.getFormat()==MediaFormat.MPEG_4&&!v.isVideoOnly()&&resolutions.add(v.getResolution()))options.add(new Option("Vídeo MP4 • "+v.getResolution()+" • com som",v.getContent(),null,"mp4","video/mp4",false,"",true));
  if(audio!=null)for(VideoStream v:info.getVideoOnlyStreams())if(usable(v)&&v.getFormat()==MediaFormat.MPEG_4&&v.getCodec()!=null&&v.getCodec().startsWith("avc")&&resolutions.add(v.getResolution()))options.add(new Option("Vídeo MP4 • "+v.getResolution()+" • juntar áudio",v.getContent(),audio.getContent(),"mp4","video/mp4"));
  if(audio==null){Option combined=combinedAudioSource(options);if(combined!=null){options.add(0,audioFromVideo(combined,"m4a"));options.add(0,audioFromVideo(combined,"aac"));options.add(0,audioFromVideo(combined,"mp3"));}}
  if(options.isEmpty())throw new Exception("Nenhum formato M4A/MP4 compatível disponível para este vídeo.");
  ExtractorHttp.remaining();return new Result(info.getName(),options);
  }finally{ExtractorHttp.end();}
 }
 static final class Entry {final String title,url,thumbnail;final long duration;Entry(String t,String u){this(t,u,"",0);}Entry(String t,String u,String image,long seconds){title=t.length()>160?t.substring(0,160):t;url=DownloadLinks.canonical(u);thumbnail=PlaylistSelection.artwork(image);duration=seconds>0?seconds:0;}}
 static final class Playlist {final String title,url;final List<Entry> items;final boolean limited;final Page next;Playlist(String t,String u,List<Entry> i,Page n){title=t;url=u;items=i;next=n;limited=Page.isValid(n);}}
 static Playlist playlist(String link)throws Exception{
  init();ExtractorHttp.begin();try{String url=DownloadLinks.playlist(link);PlaylistInfo info=PlaylistInfo.getInfo(ServiceList.YouTube,url);List<Entry> items=append(Collections.emptyList(),info.getRelatedItems());if(items.isEmpty())throw new Exception("Playlist privada, vazia ou sem vídeos compatíveis.");return new Playlist(info.getName(),url,items,info.getNextPage());}finally{ExtractorHttp.end();}
 }
 static Playlist more(Playlist previous)throws Exception{
  if(!previous.limited)return previous;init();ExtractorHttp.begin();try{InfoItemsPage<StreamInfoItem> page=PlaylistInfo.getMoreItems(ServiceList.YouTube,previous.url,previous.next);List<Entry> items=append(previous.items,page.getItems());return new Playlist(previous.title,previous.url,items,page.getNextPage());}finally{ExtractorHttp.end();}
 }
 private static List<Entry> append(List<Entry> existing,List<StreamInfoItem> page){List<Entry> items=new ArrayList<>(existing);Set<String> seen=new HashSet<>();for(Entry e:existing)seen.add(e.url);for(StreamInfoItem item:page){if(item.getStreamType()!=StreamType.VIDEO_STREAM)continue;try{String image="";int distance=Integer.MAX_VALUE;for(Image candidate:item.getThumbnails()){int d=candidate.getWidth()>0?Math.abs(candidate.getWidth()-320):10000;if(d<distance&&!PlaylistSelection.artwork(candidate.getUrl()).isEmpty()){image=candidate.getUrl();distance=d;}}Entry e=new Entry(item.getName(),item.getUrl(),image,item.getDuration());if(seen.add(e.url))items.add(e);}catch(IllegalArgumentException ignored){}}return items;}
 static String cursor(Playlist p)throws org.json.JSONException{org.json.JSONObject root=new org.json.JSONObject().put("url",p.url);if(p.next!=null){Page n=p.next;org.json.JSONObject next=new org.json.JSONObject().put("url",n.getUrl()).put("id",n.getId());if(n.getIds()!=null)next.put("ids",new org.json.JSONArray(n.getIds()));if(n.getCookies()!=null)next.put("cookies",new org.json.JSONObject(n.getCookies()));if(n.getBody()!=null)next.put("body",java.util.Base64.getEncoder().encodeToString(n.getBody()));root.put("next",next);}return root.toString();}
 static Playlist restore(String raw,String title,List<Entry> items)throws org.json.JSONException{org.json.JSONObject root=new org.json.JSONObject(raw),n=root.optJSONObject("next");Page next=null;if(n!=null){List<String> ids=null;Map<String,String> cookies=null;if(n.has("ids")){ids=new ArrayList<>();org.json.JSONArray a=n.getJSONArray("ids");for(int i=0;i<a.length();i++)ids.add(a.getString(i));}if(n.has("cookies")){cookies=new HashMap<>();org.json.JSONObject o=n.getJSONObject("cookies");java.util.Iterator<String> keys=o.keys();while(keys.hasNext()){String key=keys.next();cookies.put(key,o.getString(key));}}next=new Page(n.has("url")?n.getString("url"):null,n.has("id")?n.getString("id"):null,ids,cookies,n.has("body")?java.util.Base64.getDecoder().decode(n.getString("body")):null);}return new Playlist(title,DownloadLinks.playlist(root.getString("url")),items,next);}
 private static int height(Option option){java.util.regex.Matcher matcher=java.util.regex.Pattern.compile("(\\d+)p").matcher(option.title);return matcher.find()?Integer.parseInt(matcher.group(1)):0;}
 private static Option combinedAudioSource(List<Option> options){Option best=null;int rank=Integer.MAX_VALUE;for(Option option:options)if(option.extension.equals("mp4")&&option.combinedAudio){int h=height(option),score=h>0?h:Integer.MAX_VALUE;if(best==null||score<rank){best=option;rank=score;}}return best;}
 private static Option audioFromVideo(Option video,String format){return new Option("Áudio "+format.toUpperCase(Locale.ROOT)+" • extrair do vídeo"+(format.equals("mp3")?" • taxa configurada":""),video.first,null,format,MediaDownloads.mime(format),false,video.referer);}
 static Option choose(Result result,String format)throws Exception{
  if("mp3".equals(format)||"m4a".equals(format)||"aac".equals(format)){for(Option option:result.options)if(option.extension.equals(format))return option;Option combined=combinedAudioSource(result.options);if(combined!=null)return audioFromVideo(combined,format);}
  if("mp4".equals(format)){Option best=null;int bestHeight=0;for(Option option:result.options)if(option.extension.equals("mp4")){int h=height(option);if(h>0&&h>bestHeight&&(option.combinedAudio||(option.second!=null&&!option.second.isEmpty()))){best=option;bestHeight=h;}}if(best!=null)return best;}
  java.util.LinkedHashSet<String> available=new java.util.LinkedHashSet<>();for(Option option:result.options){int h=height(option);available.add(option.extension.toUpperCase(Locale.ROOT)+(option.extension.equals("mp4")&&h>0?" "+h+"p":""));if(available.size()>=8)break;}
  throw new Exception(("mp4".equals(format)?"MP4 com som":String.valueOf(format).toUpperCase(Locale.ROOT))+" indisponível para este vídeo. Disponíveis: "+(available.isEmpty()?"nenhum formato compatível":String.join(", ",available))+". Analise o link individual para escolher uma opção disponível.");
 }
}
