package br.com.onda;

import org.schabi.newpipe.extractor.*;
import org.schabi.newpipe.extractor.stream.*;
import org.schabi.newpipe.extractor.playlist.PlaylistInfo;
import org.schabi.newpipe.extractor.ListExtractor.InfoItemsPage;
import java.util.*;

final class YoutubeDownloads {
 static final class Option {
  final String title,first,second,extension,mime;
  Option(String title,String first,String second,String extension,String mime){this.title=title;this.first=first;this.second=second;this.extension=extension;this.mime=mime;}
 }
 static final class Result {final String title;final List<Option> options;Result(String t,List<Option> o){title=t;options=o;}}
 private static boolean ready;
 private static synchronized void init(){if(!ready){NewPipe.init(new ExtractorHttp());ready=true;}}
 private static boolean usable(Stream s){return s.isUrl()&&s.getContent().startsWith("https://")&&s.getDeliveryMethod()==DeliveryMethod.PROGRESSIVE_HTTP;}
 static Result inspect(String link)throws Exception {
  init();ExtractorHttp.begin();try{String url=DownloadLinks.canonical(link);StreamInfo info=StreamInfo.getInfo(ServiceList.YouTube,url);
  if(info.getStreamType()!=StreamType.VIDEO_STREAM||info.getDuration()<=0)throw new Exception("Esta versão aceita vídeos gravados, sem transmissão ao vivo.");
  List<Option> options=new ArrayList<>();AudioStream audio=null;
  for(AudioStream a:info.getAudioStreams())if(usable(a)&&a.getFormat()==MediaFormat.M4A&&(audio==null||a.getAverageBitrate()>audio.getAverageBitrate()))audio=a;
  if(audio!=null){options.add(new Option("Áudio MP3 • 192 kbps • converter",audio.getContent(),null,"mp3","audio/mpeg"));}
  if(audio!=null)options.add(new Option("Áudio M4A • "+audio.getAverageBitrate()+" kbps",audio.getContent(),null,"m4a","audio/mp4"));
  Set<String> resolutions=new HashSet<>();
  for(VideoStream v:info.getVideoStreams())if(usable(v)&&v.getFormat()==MediaFormat.MPEG_4&&!v.isVideoOnly()&&resolutions.add(v.getResolution()))options.add(new Option("Vídeo MP4 • "+v.getResolution()+" • com som",v.getContent(),null,"mp4","video/mp4"));
  if(audio!=null)for(VideoStream v:info.getVideoOnlyStreams())if(usable(v)&&v.getFormat()==MediaFormat.MPEG_4&&v.getCodec()!=null&&v.getCodec().startsWith("avc")&&resolutions.add(v.getResolution()))options.add(new Option("Vídeo MP4 • "+v.getResolution()+" • juntar áudio",v.getContent(),audio.getContent(),"mp4","video/mp4"));
  if(options.isEmpty())throw new Exception("Nenhum formato M4A/MP4 compatível disponível para este vídeo.");
  ExtractorHttp.remaining();return new Result(info.getName(),options);
  }finally{ExtractorHttp.end();}
 }
 static final int MAX_PLAYLIST=100,MAX_MIX=50;
 static final class Entry {final String title,url;Entry(String t,String u){title=t.length()>160?t.substring(0,160):t;url=DownloadLinks.canonical(u);}}
 static final class Playlist {final String title;final List<Entry> items;final boolean limited;Playlist(String t,List<Entry> i,boolean l){title=t;items=i;limited=l;}}
 static Playlist playlist(String link)throws Exception{
  init();ExtractorHttp.begin();try{String url=DownloadLinks.playlist(link);PlaylistInfo info=PlaylistInfo.getInfo(ServiceList.YouTube,url);boolean mix=info.getPlaylistType()!=null&&info.getPlaylistType()!=PlaylistInfo.PlaylistType.NORMAL;int cap=mix?MAX_MIX:MAX_PLAYLIST;List<Entry> items=new ArrayList<>();Set<String> seen=new HashSet<>();List<StreamInfoItem> page=info.getRelatedItems();Page next=info.getNextPage();int pages=0;
   while(true){for(StreamInfoItem item:page){if(items.size()>=cap)break;if(item.getStreamType()!=StreamType.VIDEO_STREAM)continue;try{Entry e=new Entry(item.getName(),item.getUrl());if(seen.add(e.url))items.add(e);}catch(IllegalArgumentException ignored){}}
    if(items.size()>=cap||!Page.isValid(next)||++pages>=10)break;ExtractorHttp.remaining();InfoItemsPage<StreamInfoItem> more=PlaylistInfo.getMoreItems(ServiceList.YouTube,url,next);page=more.getItems();next=more.getNextPage();if(page.isEmpty())break;
   }
   if(items.isEmpty())throw new Exception("Playlist privada, vazia ou sem vídeos compatíveis.");return new Playlist(info.getName(),items,Page.isValid(next)||info.getStreamCount()>items.size());
  }finally{ExtractorHttp.end();}
 }
 static Option choose(Result result,String format)throws Exception{
  if("mp3".equals(format)||"m4a".equals(format)){for(Option o:result.options)if(o.extension.equals(format))return o;}
  if("mp4".equals(format)){Option best=null;int bestHeight=0;for(Option o:result.options)if(o.extension.equals("mp4")){java.util.regex.Matcher m=java.util.regex.Pattern.compile("(\\d+)p").matcher(o.title);int h=m.find()?Integer.parseInt(m.group(1)):0;if(h>0&&h<=720&&h>bestHeight){best=o;bestHeight=h;}}if(best!=null)return best;}
  throw new Exception("Formato escolhido indisponível para este vídeo.");
 }
}
