package br.com.onda;

import java.net.URI;
import java.util.regex.Pattern;

/** Accept a single public YouTube video, never an arbitrary URL or credentials. */
final class DownloadLinks {
 private static final Pattern ID=Pattern.compile("[A-Za-z0-9_-]{11}");
 static String canonical(String input){
  try{
   if(input==null||input.length()>4096)throw new IllegalArgumentException();
   URI u=new URI(input.trim());String host=u.getHost();
   if(!"https".equalsIgnoreCase(u.getScheme())||host==null||u.getUserInfo()!=null||u.getPort()!=-1)throw new IllegalArgumentException();
   String id=null,path=u.getPath();
   if(host.equalsIgnoreCase("youtu.be")){id=path.substring(1);}
   else if(host.equalsIgnoreCase("youtube.com")||host.equalsIgnoreCase("www.youtube.com")||host.equalsIgnoreCase("m.youtube.com")||host.equalsIgnoreCase("music.youtube.com")){
    if("/watch".equals(path)&&u.getRawQuery()!=null){for(String q:u.getRawQuery().split("&"))if(q.startsWith("v=")){if(id!=null)throw new IllegalArgumentException();id=q.substring(2);}}
    else if(path.startsWith("/shorts/"))id=path.substring(8);
    else if(path.startsWith("/live/"))id=path.substring(6);
   }
   if(id==null||!ID.matcher(id).matches())throw new IllegalArgumentException();
   return "https://www.youtube.com/watch?v="+id;
  }catch(Exception e){throw new IllegalArgumentException("Cole um link HTTPS de um vídeo do YouTube (watch, youtu.be ou Shorts).");}
 }
 static String playlist(String input){
  try{if(input==null||input.length()>4096)throw new IllegalArgumentException();URI u=new URI(input.trim());String h=u.getHost();if(!"https".equalsIgnoreCase(u.getScheme())||h==null||u.getUserInfo()!=null||u.getPort()!=-1||!(h.equalsIgnoreCase("youtube.com")||h.equalsIgnoreCase("www.youtube.com")||h.equalsIgnoreCase("m.youtube.com")||h.equalsIgnoreCase("music.youtube.com"))||!("/playlist".equals(u.getPath())||"/watch".equals(u.getPath())))throw new IllegalArgumentException();String id=null;if(u.getRawQuery()!=null)for(String q:u.getRawQuery().split("&"))if(q.startsWith("list=")){if(id!=null)throw new IllegalArgumentException();id=q.substring(5);}if(id==null||!id.matches("[A-Za-z0-9_-]{10,100}"))throw new IllegalArgumentException();return "https://www.youtube.com/playlist?list="+id;
  }catch(Exception e){throw new IllegalArgumentException("Cole um link HTTPS válido de vídeo ou playlist do YouTube.");}
 }
 static String resolve(String input){try{return playlist(input);}catch(IllegalArgumentException e){return canonical(input);}}
 static boolean isPlaylist(String url){return url.startsWith("https://www.youtube.com/playlist?list=");}
 static String filename(String title){String s=title==null?"Onda":title.replaceAll("[\\p{Cntrl}\\\\/:*?\"<>|]"," ").trim();return s.isEmpty()?"Onda":s.substring(0,Math.min(80,s.length()));}
}
