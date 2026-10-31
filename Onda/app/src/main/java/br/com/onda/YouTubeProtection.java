package br.com.onda;

import java.net.URI;
import java.util.Locale;

/** Small local rules for dedicated advertising hosts. Never filters the video CDN or main document. */
final class YouTubeProtection {
 static final String PREF="youtube_browser", KEY="block_ads";
 private static final String[] HOSTS={"doubleclick.net","googlesyndication.com","googleadservices.com","googletagservices.com","adservice.google.com","adservice.google.com.br","adservice.google.pt","adservice.google.es","adservice.google.de","adservice.google.com.ar","adservice.google.com.mx","2mdn.net","admob.com","imasdk.googleapis.com","ads.youtube.com"};
 static boolean blocks(String url,boolean mainFrame){
  if(mainFrame||url==null||url.length()>16384)return false;
  try{URI uri=new URI(url);String scheme=uri.getScheme();if(!"https".equalsIgnoreCase(scheme)&&!"http".equalsIgnoreCase(scheme))return false;String host=uri.getHost();if(host==null||uri.getUserInfo()!=null)return false;host=host.toLowerCase(Locale.ROOT);if(host.endsWith("."))host=host.substring(0,host.length()-1);for(String rule:HOSTS)if(host.equals(rule)||host.endsWith("."+rule))return true;if(host.equals("youtube.com")||host.equals("www.youtube.com")||host.equals("m.youtube.com")||host.equals("music.youtube.com")){String path=uri.getPath();if(path!=null&&(path.equals("/api/stats/ads")||path.startsWith("/api/stats/ads/")||path.startsWith("/pagead/")))return true;}}catch(Exception ignored){}return false;
 }
 static String cosmeticScript(){return "(function(){if(document.getElementById('onda-ad-protection'))return;var s=document.createElement('style');s.id='onda-ad-protection';s.textContent='ytm-promoted-sparkles-web-renderer,ytm-promoted-sparkles-text-search-renderer,ytm-promoted-video-renderer,ytm-display-ad-renderer,ytm-ad-slot-renderer,ytm-companion-ad-renderer,ytd-ad-slot-renderer,ytd-display-ad-renderer,ytd-promoted-sparkles-web-renderer,ytd-promoted-sparkles-text-search-renderer,ytd-promoted-video-renderer,ytd-in-feed-ad-layout-renderer,ytd-companion-slot-renderer,#player-ads,#masthead-ad{display:none!important}';(document.head||document.documentElement).appendChild(s);})();";}
}
