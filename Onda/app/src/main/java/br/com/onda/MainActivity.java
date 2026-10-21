package br.com.onda;

import android.Manifest;
import android.app.*;
import android.content.*;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.*;
import android.provider.MediaStore;
import android.text.*;
import android.view.*;
import android.widget.*;
import androidx.media3.common.*;
import androidx.media3.session.*;
import androidx.media3.session.MediaController;
import com.google.common.util.concurrent.ListenableFuture;
import java.util.*;
import java.util.concurrent.*;

@androidx.media3.common.util.UnstableApi
public class MainActivity extends Activity {
    private final int bg = Color.rgb(16,20,16), panel = Color.rgb(29,35,29), green = Color.rgb(184,243,107), muted = Color.rgb(159,174,156);
    private final ArrayList<MediaItem> songs = new ArrayList<>();
    private final ExecutorService scanner = Executors.newSingleThreadExecutor();
    private final Handler handler = new Handler(Looper.getMainLooper());
    private MediaController player;
    private ListenableFuture<MediaController> connection;
    private LinearLayout rows;
    private TextView status, title, artist, elapsed, total;
    private Button play, shuffle, repeat, favorite;
    private SeekBar seek;
    private String query = "";
    private boolean onlyFavorites = false, seeking = false;
    private Set<String> favorites;
    private SharedPreferences prefs;
    private final Runnable progress = new Runnable() { public void run() {
        if (player != null && !seeking) { seek.setProgress((int)player.getCurrentPosition()); elapsed.setText(time(player.getCurrentPosition())); }
        handler.postDelayed(this, 500);
    }};

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        prefs = getSharedPreferences("library", MODE_PRIVATE);
        favorites = new HashSet<>(prefs.getStringSet("favorites", Collections.emptySet()));
        LinearLayout root = column(); root.setBackgroundColor(bg); root.setPadding(dp(20),dp(12),dp(20),dp(12));
        root.setOnApplyWindowInsetsListener((v, insets) -> { root.setPadding(dp(20),dp(12)+insets.getSystemWindowInsetTop(),dp(20),dp(12)+insets.getSystemWindowInsetBottom()); return insets; });
        setContentView(root);
        TextView brand = label("≋  onda", 34, green); brand.setTypeface(null,Typeface.BOLD); root.addView(brand);
        root.addView(label("Sua música. No seu ritmo.",14,muted));
        EditText search = new EditText(this); search.setSingleLine(true); search.setTextColor(Color.WHITE); search.setHintTextColor(muted); search.setTextSize(16); search.setHint("Buscar música, artista ou álbum"); search.setContentDescription("Buscar na biblioteca"); root.addView(search);
        search.addTextChangedListener(new TextWatcher() { public void beforeTextChanged(CharSequence s,int st,int c,int a){} public void onTextChanged(CharSequence s,int st,int before,int count){ query=s.toString().toLowerCase(Locale.ROOT); render(); } public void afterTextChanged(Editable e){} });
        LinearLayout tabs = new LinearLayout(this);
        tabs.addView(button("Todas",v->{onlyFavorites=false;render();}), new LinearLayout.LayoutParams(0,dp(48),1));
        tabs.addView(button("Favoritas ♡",v->{onlyFavorites=true;render();}), new LinearLayout.LayoutParams(0,dp(48),1));
        tabs.addView(button("Atualizar",v->permission()), new LinearLayout.LayoutParams(0,dp(48),1)); root.addView(tabs);
        root.addView(button("⌕ Buscar e ouvir online",v->startActivity(new Intent(this,OnlineActivity.class))));
        status=label("Preparando biblioteca…",13,muted); root.addView(status);
        ScrollView scroll = new ScrollView(this); rows=column(); scroll.addView(rows); root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
        LinearLayout now=column(); now.setPadding(dp(16),dp(12),dp(16),dp(8)); GradientDrawable shape=new GradientDrawable(); shape.setColor(panel); shape.setCornerRadius(dp(20)); now.setBackground(shape); root.addView(now);
        now.addView(label("TOCANDO AGORA",10,green)); title=label("Escolha sua primeira música",19,Color.WHITE); title.setMaxLines(2); now.addView(title);
        artist=label("Arquivos locais • reprodução offline",13,muted); artist.setMaxLines(1); now.addView(artist);
        seek=new SeekBar(this); seek.setContentDescription("Posição na música"); now.addView(seek);
        seek.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener(){public void onProgressChanged(SeekBar b,int p,boolean u){if(u)elapsed.setText(time(p));}public void onStartTrackingTouch(SeekBar b){seeking=true;}public void onStopTrackingTouch(SeekBar b){if(player!=null)player.seekTo(b.getProgress());seeking=false;}});
        LinearLayout times=new LinearLayout(this); elapsed=label("0:00",12,muted); total=label("0:00",12,muted); total.setGravity(Gravity.END); times.addView(elapsed,new LinearLayout.LayoutParams(0,-2,1));times.addView(total,new LinearLayout.LayoutParams(0,-2,1));now.addView(times);
        LinearLayout controls=new LinearLayout(this);
        shuffle=button("⇄",v->{if(player!=null){player.setShuffleModeEnabled(!player.getShuffleModeEnabled());refresh();}}); shuffle.setContentDescription("Alternar modo aleatório");
        Button previous=button("|◀",v->{if(player!=null)player.seekToPrevious();});previous.setContentDescription("Música anterior");
        play=button("▶",v->{if(player==null)return;if(player.isPlaying())player.pause();else if(player.getMediaItemCount()>0){if(player.getPlaybackState()==Player.STATE_ENDED)player.seekToDefaultPosition();player.prepare();player.play();}});play.setTextColor(green);
        Button next=button("▶|",v->{if(player!=null)player.seekToNext();});next.setContentDescription("Próxima música");
        repeat=button("↻",v->{if(player!=null){player.setRepeatMode((player.getRepeatMode()+1)%3);refresh();}});repeat.setContentDescription("Alternar repetição: desativada, uma, todas");
        for(Button b:new Button[]{shuffle,previous,play,next,repeat})controls.addView(b,new LinearLayout.LayoutParams(0,dp(56),1));now.addView(controls);
        LinearLayout extras=new LinearLayout(this);favorite=button("♡ Favoritar",v->toggleFavorite());extras.addView(favorite,new LinearLayout.LayoutParams(0,dp(48),1));extras.addView(button("◷ Timer",v->sleep()),new LinearLayout.LayoutParams(0,dp(48),1));now.addView(extras);
        now.addView(button("♫ Ver letra da música",v->{if(player==null||player.getCurrentMediaItem()==null){Toast.makeText(this,"Escolha uma música primeiro",Toast.LENGTH_SHORT).show();return;}startActivity(new Intent(this,LyricsActivity.class));}));
        connection=new MediaController.Builder(this,new SessionToken(this,new ComponentName(this,PlaybackService.class))).buildAsync();
        connection.addListener(()->{try{player=connection.get();player.addListener(new Player.Listener(){@Override public void onEvents(Player p,Player.Events e){refresh();}@Override public void onPlayerError(PlaybackException e){new AlertDialog.Builder(MainActivity.this).setTitle("Não foi possível tocar").setMessage("O arquivo pode estar indisponível ou usar um codec incompatível com este aparelho. Tente outra música.").setPositiveButton("OK",null).show();}});refresh();}catch(Exception e){status.setText("Falha ao conectar o tocador. Feche e abra o app.");}},handler::post);
        handler.post(progress);permission();
    }
    private void permission(){String p=Build.VERSION.SDK_INT>=33?Manifest.permission.READ_MEDIA_AUDIO:Manifest.permission.READ_EXTERNAL_STORAGE;if(checkSelfPermission(p)==PackageManager.PERMISSION_GRANTED)scan();else requestPermissions(new String[]{p},10);}
    @Override public void onRequestPermissionsResult(int code,String[] p,int[] results){super.onRequestPermissionsResult(code,p,results);if(code==10&&results.length>0&&results[0]==PackageManager.PERMISSION_GRANTED)scan();else{status.setText("Permita acesso às músicas para abrir sua biblioteca.");rows.removeAllViews();Button settings=button("Abrir configurações",v->startActivity(new Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,Uri.parse("package:"+getPackageName()))));rows.addView(settings);}}
    private void scan(){status.setText("Buscando músicas no celular…");scanner.execute(()->{ArrayList<MediaItem> found=new ArrayList<>();String error=null;
        try(Cursor c=getContentResolver().query(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,new String[]{"_id","title","artist","album","duration"},null,null,MediaStore.Audio.Media.TITLE+" COLLATE NOCASE ASC")){
            if(c!=null)while(c.moveToNext()){if(c.getLong(4)<=0)continue;String id=c.getString(0);String name=c.getString(1), author=c.getString(2), album=c.getString(3);found.add(new MediaItem.Builder().setMediaId(id).setUri(ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,c.getLong(0))).setMediaMetadata(new MediaMetadata.Builder().setTitle(name==null?"Sem título":name).setArtist(author==null||author.equals("<unknown>")?"Artista desconhecido":author).setAlbumTitle(album).build()).build());}
        }catch(Exception e){error="Não foi possível ler a biblioteca. Verifique a permissão e tente atualizar.";}
        String message=error;runOnUiThread(()->{if(isDestroyed())return;songs.clear();songs.addAll(found);render();if(message!=null)status.setText(message);});});}
    private void render(){if(rows==null)return;rows.removeAllViews();int count=0;for(MediaItem item:songs){MediaMetadata m=item.mediaMetadata;String text=m.title+" "+m.artist+" "+m.albumTitle;if(!text.toLowerCase(Locale.ROOT).contains(query)||(onlyFavorites&&!favorites.contains(item.mediaId)))continue;count++;
        LinearLayout row=column();row.setPadding(dp(8),dp(12),dp(8),dp(12));TextView name=label((favorites.contains(item.mediaId)?"♥  ":"♫  ")+m.title,16,Color.WHITE);row.addView(name);row.addView(label(m.artist+" · "+m.albumTitle,12,muted));row.setContentDescription("Tocar "+m.title+", "+m.artist);row.setFocusable(true);row.setClickable(true);row.setOnClickListener(v->{if(player==null){Toast.makeText(this,"Tocador iniciando…",Toast.LENGTH_SHORT).show();return;}player.setMediaItems(new ArrayList<>(songs),songs.indexOf(item),0);player.prepare();player.play();});rows.addView(row);
    }status.setText(count+" música"+(count==1?"":"s")+(onlyFavorites?" favorita"+(count==1?"":"s"):" na biblioteca"));if(count==0)rows.addView(label(songs.isEmpty()?"Sua biblioteca está vazia.\nCopie músicas para a pasta Music do celular e toque em Atualizar.":"Nenhuma música encontrada com este filtro.",16,muted));}
    private void refresh(){if(player==null)return;MediaItem item=player.getCurrentMediaItem();if(item!=null){title.setText(item.mediaMetadata.title);artist.setText(item.mediaMetadata.artist);favorite.setText(favorites.contains(item.mediaId)?"♥ Favorita":"♡ Favoritar");}play.setText(player.isPlaying()?"❚❚":"▶");play.setContentDescription(player.isPlaying()?"Pausar":"Reproduzir");shuffle.setTextColor(player.getShuffleModeEnabled()?green:muted);repeat.setText(player.getRepeatMode()==Player.REPEAT_MODE_ONE?"↻ 1":"↻");repeat.setTextColor(player.getRepeatMode()!=Player.REPEAT_MODE_OFF?green:muted);long duration=player.getDuration();seek.setMax(duration>0?(int)Math.min(Integer.MAX_VALUE,duration):0);total.setText(time(duration));}
    private void toggleFavorite(){if(player==null||player.getCurrentMediaItem()==null)return;String id=player.getCurrentMediaItem().mediaId;if(!favorites.remove(id))favorites.add(id);prefs.edit().putStringSet("favorites",new HashSet<>(favorites)).apply();refresh();render();}
    private void sleep(){String[] options={"Desativar","15 minutos","30 minutos","60 minutos","120 minutos"};int[] mins={0,15,30,60,120};new AlertDialog.Builder(this).setTitle("Parar reprodução após…").setItems(options,(dialog,which)->{if(player==null)return;Bundle args=new Bundle();args.putInt("minutes",mins[which]);player.sendCustomCommand(new SessionCommand("sleep",Bundle.EMPTY),args);Toast.makeText(this,which==0?"Temporizador desativado":"A música vai pausar em "+mins[which]+" minutos",Toast.LENGTH_SHORT).show();}).show();}
    private LinearLayout column(){LinearLayout v=new LinearLayout(this);v.setOrientation(LinearLayout.VERTICAL);return v;}
    private TextView label(String text,int size,int color){TextView v=new TextView(this);v.setText(text);v.setTextSize(size);v.setTextColor(color);v.setPadding(0,dp(4),0,dp(4));return v;}
    private Button button(String text,View.OnClickListener listener){Button b=new Button(this);b.setText(text);b.setTextColor(muted);b.setTextSize(13);b.setAllCaps(false);b.setMinWidth(0);b.setMinimumWidth(0);b.setPadding(0,0,0,0);b.setBackgroundColor(Color.TRANSPARENT);b.setOnClickListener(listener);return b;}
    private int dp(int n){return Math.round(n*getResources().getDisplayMetrics().density);}
    private String time(long ms){long s=Math.max(0,ms)/1000;return String.format(Locale.ROOT,"%d:%02d",s/60,s%60);}
    @Override public void onDestroy(){handler.removeCallbacksAndMessages(null);scanner.shutdownNow();if(connection!=null)MediaController.releaseFuture(connection);super.onDestroy();}
}
