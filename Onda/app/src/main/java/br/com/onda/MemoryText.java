package br.com.onda;
import java.util.*;import java.util.regex.*;
/** Deterministic text search and timestamp parsing, never an invented semantic answer. */
final class MemoryText {
 static final class Cue {final long start,end;final int page;final String text;Cue(long a,long b,int p,String t){start=a;end=b;page=p;text=t;}}
 private static final Set<String> STOP=new HashSet<>(Arrays.asList("a","o","as","os","de","da","do","das","dos","em","no","na","nos","nas","e","um","uma","que","sobre","onde","ache","encontre","busque","procure","parte","trecho","video","audio","pdf","fala","falar","mostre","me","por","favor","com"));
 static String query(String raw){StringBuilder out=new StringBuilder();int count=0;for(String word:SearchText.normalize(raw).split(" ")){if(word.length()<2||STOP.contains(word))continue;if(count++>=12)break;if(out.length()>0)out.append(" ");out.append(word).append('*');}return out.toString();}
 static List<Cue> subtitles(String raw){List<Cue> result=new ArrayList<>();String text=raw.replace("\r","").replace("\uFEFF","");Pattern time=Pattern.compile("(?m)^(?:(\\d{1,3}):)?(\\d{2}):(\\d{2})[,.](\\d{3})[ \\t]+-->[ \\t]+(?:(\\d{1,3}):)?(\\d{2}):(\\d{2})[,.](\\d{3})[^\\n]*\\n");Matcher m=time.matcher(text);long start=-1,end=0;int at=0;while(m.find()){if(start>=0)add(result,start,end,body(text.substring(at,m.start())));start=millis(m,1);end=millis(m,5);at=m.end();}if(start>=0)add(result,start,end,body(text.substring(at)));return result;}
 private static String body(String text){return text.replaceAll("\\n\\s*\\n\\s*\\d+\\s*$","").replaceAll("<[^>]*>","").replaceAll("\\s+"," ").trim();}
 private static long millis(Matcher m,int g){int min=Integer.parseInt(m.group(g+1)),sec=Integer.parseInt(m.group(g+2));if(min>59||sec>59)return -1;return (m.group(g)==null?0:Long.parseLong(m.group(g))*3600000L)+min*60000L+sec*1000L+Integer.parseInt(m.group(g+3));}
 private static void add(List<Cue> result,long a,long b,String text){if(a>=0&&b>a&&!text.isEmpty())for(String part:chunks(text))result.add(new Cue(a,b,-1,part));}
 static List<String> chunks(String text){List<String> out=new ArrayList<>();String clean=text.replaceAll("\\s+"," ").trim();for(int from=0;from<clean.length();){int to=Math.min(clean.length(),from+1200);if(to<clean.length()){int space=clean.lastIndexOf(' ',to);if(space>from+600)to=space;}out.add(clean.substring(from,to).trim());from=to;while(from<clean.length()&&clean.charAt(from)==' ')from++;}return out;}
}
