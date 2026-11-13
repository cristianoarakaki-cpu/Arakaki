package br.com.onda;
import java.util.*;
/** Translates verses once, prioritizes the current one, and preserves original timestamps. */
final class LyricTranslation {
 interface Result {void success(String translated);void failure(Exception error);}
 interface Engine {void translate(String text,Result callback);}
 interface Listener {void row(int index,String translated);void complete();void failure(Exception error);}
 private final List<String> rows;private final List<String> order=new ArrayList<>();private final Map<String,List<Integer>> indices=new LinkedHashMap<>();private final Engine engine;private final Listener listener;private boolean cancelled;private int cursor;
 LyricTranslation(List<String> rows,int first,Engine engine,Listener listener){this.rows=new ArrayList<>(rows);this.engine=engine;this.listener=listener;for(int i=0;i<rows.size();i++)if(!rows.get(i).trim().isEmpty())indices.computeIfAbsent(rows.get(i),k->new ArrayList<>()).add(i);if(first>=0&&first<rows.size()&&indices.containsKey(rows.get(first)))order.add(rows.get(first));for(String text:indices.keySet())if(!order.contains(text))order.add(text);}
 void start(){next();}
 void cancel(){cancelled=true;}
 private void next(){if(cancelled)return;if(cursor>=order.size()){listener.complete();return;}String text=order.get(cursor++);engine.translate(text,new Result(){public void success(String translated){if(cancelled)return;for(int index:indices.get(text))listener.row(index,translated);next();}public void failure(Exception error){if(cancelled)return;cancelled=true;listener.failure(error);}});}
}
