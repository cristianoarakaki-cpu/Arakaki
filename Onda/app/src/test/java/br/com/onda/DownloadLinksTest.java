package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
public class DownloadLinksTest {
 @Test public void forms(){String expected="https://www.youtube.com/watch?v=aqz-KE-bpKQ";for(String url:new String[]{expected+"&list=abc","https://youtu.be/aqz-KE-bpKQ?si=x","https://m.youtube.com/shorts/aqz-KE-bpKQ","https://music.youtube.com/watch?v=aqz-KE-bpKQ"})assertEquals(expected,DownloadLinks.canonical(url));}
 @Test public void rejects(){for(String url:new String[]{"http://youtube.com/watch?v=aqz-KE-bpKQ","https://youtube.com.evil.test/watch?v=aqz-KE-bpKQ","https://youtube.com@evil.test/watch?v=aqz-KE-bpKQ","file:///x","https://youtube.com/playlist?list=a","https://youtu.be/a","https://youtube.com/watch?v=aqz-KE-bpKQ&v=aqz-KE-bpKQ","https://youtube.com:443/watch?v=aqz-KE-bpKQ"}){try{DownloadLinks.canonical(url);fail(url);}catch(IllegalArgumentException expected){}}}
 @Test public void safeName(){assertEquals("Onda",DownloadLinks.filename(""));assertFalse(DownloadLinks.filename("../a:b\\c\n").contains("/"));assertTrue(DownloadLinks.filename("x".repeat(200)).length()<=80);}

 @Test public void officialEmbeddedPlayersKeepExactVideo(){for(String host:new String[]{"www.youtube.com","www.youtube-nocookie.com","youtube-nocookie.com"})assertEquals("https://www.youtube.com/watch?v=aqz-KE-bpKQ",DownloadLinks.canonical("https://"+host+"/embed/aqz-KE-bpKQ?rel=0"));for(String url:new String[]{"https://www.youtube-nocookie.com/watch?v=aqz-KE-bpKQ","https://www.youtube.com/embed/videoseries?list=PL1234567890","https://www.youtube.com/embed/aqz-KE-bpKQ/other","https://youtube-nocookie.com.evil.org/embed/aqz-KE-bpKQ"})try{DownloadLinks.canonical(url);fail(url);}catch(IllegalArgumentException expected){}}
}
