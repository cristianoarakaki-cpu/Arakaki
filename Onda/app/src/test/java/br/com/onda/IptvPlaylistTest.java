package br.com.onda;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import org.junit.Test;
import static org.junit.Assert.*;
public class IptvPlaylistTest {
 private List<IptvPlaylist.Channel> read(String text,String base)throws Exception{return IptvPlaylist.read(new ByteArrayInputStream(text.getBytes(StandardCharsets.UTF_8)),base);}
 @Test public void readsUtf8NamesGroupsAndQuotedCommas()throws Exception{List<IptvPlaylist.Channel> items=read("\uFEFF#EXTM3U\n#EXTINF:-1 tvg-name=\"Nome alternativo\" group-title=\"Notícias, Brasil\",Canal de notícias\nhttps://example.org/live.m3u8?token=123\n","");assertEquals(1,items.size());assertEquals("Canal de notícias",items.get(0).name);assertEquals("Notícias, Brasil",items.get(0).group);assertEquals("https://example.org/live.m3u8?token=123",items.get(0).url);}
 @Test public void relativeStreamsUseFinalPlaylistUrlAndDuplicateEntriesCollapse()throws Exception{List<IptvPlaylist.Channel> items=read("#EXTM3U\n#EXTINF:-1,Um\n../live/a.m3u8\n#EXTINF:-1,Repetido\nhttps://example.org/live/a.m3u8\n","https://example.org/lists/main.m3u");assertEquals(1,items.size());assertEquals("https://example.org/live/a.m3u8",items.get(0).url);}
 @Test public void hlsMediaPlaylistBecomesOneStreamRatherThanItsSegments()throws Exception{List<IptvPlaylist.Channel> items=read("#EXTM3U\n#EXT-X-TARGETDURATION:10\n#EXTINF:10,\npart.ts\n","https://example.org/live/index.m3u8");assertEquals(1,items.size());assertEquals("https://example.org/live/index.m3u8",items.get(0).url);}
 @Test public void unsafeSchemesAndProviderExecutableOptionsAreNotUsed()throws Exception{List<IptvPlaylist.Channel> items=read("#EXTM3U\n#EXTVLCOPT:http-user-agent=evil\n#EXTINF:-1,Bad\nfile:///private\n#EXTINF:-1,OK\nHTTP://192.168.1.2:8080/channel\n","");assertEquals(1,items.size());assertEquals("OK",items.get(0).name);assertEquals("http://192.168.1.2:8080/channel",items.get(0).url);assertEquals("",IptvPlaylist.stream("javascript:alert(1)",""));assertEquals("",IptvPlaylist.stream("https://user:pass@example.org/live",""));}
 @Test public void extgrpAndTvgNamesAreAccepted()throws Exception{List<IptvPlaylist.Channel> items=read("#EXTM3U\n#EXTINF:-1 tvg-name=\"Canal A\",\n#EXTGRP:Documentários\nhttps://example.org/a\n","");assertEquals("Canal A",items.get(0).name);assertEquals("Documentários",items.get(0).group);}
 @Test public void invalidListsAndOverlongLinesFailClearly()throws Exception{for(String raw:new String[]{"<html>login</html>","#EXTM3U\nfile:///private\n","#EXTM3U\n"+"a".repeat(65537)})try{read(raw,"");fail();}catch(IOException expected){assertNotNull(expected.getMessage());}}
}
