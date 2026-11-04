package br.com.onda;
import java.util.*;
import org.schabi.newpipe.extractor.*;
import org.schabi.newpipe.extractor.stream.*;
import org.junit.Test;
import static org.junit.Assert.*;
public class YoutubeAudioChoiceTest {
 private AudioStream stream(String tag,AudioTrackType type,MediaFormat format,int bitrate){AudioStream.Builder b=new AudioStream.Builder().setId(tag+bitrate+format).setContent("https://r1.googlevideo.com/audio/"+tag,true).setMediaFormat(format).setAverageBitrate(bitrate);if(tag!=null)b.setAudioLocale(Locale.forLanguageTag(tag));if(type!=null)b.setAudioTrackType(type);return b.build();}
 @Test public void brazilianDubWinsEvenAgainstHigherBitrateEnglishOriginal(){AudioStream en=stream("en-US",AudioTrackType.ORIGINAL,MediaFormat.M4A,256),br=stream("pt-BR",AudioTrackType.DUBBED,MediaFormat.WEBMA,64);assertSame(br,YoutubeAudioChoice.select(Arrays.asList(en,br)));}
 @Test public void exactBrazilIsPreferredToOtherPortugueseAndOriginalBreaksSameLanguageTie(){AudioStream portugal=stream("pt-PT",AudioTrackType.ORIGINAL,MediaFormat.M4A,256),generic=stream("pt",AudioTrackType.ORIGINAL,MediaFormat.M4A,128),br=stream("pt-BR",AudioTrackType.DUBBED,MediaFormat.M4A,64),original=stream("pt-BR",AudioTrackType.ORIGINAL,MediaFormat.M4A,64);assertSame(original,YoutubeAudioChoice.select(Arrays.asList(portugal,generic,br,original)));}
 @Test public void originalFallbackAndContainerQualityAreDeterministic(){AudioStream original=stream("en-US",AudioTrackType.ORIGINAL,MediaFormat.M4A,64),dub=stream("de-DE",AudioTrackType.DUBBED,MediaFormat.M4A,256),better=stream("en-US",AudioTrackType.ORIGINAL,MediaFormat.M4A,128);assertSame(better,YoutubeAudioChoice.select(Arrays.asList(dub,original,better)));assertTrue(YoutubeAudioChoice.notice(better).contains("português indisponível"));}
 @Test public void unusableBrazilianStreamCannotReplacePlayableOriginal(){AudioStream bad=new AudioStream.Builder().setId("bad").setContent("http://example.org/pt.mp4",true).setMediaFormat(MediaFormat.M4A).setAudioLocale(Locale.forLanguageTag("pt-BR")).build(),good=stream("en",AudioTrackType.ORIGINAL,MediaFormat.M4A,128);assertSame(good,YoutubeAudioChoice.select(Arrays.asList(bad,good)));assertNull(YoutubeAudioChoice.select(Collections.singletonList(bad)));}
 @Test public void trackIdCanSupplyLanguageWhenLocaleIsMissing(){AudioStream br=new AudioStream.Builder().setId("pt-id").setContent("https://r1.googlevideo.com/pt",true).setMediaFormat(MediaFormat.M4A).setAudioTrackId("pt-BR.4").build();assertEquals("BR",YoutubeAudioChoice.locale(br).getCountry());assertEquals("Português (Brasil)",YoutubeAudioChoice.notice(br));}
}
