package br.com.onda;

import android.app.Activity;
import android.content.*;
import android.os.*;
import android.view.Gravity;
import android.widget.*;
import androidx.media3.common.*;
import androidx.media3.session.*;
import androidx.media3.session.MediaController;
import com.google.common.util.concurrent.ListenableFuture;
import java.util.*;
import java.util.concurrent.*;

@androidx.media3.common.util.UnstableApi
public class SmartLibraryActivity extends Activity {
    private final ExecutorService worker=Executors.newSingleThreadExecutor();
    private final List<MediaItem> songs=new ArrayList<>();
    private LinearLayout rows;private TextView status;private Spinner collections;
    private MediaController player;private ListenableFuture<MediaController> connection;
    @Override public void onCreate(Bundle state){
        super.onCreate(state);LinearLayout root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);Ui.background(root);int pad=Ui.dp(this,20);
        root.setOnApplyWindowInsetsListener((v,i)->{root.setPadding(pad,pad+i.getSystemWindowInsetTop(),pad,pad+i.getSystemWindowInsetBottom());return i;});setContentView(root);
        Button back=Ui.button(this,"‹  Biblioteca",v->finish());Ui.ghost(back);root.addView(back);
        TextView heading=Ui.text(this,"Onda Lab",30,Ui.TEXT);Ui.bold(heading);root.addView(heading);
        TextView intro=Ui.text(this,"Sua música, em novas conexões",15,Ui.CYAN);root.addView(intro);
        TextView help=Ui.text(this,"No microfone: ‘toque minhas favoritas’, ‘próxima música’ ou ‘pare em 30 minutos’. O microfone só é aberto ao tocar no botão de voz.",13,Ui.MUTED);help.setPadding(0,pad,0,pad);root.addView(help);
        root.addView(Ui.eyebrow(this,"FADE SUAVE"));
        Spinner fade=new Spinner(this);fade.setContentDescription("Duração do fade suave");fade.setAdapter(new ArrayAdapter<>(this,R.layout.spinner_item,new String[]{"Desativado","1 segundo","2 segundos","3 segundos"}));Ui.spinner(fade);
        int initial=getSharedPreferences("audio",0).getInt("fade_ms",2000)/1000;fade.setSelection(Math.max(0,Math.min(3,initial)));root.addView(fade);
        fade.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener(){public void onNothingSelected(AdapterView<?> p){}public void onItemSelected(AdapterView<?> p,android.view.View v,int position,long id){int ms=position*1000;getSharedPreferences("audio",0).edit().putInt("fade_ms",ms).apply();if(player!=null)player.sendCustomCommand(new SessionCommand("fade",Bundle.EMPTY),Bundle.EMPTY);}});
        root.addView(Ui.text(this,"Volume desce no fim e sobe na próxima faixa. Sem sobrepor músicas. Não aplicado às prévias online.",12,Ui.MUTED));
        collections=new Spinner(this);collections.setContentDescription("Coleção inteligente");collections.setAdapter(new ArrayAdapter<>(this,R.layout.spinner_item,new String[]{"Favoritas","Mais tocadas","Ouvidas recentemente","Redescobrir","Possíveis duplicatas"}));Ui.spinner(collections);root.addView(collections);
        status=Ui.text(this,"Lendo biblioteca…",12,Ui.MUTED);root.addView(status);ScrollView scroll=new ScrollView(this);rows=new LinearLayout(this);rows.setOrientation(LinearLayout.VERTICAL);scroll.addView(rows);root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
        collections.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener(){public void onNothingSelected(AdapterView<?> p){}public void onItemSelected(AdapterView<?> p,android.view.View v,int position,long id){render(position);}});
        connection=new MediaController.Builder(this,new SessionToken(this,new ComponentName(this,PlaybackService.class))).buildAsync();connection.addListener(()->{try{player=connection.get();}catch(Exception ignored){}},command->new Handler(Looper.getMainLooper()).post(command));
        worker.execute(()->{try{List<MediaItem> found=LibraryStore.scan(this);runOnUiThread(()->{if(isDestroyed())return;songs.addAll(found);render(collections.getSelectedItemPosition());});}catch(Exception e){runOnUiThread(()->status.setText("Permita acesso às músicas na Biblioteca e tente novamente."));}});
    }
    private void render(int mode){if(rows==null)return;rows.removeAllViews();ArrayList<MediaItem> selected=new ArrayList<>();Set<String> favorites=getSharedPreferences("library",0).getStringSet("favorites",Collections.emptySet());
        if(mode==4){List<LibraryIntelligence.Song> entries=new ArrayList<>();Map<String,MediaItem> byId=new HashMap<>();for(MediaItem song:songs){entries.add(new LibraryIntelligence.Song(song.mediaId,String.valueOf(song.mediaMetadata.title),String.valueOf(song.mediaMetadata.artist),LibraryStore.number(song,"durationMs")));byId.put(song.mediaId,song);}List<List<LibraryIntelligence.Song>> groups=LibraryIntelligence.duplicates(entries);status.setText(groups.size()+" grupos possíveis • nenhum arquivo é apagado");for(List<LibraryIntelligence.Song> group:groups){rows.addView(Ui.text(this,"Mesmo título, artista e duração semelhante",12,Ui.CYAN));for(LibraryIntelligence.Song song:group){MediaItem item=byId.get(song.id);add(item,new ArrayList<>(Collections.singletonList(item)),"Arquivo #"+song.id+" • "+LibraryStore.number(item,"size")/1024+" KB");}}if(groups.isEmpty())rows.addView(Ui.text(this,"Nenhum grupo semelhante encontrado. Esta análise compara metadados, não o áudio dos arquivos.",14,Ui.MUTED));return;}
        for(MediaItem song:songs)if(mode==0?favorites.contains(song.mediaId):mode==1?LibraryStore.count(this,song.mediaId)>0:mode==2?LibraryStore.last(this,song.mediaId)>0:true)selected.add(song);
        if(mode==1)selected.sort((a,b)->Integer.compare(LibraryStore.count(this,b.mediaId),LibraryStore.count(this,a.mediaId)));
        if(mode==2)selected.sort((a,b)->Long.compare(LibraryStore.last(this,b.mediaId),LibraryStore.last(this,a.mediaId)));
        if(mode==3)selected.sort((a,b)->Long.compare(LibraryStore.last(this,a.mediaId),LibraryStore.last(this,b.mediaId)));
        status.setText(selected.size()+" músicas • histórico guardado só neste celular");
        for(MediaItem item:selected)add(item,selected,String.valueOf(item.mediaMetadata.artist)+(mode==1?" • "+LibraryStore.count(this,item.mediaId)+" reproduções":""));
        if(selected.isEmpty())rows.addView(Ui.text(this,"Esta coleção cresce conforme você ouve e favorita suas músicas. O histórico começa nesta versão e conta até 30 segundos de escuta por faixa.",14,Ui.MUTED));
    }
    private void add(MediaItem item,List<MediaItem> queue,String detail){LinearLayout row=Ui.result(this,String.valueOf(item.mediaMetadata.title),detail,item.mediaId.hashCode(),v->{if(player==null)return;player.setMediaItems(new ArrayList<>(queue),queue.indexOf(item),0);player.prepare();player.play();Toast.makeText(this,"Tocando "+item.mediaMetadata.title,Toast.LENGTH_SHORT).show();});row.setContentDescription("Tocar "+item.mediaMetadata.title);rows.addView(row);}
    @Override public void onDestroy(){worker.shutdownNow();if(connection!=null)MediaController.releaseFuture(connection);super.onDestroy();}
}
