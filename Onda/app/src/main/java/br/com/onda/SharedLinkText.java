package br.com.onda;
import java.net.URI;import java.util.*;import java.util.regex.*;
/** Fallback for damaged clipboard text. Never rewrites a link the existing resolver accepts. */
final class SharedLinkText {
 private static final Pattern URL=Pattern.compile("https://[^\\s\\p{Zs}<>\"'“”‘’«»]+",Pattern.CASE_INSENSITIVE);
 private static boolean invisible(int c){return c==0xFEFF||c==0x200B||c==0x2060||c==0x200E||c==0x200F||c>=0x202A&&c<=0x202E||c>=0x2066&&c<=0x2069;}
 private static String edges(String s){int first=0,last=s.length();while(first<last&&(Character.isWhitespace(s.charAt(first))||Character.isSpaceChar(s.charAt(first))||invisible(s.charAt(first))))first++;while(last>first&&(Character.isWhitespace(s.charAt(last-1))||Character.isSpaceChar(s.charAt(last-1))||invisible(s.charAt(last-1))))last--;return s.substring(first,last);}
 static String extract(String text){if(text==null||text.length()>4096)throw new IllegalArgumentException();Matcher m=URL.matcher(edges(text));if(!m.find())throw new IllegalArgumentException();String value=edges(m.group());if(m.find())throw new IllegalArgumentException();return "https://"+value.substring(8);}
 static String platformRepair(String value){StringBuilder out=new StringBuilder();for(int i=0;i<value.length();i++)if(!invisible(value.charAt(i)))out.append(value.charAt(i));String repaired=out.toString();while(!repaired.isEmpty()&&").,;!]}”’»。".indexOf(repaired.charAt(repaired.length()-1))>=0)repaired=repaired.substring(0,repaired.length()-1);try{URI u=new URI(repaired);String h=u.getHost();if(!"https".equalsIgnoreCase(u.getScheme())||h==null||u.getUserInfo()!=null||u.getPort()!=-1)return value;h=h.toLowerCase(Locale.ROOT);if(!Arrays.asList("tiktok.com","www.tiktok.com","m.tiktok.com","vt.tiktok.com","vm.tiktok.com","youtube.com","www.youtube.com","m.youtube.com","music.youtube.com","youtu.be","youtube-nocookie.com","www.youtube-nocookie.com").contains(h))return value;return repaired;}catch(Exception invalid){return value;}}
}
