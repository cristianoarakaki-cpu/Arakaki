package br.com.onda;

import android.app.Activity;
import android.content.ComponentName;
import android.graphics.Color;
import android.graphics.Typeface;
import android.os.*;
import android.view.*;
import android.widget.*;
import androidx.media3.common.*;
import androidx.media3.session.MediaController;
import androidx.media3.session.SessionToken;
import com.google.common.util.concurrent.ListenableFuture;
import java.util.*;
import java.util.concurrent.*;

@androidx.media3.common.util.UnstableApi
public class LyricsActivity extends Activity {
    private final int green = Color.rgb(184,243,107), muted = Color.rgb(159,174,156);
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final ExecutorService network = Executors.newFixedThreadPool(2);
    private ListenableFuture<MediaController> connection;
    private MediaController player;
    private Future<?> request;
    private TextView heading, status;
    private EditText track, artist;
    private Button play;
    private LinearLayout linesView;
    private ScrollView scroll;
    private final List<TextView> labels = new ArrayList<>();
    private List<Lrc.Line> lines = Collections.emptyList();
    private String songKey = "";
    private int generation = 0, highlighted = -1;
    private long manualUntil = 0;
    private boolean durationKnown = false;
    private boolean screenStarted = false;
    private int lastScrolled = -1;
    private final Runnable tick = new Runnable() { public void run() {
        if (!screenStarted) return;
        if (player != null) {
            followSong();
            play.setText(player.isPlaying() ? "Pausar" : "Reproduzir");
            int index = Lrc.active(lines, player.getCurrentPosition());
            if (index != highlighted) {
                if (highlighted >= 0 && highlighted < labels.size()) style(labels.get(highlighted), false);
                highlighted = index;
                if (index >= 0 && index < labels.size()) style(labels.get(index), true);
            }
            if (index >= 0 && index < labels.size() && index != lastScrolled && SystemClock.uptimeMillis() >= manualUntil) {
                lastScrolled = index;
                int target = Math.max(0, labels.get(index).getTop() - scroll.getHeight() / 3);
                if (Math.abs(scroll.getScrollY() - target) > dp(8)) scroll.smoothScrollTo(0, target);
            }
        }
        if (player != null && player.isPlaying()) handler.postDelayed(this, 500);
    }};
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        LinearLayout root = column(); root.setBackgroundColor(Color.rgb(16,20,16));
        root.setOnApplyWindowInsetsListener((v,i)->{root.setPadding(dp(20),dp(12)+i.getSystemWindowInsetTop(),dp(20),dp(12)+i.getSystemWindowInsetBottom());return i;});
        setContentView(root);
        root.addView(button("‹ Voltar à biblioteca", v->finish()));
        heading = text("Letra da música", 25, Color.WHITE); root.addView(heading);
        status = text("Conectando ao tocador…", 13, muted); root.addView(status);
        track = new EditText(this);track.setSingleLine(true);track.setTextColor(Color.WHITE);track.setHintTextColor(muted);track.setHint("Nome da música");track.setContentDescription("Nome da música para buscar letra");root.addView(track);
        artist = new EditText(this);artist.setSingleLine(true);artist.setTextColor(Color.WHITE);artist.setHintTextColor(muted);artist.setHint("Artista");artist.setContentDescription("Artista para buscar letra");root.addView(artist);
        root.addView(button("Buscar letra",v->load()));
        scroll = new ScrollView(this);linesView = column();scroll.addView(linesView);root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
        scroll.setOnTouchListener((v,e)->{manualUntil=SystemClock.uptimeMillis()+5000;lastScrolled=-1;return false;});
        play = button("Reproduzir",v->{if(player!=null&&player.getMediaItemCount()>0){if(player.isPlaying())player.pause();else player.play();}});root.addView(play);
        root.addView(text("Letras: LRCLIB • título e artista são enviados para buscar.\nA disponibilidade e a sincronização variam por música.",11,muted));
        connection = new MediaController.Builder(this,new SessionToken(this,new ComponentName(this,PlaybackService.class))).buildAsync();
        connection.addListener(()->{if(isDestroyed())return;try{player=connection.get();player.addListener(new Player.Listener(){@Override public void onEvents(Player p,Player.Events events){restartTick();}});if(screenStarted)followSong();restartTick();}catch(Exception e){status.setText("Não foi possível conectar. Volte e tente novamente.");}},handler::post);
    }
    private void restartTick(){handler.removeCallbacks(tick);if(screenStarted)handler.post(tick);}
    @Override protected void onStart(){super.onStart();screenStarted=true;restartTick();}
    @Override protected void onStop(){screenStarted=false;handler.removeCallbacks(tick);super.onStop();}
    private void followSong(){
        MediaItem item=player.getCurrentMediaItem();
        String key=item==null?"":item.mediaId+"\n"+item.mediaMetadata.title+"\n"+item.mediaMetadata.artist;
        if(item==null){if(!songKey.isEmpty()||generation==0){songKey="";generation++;clear();status.setText("Volte à biblioteca e escolha uma música.");}return;}
        if(!key.equals(songKey)){
            songKey=key;durationKnown=player.getDuration()>0;
            heading.setText(item.mediaMetadata.title);track.setText(item.mediaMetadata.title);
            String name=String.valueOf(item.mediaMetadata.artist);artist.setText(name.equals("Artista desconhecido")||name.equals("null")?"":name);
            load();
        }else if(!durationKnown&&player.getDuration()>0){durationKnown=true;load();}
    }
    private void clear(){lines=Collections.emptyList();labels.clear();linesView.removeAllViews();highlighted=-1;lastScrolled=-1;manualUntil=0;scroll.scrollTo(0,0);}
    private void load(){
        int id=++generation;if(request!=null)request.cancel(true);clear();
        String title=track.getText().toString().trim(), author=artist.getText().toString().trim();
        if(player==null||player.getCurrentMediaItem()==null){status.setText("Escolha uma música na biblioteca primeiro.");return;}
        if(title.isEmpty()||author.isEmpty()){status.setText("Preencha o título e o artista para encontrar a letra.");return;}
        long duration=player.getDuration();status.setText("Buscando letra na internet…");
        request=network.submit(()->{
            try{
                LyricsRepository.Result result=LyricsRepository.fetch(getApplicationContext(),title,author,duration);
                handler.post(()->{if(isDestroyed()||id!=generation)return;show(result);});
            }catch(Exception e){handler.post(()->{if(isDestroyed()||id!=generation)return;status.setText("Não foi possível buscar. Verifique sua internet e toque em Buscar letra para tentar novamente.");});}
        });
    }
    private void show(LyricsRepository.Result result){
        restartTick();
        if(result==null){status.setText("Letra não encontrada. Confira título e artista e tente novamente.");return;}
        if(result.instrumental){status.setText("Esta faixa está marcada como instrumental, sem letra.");return;}
        lines=Lrc.parse(result.synced);
        if(!lines.isEmpty()){
            status.setText("Letra sincronizada • toque em um verso para ir até ele");
            for(Lrc.Line line:lines){TextView label=text(line.text.isEmpty()?"♪":line.text,23,muted);label.setPadding(0,dp(14),0,dp(14));label.setOnClickListener(v->{if(player!=null)player.seekTo(line.ms);manualUntil=0;});linesView.addView(label);labels.add(label);}
            linesView.setPadding(0,dp(24),0,dp(160));
        }else if(!result.plain.trim().isEmpty()){
            status.setText("Letra disponível sem sincronização • role para acompanhar");
            TextView plain=text(result.plain,22,Color.WHITE);plain.setLineSpacing(dp(10),1);linesView.addView(plain);
        }else status.setText("Letra não encontrada. Confira título e artista.");
    }
    private void style(TextView v,boolean current){v.setTextColor(current?green:muted);v.setTypeface(null,current?Typeface.BOLD:Typeface.NORMAL);}
    private LinearLayout column(){LinearLayout l=new LinearLayout(this);l.setOrientation(LinearLayout.VERTICAL);return l;}
    private TextView text(String s,int size,int color){TextView t=new TextView(this);t.setText(s);t.setTextSize(size);t.setTextColor(color);t.setPadding(0,dp(4),0,dp(4));return t;}
    private Button button(String s,View.OnClickListener l){Button b=new Button(this);b.setText(s);b.setAllCaps(false);b.setTextColor(green);b.setBackgroundColor(Color.TRANSPARENT);b.setOnClickListener(l);return b;}
    private int dp(int n){return Math.round(n*getResources().getDisplayMetrics().density);}
    @Override public void onDestroy(){generation++;if(request!=null)request.cancel(true);network.shutdownNow();handler.removeCallbacksAndMessages(null);if(connection!=null)MediaController.releaseFuture(connection);super.onDestroy();}
}
