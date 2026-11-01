package br.com.onda;
import java.net.URI;
import java.util.Locale;
/** Only the selected public service can navigate inside its browser. */
final class PlatformLinks {
 static final String[] IDS={"tiktok","instagram","facebook"},NAMES={"TikTok","Instagram","Facebook"};
 static int index(String id){for(int i=0;i<IDS.length;i++)if(IDS[i].equals(id))return i;return 0;}
 static String home(String id){switch(id==null?"tiktok":id){case "instagram":return "https://www.instagram.com/";case "facebook":return "https://m.facebook.com/";default:return "https://www.tiktok.com/";}}
 static boolean allowed(String id,String raw){try{if(raw==null||raw.length()>4096)return false;URI u=new URI(raw);if(!MediaLinks.publicShape(u))return false;String h=u.getHost().toLowerCase(Locale.ROOT);switch(id==null?"tiktok":id){case "instagram":return h.equals("instagram.com")||h.endsWith(".instagram.com");case "facebook":return h.equals("facebook.com")||h.endsWith(".facebook.com")||h.equals("fb.watch");default:return MediaLinks.tiktokHost(h);}}catch(Exception e){return false;}}
 static String post(String id,String raw){try{if(!allowed(id,raw))return "";URI u=new URI(raw);String path=u.getPath();if(id.equals("tiktok"))return MediaLinks.tiktok(raw);if(id.equals("instagram")){if(!path.matches("/(?:reel|reels|p|tv)/[A-Za-z0-9_-]{5,128}/?"))return "";return "https://www.instagram.com"+path;}if(u.getHost().equalsIgnoreCase("fb.watch")&&path.matches("/[A-Za-z0-9_-]{5,128}/?"))return "https://fb.watch"+path;if(path.matches("/reel/[0-9]{5,30}/?"))return "https://www.facebook.com"+path;if(path.matches("/[^/]{1,128}/videos/[0-9]{5,30}/?"))return "https://www.facebook.com"+path;if(path.equals("/watch")||path.equals("/watch/")||path.equals("/video.php")){String video=null;if(u.getRawQuery()!=null)for(String pair:u.getRawQuery().split("&")){String[] bits=pair.split("=",2);if(bits[0].equals("v")){if(video!=null||bits.length!=2)return "";video=bits[1];}}if(video!=null&&video.matches("[0-9]{5,30}"))return "https://www.facebook.com/watch/?v="+video;}return "";}catch(Exception e){return "";}}
}
