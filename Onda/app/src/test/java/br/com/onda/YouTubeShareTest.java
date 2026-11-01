package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
public class YouTubeShareTest {
 @Test public void onlyExactInternalVideoActionsCanReachCanonicalLinks(){assertEquals("https://www.youtube.com/watch?v=aqz-KE-bpKQ",YouTubeShare.action("onda-share://youtube/aqz-KE-bpKQ"));for(String input:new String[]{"https://youtube/aqz-KE-bpKQ","onda-share://youtube.evil.org/aqz-KE-bpKQ","onda-share://user@youtube/aqz-KE-bpKQ","onda-share://youtube:443/aqz-KE-bpKQ","onda-share://youtube/aqz-KE-bpKQ?target=secret","onda-share://youtube/aqz-KE-bpKQ#x","onda-share://youtube/a","onda-share://youtube/aqz-KE-bpKQ/extra"})assertEquals(input,"",YouTubeShare.action(input));}
 @Test public void currentVideoTakesPrecedenceOverPlaylistContext(){assertEquals("https://www.youtube.com/watch?v=aqz-KE-bpKQ",YouTubeShare.page("https://m.youtube.com/watch?v=aqz-KE-bpKQ&list=PL1234567890"));assertEquals("https://www.youtube.com/playlist?list=PL1234567890",YouTubeShare.page("https://m.youtube.com/playlist?list=PL1234567890"));for(String input:new String[]{"https://m.youtube.com/results?search_query=Onda","https://youtube.com.evil.org/watch?v=aqz-KE-bpKQ","file:///private/video","javascript:alert(1)"})assertEquals("",YouTubeShare.page(input));}
}
