package br.com.onda;
import java.util.*;
/** Foreground metadata search. Pre-normalized text; no provider reads while typing. */
final class UnifiedSearch {
 static final int LIMIT=200;
 static final String[] FILTERS={"Tudo","Áudios","Vídeos","PDFs","Coleções","Anotações","Favoritas (áudio)","Continuar"};
 static final class Entry {
  final String id,type,uri,title,detail,text,normalizedTitle;String collection="",note="",targetType="";long position,seen;boolean favorite;
  Entry(String id,String type,String uri,String title,String detail){this.id=id;this.type=type;this.uri=uri;this.title=title;this.detail=detail;this.text=SearchText.normalize(title+" "+detail);this.normalizedTitle=SearchText.normalize(title);}
  String key(){return type+"|"+canonical(type.equals("note")||uri.isEmpty()?id:uri);}
 }
 static String canonical(String uri){return uri.replace("content://media/external_primary/","content://media/external/");}
 static List<Entry> merge(List<Entry> entries){LinkedHashMap<String,Entry> map=new LinkedHashMap<>();for(Entry e:entries){Entry old=map.get(e.key());if(old==null)map.put(e.key(),e);else{old.favorite|=e.favorite;if(e.seen>old.seen){old.seen=e.seen;old.position=e.position;}}}return new ArrayList<>(map.values());}
 static boolean accepts(Entry e,int filter){switch(filter){case 1:return e.type.equals("audio");case 2:return e.type.equals("video");case 3:return e.type.equals("pdf");case 4:return e.type.equals("collection");case 5:return e.type.equals("note");case 6:return e.type.equals("audio")&&e.favorite;case 7:return e.seen>0&&!e.type.equals("note")&&!e.type.equals("collection");default:return true;}}
 static int score(Entry e,String query){return normalizedScore(e,SearchText.normalize(query));}
 static int normalizedScore(Entry e,String q){if(q.isEmpty())return 0;for(String word:q.split(" "))if(!e.text.contains(word))return -1;String title=e.normalizedTitle;return title.equals(q)?100:title.startsWith(q)?60:title.contains(q)?40:10;}
 static List<Entry> find(List<Entry> index,String query,int filter){String q=SearchText.normalize(query);List<Entry> found=new ArrayList<>();Map<Entry,Integer> scores=new IdentityHashMap<>();for(Entry e:index){if(Thread.currentThread().isInterrupted())return Collections.emptyList();if(accepts(e,filter)){int score=normalizedScore(e,q);if(score>=0){found.add(e);scores.put(e,score);}}}found.sort((a,b)->{int relevance=Integer.compare(scores.get(b),scores.get(a));return relevance!=0?relevance:Long.compare(b.seen,a.seen);});return found;}
}
