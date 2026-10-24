package br.com.onda;
import android.app.Activity;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.text.TextUtils;
import android.view.*;
import android.widget.*;

/** Full selection screen with a persistent download action and recycled native rows. */
final class PlaylistPicker implements AutoCloseable {
 final LinearLayout root;final ListView list;final CheckBox all;final Button download,clear;final PlaylistSelection selection;private final PlaylistArtwork artwork=new PlaylistArtwork(this::refreshRows);private final Rows adapter;private final Activity activity;private boolean syncing;
 PlaylistPicker(Activity context,String title,PlaylistSelection state,Runnable back,Runnable proceed){activity=context;selection=state;root=new LinearLayout(context);root.setOrientation(LinearLayout.VERTICAL);Ui.background(root);root.setOnApplyWindowInsetsListener((v,i)->{root.setPadding(dp(16),dp(8)+i.getSystemWindowInsetTop(),dp(16),dp(12)+i.getSystemWindowInsetBottom());return i;});
  LinearLayout header=new LinearLayout(context);header.setGravity(Gravity.CENTER_VERTICAL);Button close=Ui.button(context,"×",v->back.run());close.setTextSize(25);close.setContentDescription("Voltar aos downloads");Ui.ghost(close);header.addView(close,new LinearLayout.LayoutParams(dp(48),dp(48)));TextView name=Ui.text(context,title,20,Ui.TEXT);Ui.bold(name);name.setMaxLines(1);name.setEllipsize(TextUtils.TruncateAt.END);name.setContentDescription(title);header.addView(name,new LinearLayout.LayoutParams(0,dp(48),1));name.setGravity(Gravity.CENTER_VERTICAL);root.addView(header);
  TextView subtitle=Ui.text(context,state.items.size()+" vídeos • marque os que deseja baixar",13,Ui.MUTED);subtitle.setPadding(dp(8),dp(8),0,dp(8));root.addView(subtitle);
  LinearLayout controls=new LinearLayout(context);controls.setGravity(Gravity.CENTER_VERTICAL);all=new CheckBox(context);all.setText("Selecionar tudo");all.setTextColor(Ui.TEXT);all.setButtonTintList(ColorStateList.valueOf(Ui.CYAN));controls.addView(all,new LinearLayout.LayoutParams(0,dp(52),1));clear=Ui.button(context,"Limpar",v->{selection.all(false);changed();});Ui.ghost(clear);clear.setContentDescription("Limpar seleção de vídeos");controls.addView(clear,new LinearLayout.LayoutParams(dp(80),dp(48)));root.addView(controls);
  list=new ListView(context);list.setDivider(null);list.setCacheColorHint(Color.TRANSPARENT);adapter=new Rows();list.setAdapter(adapter);root.addView(list,new LinearLayout.LayoutParams(-1,0,1));
  download=Ui.button(context,"Baixar (0)",v->proceed.run());Ui.primary(download);LinearLayout.LayoutParams bottom=new LinearLayout.LayoutParams(-1,dp(56));bottom.topMargin=dp(10);root.addView(download,bottom);
  all.setOnCheckedChangeListener((button,checked)->{if(!syncing){selection.all(checked);changed();}});changed();
 }
 private void refreshRows(){if(adapter!=null)adapter.notifyDataSetChanged();}
 private int dp(int n){return Ui.dp(activity,n);}
 private void changed(){syncing=true;all.setChecked(selection.count()==selection.items.size());all.setContentDescription("Selecionar tudo, "+selection.count()+" de "+selection.items.size()+" marcados");syncing=false;download.setText("Baixar ("+selection.count()+")");download.setContentDescription("Baixar "+selection.count()+" vídeos selecionados");download.setEnabled(selection.count()>0);download.setAlpha(selection.count()>0?1f:.45f);adapter.notifyDataSetChanged();}
 void resume(){artwork.resume();adapter.notifyDataSetChanged();}
 void pause(){artwork.pause();}
 @Override public void close(){artwork.close();}
 private static final class Holder {CheckBox check;ImageView image;TextView duration,title;}
 private final class Rows extends BaseAdapter {
  @Override public int getCount(){return selection.items.size();}
  @Override public Object getItem(int position){return selection.items.get(position);}
  @Override public long getItemId(int position){return position;}
  @Override public View getView(int position,View recycled,ViewGroup parent){Holder h;LinearLayout row;
   if(recycled==null){row=new LinearLayout(activity);row.setGravity(Gravity.CENTER_VERTICAL);row.setPadding(0,dp(8),0,dp(8));h=new Holder();h.check=new CheckBox(activity);h.check.setTag("playlist-check");h.check.setFocusable(false);h.check.setButtonTintList(ColorStateList.valueOf(Ui.CYAN));row.addView(h.check,new LinearLayout.LayoutParams(dp(40),dp(48)));
    FrameLayout preview=new FrameLayout(activity);preview.setBackground(Ui.shape(activity,Ui.RAISED,0,10));preview.setClipToOutline(true);h.image=new ImageView(activity);h.image.setScaleType(ImageView.ScaleType.CENTER_CROP);h.image.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_NO);preview.addView(h.image,new FrameLayout.LayoutParams(-1,-1));h.duration=Ui.text(activity,"",11,Color.WHITE);h.duration.setPadding(dp(4),dp(2),dp(4),dp(2));h.duration.setBackground(Ui.shape(activity,0xCC000000,0,4));FrameLayout.LayoutParams badge=new FrameLayout.LayoutParams(-2,-2,Gravity.BOTTOM|Gravity.END);badge.setMargins(0,0,dp(3),dp(3));preview.addView(h.duration,badge);row.addView(preview,new LinearLayout.LayoutParams(dp(112),dp(68)));
    h.title=Ui.text(activity,"",16,Ui.TEXT);h.title.setMaxLines(3);h.title.setEllipsize(TextUtils.TruncateAt.END);LinearLayout.LayoutParams copy=new LinearLayout.LayoutParams(0,-2,1);copy.leftMargin=dp(12);row.addView(h.title,copy);row.setMinimumHeight(dp(96));row.setTag(h);
   }else{row=(LinearLayout)recycled;h=(Holder)row.getTag();}
   YoutubeDownloads.Entry e=selection.items.get(position);h.check.setOnCheckedChangeListener(null);h.check.setChecked(selection.contains(position));h.check.setContentDescription("Selecionar vídeo "+(position+1)+": "+e.title);h.check.setOnCheckedChangeListener((button,checked)->{selection.set(position,checked);changed();});h.title.setText((position+1)+". "+e.title);String length=PlaylistSelection.duration(e.duration);h.duration.setText(length);h.duration.setVisibility(length.isEmpty()?View.GONE:View.VISIBLE);artwork.load(e.thumbnail,h.image);row.setOnClickListener(v->{selection.set(position,!selection.contains(position));changed();});return row;
  }
 }
}
