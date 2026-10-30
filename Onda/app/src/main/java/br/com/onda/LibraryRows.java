package br.com.onda;

import android.content.Context;
import android.view.*;
import android.widget.*;
import androidx.media3.common.MediaItem;
import java.util.*;
import java.util.function.Consumer;

/** Keeps metadata for the whole library, but creates native cards only as ListView needs them. */
@androidx.media3.common.util.UnstableApi
final class LibraryRows extends BaseAdapter {
 private static final class Row {final String group;final MediaItem item;Row(String g,MediaItem i){group=g;item=i;}}
 private static final class Holder {LinearLayout card;TextView title,artist;MediaItem item;boolean selected;String palette;}
 private final Context context;private final ListView list;private final Consumer<MediaItem> play,enqueue;private final List<Row> rows=new ArrayList<>();private String current="";
 LibraryRows(Context c,ListView view,Consumer<MediaItem> select,Consumer<MediaItem> more){context=c;list=view;play=select;enqueue=more;}
 void submit(List<MediaItem> songs,int order){rows.clear();String last="";for(MediaItem item:songs){if(order==1||order==2){CharSequence value=order==1?item.mediaMetadata.artist:item.mediaMetadata.albumTitle;String group=value==null||value.toString().trim().isEmpty()?(order==1?"Artista desconhecido":"Sem álbum"):value.toString();if(!group.equals(last)){rows.add(new Row(group,null));last=group;}}rows.add(new Row(null,item));}notifyDataSetChanged();}
 void current(String id){if(current.equals(id))return;current=id;for(int i=0;i<list.getChildCount();i++){Object tag=list.getChildAt(i).getTag();if(tag instanceof Holder)highlight((Holder)tag);}}
 private void highlight(Holder h){boolean active=h.item!=null&&h.item.mediaId.equals(current);if(h.selected!=active){Ui.card(h.card,active);h.selected=active;}}
 @Override public int getCount(){return rows.size();}@Override public Object getItem(int p){return rows.get(p).item;}@Override public long getItemId(int p){return p;}
 @Override public int getViewTypeCount(){return 2;}@Override public int getItemViewType(int p){return rows.get(p).item==null?1:0;}@Override public boolean areAllItemsEnabled(){return false;}@Override public boolean isEnabled(int p){return rows.get(p).item!=null;}
 @Override public View getView(int position,View recycled,ViewGroup parent){Row data=rows.get(position);if(data.item==null){TextView heading=recycled instanceof TextView?(TextView)recycled:Ui.eyebrow(context,"");heading.setText(data.group);heading.setTextColor(Ui.CYAN);heading.setPadding(0,Ui.dp(context,12),0,Ui.dp(context,6));return heading;}
  FrameLayout wrapper;Holder h;if(recycled instanceof FrameLayout){wrapper=(FrameLayout)recycled;h=(Holder)wrapper.getTag();}else{wrapper=new FrameLayout(context);h=new Holder();h.card=Ui.result(context,""," ",0,null);LinearLayout copy=(LinearLayout)h.card.getChildAt(1);h.title=(TextView)copy.getChildAt(0);h.artist=(TextView)copy.getChildAt(1);FrameLayout.LayoutParams params=new FrameLayout.LayoutParams(-1,-2);params.bottomMargin=Ui.dp(context,8);wrapper.addView(h.card,params);wrapper.setTag(h);Holder bound=h;h.card.setOnClickListener(v->{if(bound.item!=null)play.accept(bound.item);});h.card.setOnLongClickListener(v->{if(bound.item!=null)enqueue.accept(bound.item);return true;});h.palette=Ui.palette.id;}
  h.item=data.item;h.title.setText(String.valueOf(data.item.mediaMetadata.title));h.artist.setText(String.valueOf(data.item.mediaMetadata.artist));h.card.setContentDescription("Tocar "+data.item.mediaMetadata.title+", "+data.item.mediaMetadata.artist);if(!h.palette.equals(Ui.palette.id)){Ui.restyle(h.card);h.palette=Ui.palette.id;}highlight(h);return wrapper;
 }
}
