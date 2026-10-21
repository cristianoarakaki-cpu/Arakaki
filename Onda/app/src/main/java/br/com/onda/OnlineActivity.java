package br.com.onda;

import android.app.Activity;
import android.content.*;
import android.graphics.Color;
import android.os.*;
import android.view.*;
import android.view.inputmethod.InputMethodManager;
import android.widget.*;
import androidx.media3.common.*;
import androidx.media3.session.MediaController;
import androidx.media3.session.SessionToken;
import com.google.common.util.concurrent.ListenableFuture;
import java.util.*;
import java.util.concurrent.*;

@androidx.media3.common.util.UnstableApi
public class OnlineActivity extends Activity {
    private final Handler handler=new Handler(Looper.getMainLooper());
    private final ExecutorService worker=Executors.newFixedThreadPool(2);
    private Future<?> request;
    private ListenableFuture<MediaController> connection;
    private MediaController player;
    private EditText query;
    private TextView status, playing;
    private LinearLayout results;
    private Button pause;
    private int generation=0;
    private final int green=Color.rgb(184,243,107), muted=Color.rgb(159,174,156);
    @Override public void onCreate(Bundle state){
        super.onCreate(state);
        LinearLayout root=column();root.setBackgroundColor(Color.rgb(16,20,16));
        root.setOnApplyWindowInsetsListener((v,i)->{root.setPadding(dp(20),dp(12)+i.getSystemWindowInsetTop(),dp(20),dp(12)+i.getSystemWindowInsetBottom());return i;});setContentView(root);
        root.addView(button("‹ Biblioteca",v->finish()));root.addView(text("Ouvir online",28,Color.WHITE));
        root.addView(text("Shows ao vivo • Internet Archive\nBusque por artista ou música e escolha um show.",14,muted));
        query=new EditText(this);query.setSingleLine(true);query.setTextColor(Color.WHITE);query.setHintTextColor(muted);query.setHint("Artista ou música");query.setContentDescription("Buscar shows e músicas online");query.setImeOptions(android.view.inputmethod.EditorInfo.IME_ACTION_SEARCH);query.setOnEditorActionListener((v,id,event)->{if(id==android.view.inputmethod.EditorInfo.IME_ACTION_SEARCH){search();return true;}return false;});root.addView(query);
        root.addView(button("Buscar online",v->search()));
        status=text("Exemplos: Grateful Dead, Billy Strings, Goose.\nA busca cobre este acervo de shows, não todos os lançamentos comerciais.",13,muted);root.addView(status);
        ScrollView scroll=new ScrollView(this);results=column();scroll.addView(results);root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
        playing=text("Escolha uma faixa para ouvir no Onda.",14,green);root.addView(playing);
        LinearLayout controls=new LinearLayout(this);pause=button("Reproduzir",v->{if(player!=null&&player.getMediaItemCount()>0){if(player.isPlaying())player.pause();else{player.prepare();player.play();}}});controls.addView(pause,new LinearLayout.LayoutParams(0,dp(48),1));controls.addView(button("Próxima",v->{if(player!=null)player.seekToNext();}),new LinearLayout.LayoutParams(0,dp(48),1));controls.addView(button("Letra",v->{if(player!=null&&player.getCurrentMediaItem()!=null)startActivity(new Intent(this,LyricsActivity.class));}),new LinearLayout.LayoutParams(0,dp(48),1));root.addView(controls);
        root.addView(text("Streaming usa sua conexão de internet.\nFonte: archive.org • disponibilidade sujeita ao acervo.",11,muted));
        connection=new MediaController.Builder(this,new SessionToken(this,new ComponentName(this,PlaybackService.class))).buildAsync();
        connection.addListener(()->{if(isDestroyed())return;try{player=connection.get();player.addListener(new Player.Listener(){@Override public void onEvents(Player p,Player.Events e){refresh();}@Override public void onPlayerError(PlaybackException e){status.setText("Falha ao reproduzir. Verifique a internet ou escolha outra faixa.");}});refresh();}catch(Exception e){status.setText("Não foi possível conectar ao tocador. Volte e tente novamente.");}},handler::post);
    }
    private int startRequest(){if(request!=null)request.cancel(true);results.removeAllViews();return ++generation;}
    private void search(){
        String input=query.getText().toString().trim();if(input.length()<2){status.setText("Digite pelo menos duas letras para buscar.");return;}
        ((InputMethodManager)getSystemService(INPUT_METHOD_SERVICE)).hideSoftInputFromWindow(query.getWindowToken(),0);
        int id=startRequest();status.setText("Buscando shows no Internet Archive…");
        request=worker.submit(()->{try{List<OnlineRepository.Show> shows=OnlineRepository.search(input);handler.post(()->{if(isDestroyed()||id!=generation)return;status.setText(shows.isEmpty()?"Nenhum show encontrado. Tente o nome de outro artista.":shows.size()+" shows encontrados • toque para ver as músicas");for(OnlineRepository.Show show:shows)results.addView(button(show.title+"\n"+show.artist,v->open(show)));});}catch(Exception e){failed(id);}});
    }
    private void open(OnlineRepository.Show show){
        int id=startRequest();status.setText("Carregando faixas: "+show.title);
        request=worker.submit(()->{try{List<OnlineRepository.Track> tracks=OnlineRepository.tracks(show);handler.post(()->{if(isDestroyed()||id!=generation)return;status.setText(tracks.isEmpty()?"Este show não tem faixas MP3 disponíveis. Tente outro.":show.title+"\n"+tracks.size()+" faixas • toque para ouvir");results.addView(button("‹ Voltar aos resultados",v->search()));
            ArrayList<MediaItem> queue=new ArrayList<>();for(OnlineRepository.Track t:tracks)queue.add(new MediaItem.Builder().setMediaId("archive:"+t.url).setUri(t.url).setMediaMetadata(new MediaMetadata.Builder().setTitle(t.title).setArtist(show.artist).setAlbumTitle(show.title).build()).build());
            for(int index=0;index<tracks.size();index++){final int position=index;results.addView(button((index+1)+". "+tracks.get(index).title,v->{if(player==null){status.setText("Tocador iniciando. Tente novamente em instantes.");return;}player.setMediaItems(queue,position,0);player.prepare();player.play();refresh();}));}
        });}catch(Exception e){failed(id);}});
    }
    private void failed(int id){handler.post(()->{if(isDestroyed()||id!=generation)return;status.setText("Não foi possível consultar o acervo. Verifique a internet e tente Buscar online novamente.");});}
    private void refresh(){if(player==null)return;MediaItem item=player.getCurrentMediaItem();playing.setText(item==null?"Escolha uma faixa para ouvir.":item.mediaMetadata.title+" • "+item.mediaMetadata.artist);pause.setText(player.isPlaying()?"Pausar":"Reproduzir");}
    private LinearLayout column(){LinearLayout l=new LinearLayout(this);l.setOrientation(LinearLayout.VERTICAL);return l;}
    private TextView text(String s,int size,int color){TextView t=new TextView(this);t.setText(s);t.setTextSize(size);t.setTextColor(color);t.setPadding(0,dp(6),0,dp(6));return t;}
    private Button button(String s,View.OnClickListener l){Button b=new Button(this);b.setText(s);b.setAllCaps(false);b.setTextColor(green);b.setBackgroundColor(Color.TRANSPARENT);b.setGravity(Gravity.START|Gravity.CENTER_VERTICAL);b.setPadding(dp(8),dp(12),dp(8),dp(12));b.setOnClickListener(l);return b;}
    private int dp(int n){return Math.round(n*getResources().getDisplayMetrics().density);}
    @Override public void onDestroy(){generation++;if(request!=null)request.cancel(true);worker.shutdownNow();handler.removeCallbacksAndMessages(null);if(connection!=null)MediaController.releaseFuture(connection);super.onDestroy();}
}
