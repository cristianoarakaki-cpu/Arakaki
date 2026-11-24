package br.com.onda;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Locale;

/** Immutable edits; neighboring tracks share a single boundary, with no gaps or overlap. */
final class ChapterEdits {
    static long parse(String value) {
        String s=value.trim().replace(',', '.');
        if(s.length()>24||!s.matches("[0-9]+(?::[0-9]{1,2}){0,2}(?:\\.[0-9]{1,3})?"))throw bad();
        String[] fraction=s.split("\\.",-1), parts=fraction[0].split(":");
        try {
            long seconds=0;
            for(int i=0;i<parts.length;i++){
                long n=Long.parseLong(parts[i]);
                if(i>0&&n>59)throw bad();
                seconds=Math.addExact(Math.multiplyExact(seconds,60),n);
            }
            long millis=fraction.length==1?0:Long.parseLong((fraction[1]+"000").substring(0,3));
            return Math.addExact(Math.multiplyExact(seconds,1000),millis);
        }catch(ArithmeticException|NumberFormatException error){throw bad();}
    }
    static String format(long ms){return String.format(Locale.ROOT,"%d:%02d.%03d",ms/60000,ms/1000%60,ms%1000);}
    static AudioChapterStore.Data full(long duration){
        if(duration<=0)throw bad();
        return new AudioChapterStore.Data(duration,Collections.singletonList(new AudioChapterStore.Chapter(0,"")));
    }
    static AudioChapterStore.Data add(AudioChapterStore.Data data,long start,String title){
        if(start<=0||start>=data.duration)throw bad();
        ArrayList<AudioChapterStore.Chapter> copy=new ArrayList<>(data.chapters);
        int index=0;while(index<copy.size()&&copy.get(index).start<start)index++;
        if(index<copy.size()&&copy.get(index).start==start)throw bad();
        copy.add(index,new AudioChapterStore.Chapter(start,name(title)));
        return new AudioChapterStore.Data(data.duration,copy);
    }
    static AudioChapterStore.Data update(AudioChapterStore.Data data,int index,String title,long start,long end){
        if(index<0||index>=data.chapters.size())throw bad();
        int last=data.chapters.size()-1;
        if(start<0||start>=end||end>data.duration||index==0&&start!=0||index==last&&end!=data.duration
                ||index>0&&start<=data.chapters.get(index-1).start
                ||index<last&&end>=(index+2<=last?data.chapters.get(index+2).start:data.duration))throw bad();
        ArrayList<AudioChapterStore.Chapter> copy=new ArrayList<>(data.chapters);
        copy.set(index,new AudioChapterStore.Chapter(start,name(title)));
        if(index<last)copy.set(index+1,new AudioChapterStore.Chapter(end,copy.get(index+1).title));
        return new AudioChapterStore.Data(data.duration,copy);
    }
    static AudioChapterStore.Data remove(AudioChapterStore.Data data,int index){
        if(index<=0||index>=data.chapters.size())throw bad();
        ArrayList<AudioChapterStore.Chapter> copy=new ArrayList<>(data.chapters);copy.remove(index);
        return new AudioChapterStore.Data(data.duration,copy);
    }
    private static String name(String title){String s=title.trim();if(s.length()>120)throw bad();return s;}
    private static IllegalArgumentException bad(){return new IllegalArgumentException("Confira os horários: use minutos:segundos. Cada faixa precisa ter duração positiva, sem ultrapassar a próxima divisão.");}
}
