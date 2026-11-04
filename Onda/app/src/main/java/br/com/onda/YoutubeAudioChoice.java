package br.com.onda;
import java.util.*;
import org.schabi.newpipe.extractor.*;
import org.schabi.newpipe.extractor.stream.*;
/** Language is chosen before container or bitrate, so a higher-quality foreign dub cannot win. */
final class YoutubeAudioChoice {
 static Locale locale(AudioStream stream){Locale locale=stream.getAudioLocale();if(locale!=null&&!locale.getLanguage().isEmpty())return locale;String id=stream.getAudioTrackId();if(id==null)return null;int dot=id.indexOf('.');String tag=(dot<0?id:id.substring(0,dot)).replace('_','-');Locale parsed=Locale.forLanguageTag(tag);return parsed.getLanguage().isEmpty()?null:parsed;}
 private static boolean original(AudioStream stream){return stream.getAudioTrackType()==AudioTrackType.ORIGINAL;}
 private static int rank(AudioStream stream){int value=AudioLanguage.rank(locale(stream),original(stream));if(value==4&&stream.getAudioTrackType()!=null)return stream.getAudioTrackType()==AudioTrackType.DESCRIPTIVE?6:5;return value;}
 private static int type(AudioStream stream){AudioTrackType type=stream.getAudioTrackType();return type==AudioTrackType.ORIGINAL?0:type==AudioTrackType.DUBBED?1:type==AudioTrackType.SECONDARY?2:type==AudioTrackType.DESCRIPTIVE?4:3;}
 private static int format(AudioStream stream){return stream.getFormat()==MediaFormat.M4A?0:stream.getFormat()==MediaFormat.WEBMA||stream.getFormat()==MediaFormat.WEBMA_OPUS?1:2;}
 static AudioStream select(List<AudioStream> streams){Comparator<AudioStream> order=Comparator.comparingInt(YoutubeAudioChoice::rank).thenComparingInt(YoutubeAudioChoice::type).thenComparingInt(YoutubeAudioChoice::format).thenComparing(Comparator.comparingInt(AudioStream::getAverageBitrate).reversed());AudioStream best=null;for(AudioStream stream:streams)if(stream.isUrl()&&stream.getContent().startsWith("https://")&&stream.getDeliveryMethod()==DeliveryMethod.PROGRESSIVE_HTTP&&stream.getFormat()!=null&&(best==null||order.compare(stream,best)<0))best=stream;return best;}
 static String notice(AudioStream stream){return AudioLanguage.notice(locale(stream),original(stream));}
}
