package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
public class DownloadLinksTest {
 @Test public void forms(){String expected="https://www.youtube.com/watch?v=aqz-KE-bpKQ";for(String url:new String[]{expected+"&list=abc","https://youtu.be/aqz-KE-bpKQ?si=x","https://m.youtube.com/shorts/aqz-KE-bpKQ","https://music.youtube.com/watch?v=aqz-KE-bpKQ"})assertEquals(expected,DownloadLinks.canonical(url));}
 @Test public void rejects(){for(String url:new String[]{"http://youtube.com/watch?v=aqz-KE-bpKQ","https://youtube.com.evil.test/watch?v=aqz-KE-bpKQ","https://youtube.com@evil.test/watch?v=aqz-KE-bpKQ","file:///x","https://youtube.com/playlist?list=a","https://youtu.be/a","https://youtube.com/watch?v=aqz-KE-bpKQ&v=aqz-KE-bpKQ","https://youtube.com:443/watch?v=aqz-KE-bpKQ"}){try{DownloadLinks.canonical(url);fail(url);}catch(IllegalArgumentException expected){}}}
 @Test public void safeName(){assertEquals("Onda",DownloadLinks.filename(""));assertFalse(DownloadLinks.filename("../a:b\\c\n").contains("/"));assertTrue(DownloadLinks.filename("x".repeat(200)).length()<=80);}
}
