package br.com.onda;

import android.content.Context;
import android.os.Bundle;
import androidx.media3.common.C;
import androidx.media3.common.MediaItem;
import org.json.JSONObject;

/** Native, non-destructive chapter bounds. Positions saved outside the player stay absolute. */
@androidx.media3.common.util.UnstableApi
final class AudioChapterPlayback {
    static final String SELECT="audio_chapter_select";
    private static final String START="onda.chapter.start",END="onda.chapter.end",
            DURATION="onda.chapter.duration",TITLE="onda.chapter.title",STAMP="onda.chapter.stamp";

    private static Bundle extras(MediaItem item){return item==null?null:item.mediaMetadata.extras;}
    static boolean selected(MediaItem item){
        Bundle b=extras(item);
        if(b==null||item.localConfiguration==null||YouTubeAudio.is(item)||RadioMedia.is(item))return false;
        String scheme=item.localConfiguration.uri.getScheme();
        long start=b.getLong(START,-1),end=b.getLong(END,-1),duration=b.getLong(DURATION,0);
        return ("file".equals(scheme)||"content".equals(scheme))&&start>=0&&end>start&&end<=duration;
    }
    static long start(MediaItem item){return selected(item)?extras(item).getLong(START):0;}
    static long end(MediaItem item){return selected(item)?extras(item).getLong(END):0;}
    static String label(MediaItem item){return selected(item)?extras(item).getString(TITLE,"Faixa da coletânea"):"";}
    static boolean clipped(MediaItem item){return selected(item)
            &&item.clippingConfiguration.startPositionMs==start(item)
            &&item.clippingConfiguration.endPositionMs==end(item);}
    static long absolute(MediaItem item,long position){
        long at=Math.max(0,position);
        return clipped(item)?start(item)+Math.min(end(item)-start(item),at):at;
    }
    static long position(MediaItem item,long absolute){
        return clipped(item)?(absolute>=start(item)&&absolute<end(item)?absolute-start(item):0):Math.max(0,absolute);
    }
    static long bookmark(MediaItem item,long position,boolean ended){
        return ended?(clipped(item)?start(item):0):absolute(item,position);
    }
    static long duration(MediaItem item,long fallback){
        return Math.max(fallback,selected(item)?extras(item).getLong(DURATION):item==null?0:LibraryStore.number(item,"durationMs"));
    }
    static MediaItem select(MediaItem item,AudioChapterStore.Data data,int index,String stamp){
        if(item==null||index<0||index>=data.chapters.size())throw new IllegalArgumentException("Faixa inválida");
        long start=data.chapters.get(index).start,end=index+1<data.chapters.size()?data.chapters.get(index+1).start:data.duration;
        Bundle b=extras(item)==null?new Bundle():new Bundle(extras(item));
        b.putLong(START,start);b.putLong(END,end);b.putLong(DURATION,data.duration);
        b.putLong("durationMs",data.duration);b.putString(TITLE,AudioChapterStore.label(data,index));b.putString(STAMP,stamp);
        MediaItem result=item.buildUpon().setMediaMetadata(item.mediaMetadata.buildUpon().setExtras(b).build()).build();
        if(!selected(result))throw new IllegalArgumentException("Limites da faixa inválidos");
        return result;
    }
    static MediaItem configure(MediaItem item,boolean repeat){
        if(!selected(item))return item;
        MediaItem.ClippingConfiguration.Builder clip=new MediaItem.ClippingConfiguration.Builder();
        if(repeat)clip.setStartPositionMs(start(item)).setEndPositionMs(end(item));
        return item.buildUpon().setClippingConfiguration(clip.build()).build();
    }
    static boolean configured(MediaItem item,boolean repeat){return !selected(item)||(repeat?clipped(item):
            item.clippingConfiguration.startPositionMs==0&&item.clippingConfiguration.endPositionMs==C.TIME_END_OF_SOURCE);}
    static String encode(MediaItem item){
        if(!selected(item))return "";
        try{return new JSONObject().put("id",item.mediaId).put("uri",item.localConfiguration.uri.toString())
                .put("start",start(item)).put("end",end(item)).put("duration",extras(item).getLong(DURATION))
                .put("stamp",extras(item).getString(STAMP,"")).toString();}catch(Exception error){return "";}
    }
    /** Called on the existing resume worker, never the playback or UI thread. */
    static MediaItem restore(Context context,MediaItem item,String encoded){
        if(encoded==null||encoded.isEmpty()||encoded.length()>8192||item==null||item.localConfiguration==null)return item;
        try{
            JSONObject json=new JSONObject(encoded);
            if(!item.mediaId.equals(json.getString("id"))||!item.localConfiguration.uri.toString().equals(json.getString("uri")))return item;
            String stamp=AudioChapterStore.stamp(context,item.localConfiguration.uri);
            if(!stamp.equals(json.getString("stamp")))return item;
            AudioChapterStore.Data data=AudioChapterStore.load(context,item.localConfiguration.uri,stamp,
                    LibraryStore.number(item,"durationMs"));
            if(data==null||Math.abs(data.duration-json.getLong("duration"))>1500)return item;
            for(int i=0;i<data.chapters.size();i++){
                long end=i+1<data.chapters.size()?data.chapters.get(i+1).start:data.duration;
                if(data.chapters.get(i).start==json.getLong("start")&&end==json.getLong("end"))return select(item,data,i,stamp);
            }
        }catch(Exception ignored){/* Invalidated markers must never turn into a whole-collection loop. */}
        return item;
    }
}
