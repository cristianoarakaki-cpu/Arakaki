package br.com.onda;

import org.schabi.newpipe.extractor.*;
import org.schabi.newpipe.extractor.stream.*;
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
  if(audio!=null)options.add(new Option("Áudio M4A • "+audio.getAverageBitrate()+" kbps",audio.getContent(),null,"m4a","audio/mp4"));
  Set<String> resolutions=new HashSet<>();
  for(VideoStream v:info.getVideoStreams())if(usable(v)&&v.getFormat()==MediaFormat.MPEG_4&&!v.isVideoOnly()&&resolutions.add(v.getResolution()))options.add(new Option("Vídeo MP4 • "+v.getResolution()+" • com som",v.getContent(),null,"mp4","video/mp4"));
  if(audio!=null)for(VideoStream v:info.getVideoOnlyStreams())if(usable(v)&&v.getFormat()==MediaFormat.MPEG_4&&v.getCodec()!=null&&v.getCodec().startsWith("avc")&&resolutions.add(v.getResolution()))options.add(new Option("Vídeo MP4 • "+v.getResolution()+" • juntar áudio",v.getContent(),audio.getContent(),"mp4","video/mp4"));
  if(options.isEmpty())throw new Exception("Nenhum formato M4A/MP4 compatível disponível para este vídeo.");
  ExtractorHttp.remaining();return new Result(info.getName(),options);
  }finally{ExtractorHttp.end();}
 }
}
