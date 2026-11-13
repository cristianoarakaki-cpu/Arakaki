package br.com.onda;

import android.app.Activity;
import android.app.AlertDialog;
import com.google.mlkit.nl.translate.TranslateLanguage;
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
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final ExecutorService network = Executors.newFixedThreadPool(2);
    private ListenableFuture<MediaController> connection;
    private MediaController player;
    private Future<?> request;
    private TextView heading, status;
    private EditText track, artist;
    private Button play,translate;
    private LyricsRepository.Result originalLyrics;
    private final List<String> originalRows=new ArrayList<>();
    private final List<TextView> translationLabels=new ArrayList<>();
    private LocalLyricTranslator translator;private LyricTranslation translationJob;private int translationGeneration;
    private LinearLayout linesView;
    private ScrollView scroll;
    private final List<TextView> labels = new ArrayList<>();
    private List<Lrc.Line> lines = Collections.emptyList();
    private String songKey = "";
    private int generation = 0, highlighted = -1;
    private long manualUntil = 0;
    private boolean durationKnown = false;
    private boolean screenStarted = false;
    private int lastScrolled = -1;private long lyricUpdates;
    private final Runnable tick = new Runnable() { public void run() {
        if (!screenStarted) return;lyricUpdates++;
        if (player != null) {
            followSong();
            String action=player.isPlaying()?"Pausar":"Reproduzir";if(!action.contentEquals(play.getText()))play.setText(action);
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
        if(player!=null&&player.isPlaying()){long delay=PowerPolicy.lyricDelay(lines,highlighted,player.getCurrentPosition(),player.getPlaybackParameters().speed,manualUntil-SystemClock.uptimeMillis(),highlighted>=0&&lastScrolled!=highlighted);if(delay>=0)handler.postDelayed(this,delay);}
    }};
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        LinearLayout root = column(); Ui.background(root);
        root.setOnApplyWindowInsetsListener((v,i)->{root.setPadding(dp(20),dp(12)+i.getSystemWindowInsetTop(),dp(20),dp(12)+i.getSystemWindowInsetBottom());return i;});
        setContentView(root);
        Button back=button("‹ Biblioteca",v->finish());Ui.ghost(back);back.setGravity(Gravity.START|Gravity.CENTER_VERTICAL);root.addView(back);root.addView(Ui.eyebrow(this,"SINTA CADA VERSO"));
        heading = text("Letra da música", 27, Ui.TEXT);heading.setMaxLines(2); root.addView(heading);
        status = text("Conectando ao tocador…", 13, Ui.MUTED); root.addView(status);
        track = new EditText(this);track.setSingleLine(true);track.setTextColor(Color.WHITE);track.setHintTextColor(Ui.MUTED);track.setHint("Nome da música");track.setContentDescription("Nome da música para buscar letra");Ui.input(track);LinearLayout searchFields=new LinearLayout(this);LinearLayout.LayoutParams trackParams=new LinearLayout.LayoutParams(0,dp(52),1);trackParams.rightMargin=dp(8);searchFields.addView(track,trackParams);root.addView(searchFields);
        artist = new EditText(this);artist.setSingleLine(true);artist.setTextColor(Color.WHITE);artist.setHintTextColor(Ui.MUTED);artist.setHint("Artista");artist.setContentDescription("Artista para buscar letra");Ui.input(artist);searchFields.addView(artist,new LinearLayout.LayoutParams(0,dp(52),1));
        Button search=button("Buscar letra",v->load());LinearLayout.LayoutParams searchParams=new LinearLayout.LayoutParams(-1,dp(48));searchParams.topMargin=dp(8);root.addView(search,searchParams);
        translate=button("Traduzir letra",v->translationOptions());translate.setContentDescription("Traduzir letra no celular");translate.setEnabled(false);root.addView(translate,new LinearLayout.LayoutParams(-1,dp(48)));
        scroll = new ScrollView(this);linesView = column();scroll.addView(linesView);root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
        scroll.setOnTouchListener((v,e)->{manualUntil=SystemClock.uptimeMillis()+5000;lastScrolled=-1;if(e.getActionMasked()==android.view.MotionEvent.ACTION_UP||e.getActionMasked()==android.view.MotionEvent.ACTION_CANCEL)restartTick();return false;});
        play = button("Reproduzir",v->{if(player!=null&&player.getMediaItemCount()>0){if(player.isPlaying())player.pause();else player.play();}});Ui.primary(play);root.addView(play);
        root.addView(text("Letras: LRCLIB • título e artista são enviados para buscar.\nA disponibilidade e a sincronização variam por música.",11,Ui.MUTED));
        connection = new MediaController.Builder(this,new SessionToken(this,new ComponentName(this,PlaybackService.class))).setListener(new MediaController.Listener(){@Override public void onExtrasChanged(MediaController controller,Bundle extras){restartTick();}}).buildAsync();
        connection.addListener(()->{if(isDestroyed())return;try{player=connection.get();player.addListener(new Player.Listener(){@Override public void onEvents(Player p,Player.Events events){if(events.size()!=1||!events.contains(Player.EVENT_VOLUME_CHANGED))restartTick();}});if(screenStarted)followSong();restartTick();}catch(Exception e){status.setText("Não foi possível conectar. Volte e tente novamente.");}},handler::post);
    }
    private void restartTick(){handler.removeCallbacks(tick);if(screenStarted)handler.post(tick);}
    @Override protected void onStart(){super.onStart();screenStarted=true;restartTick();}
    @Override protected void onStop(){if(translator!=null||translationJob!=null)status.setText("Tradução interrompida ao sair da tela. Toque em Traduzir letra para retomar.");cancelTranslation();screenStarted=false;handler.removeCallbacks(tick);super.onStop();}
    private void followSong(){
        MediaItem item=player.getCurrentMediaItem();
        TrackIdentity identity=item==null?null:NowPlayingInfo.read(player);String currentTitle=item==null?"":identity.title.isEmpty()?String.valueOf(item.mediaMetadata.title):identity.title;String currentArtist=identity==null?"":identity.artist;String key=item==null?"":item.mediaId+"\n"+currentTitle+"\n"+currentArtist;
        if(item==null){if(!songKey.isEmpty()||generation==0){songKey="";generation++;clear();status.setText("Volte à biblioteca e escolha uma música.");}return;}
        if(!key.equals(songKey)){
            songKey=key;durationKnown=player.getDuration()>0;
            heading.setText(currentTitle);track.setText(currentTitle);
            String name=currentArtist;artist.setText(name.equals("Artista desconhecido")||name.equals("null")?"":name);
            load();
        }else if(!durationKnown&&player.getDuration()>0){durationKnown=true;load();}
    }
    private void clear(){cancelTranslation();originalLyrics=null;originalRows.clear();translationLabels.clear();translate.setEnabled(false);lines=Collections.emptyList();labels.clear();linesView.removeAllViews();highlighted=-1;lastScrolled=-1;manualUntil=0;scroll.scrollTo(0,0);}
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
        originalLyrics=result;lines=Lrc.parse(result.synced);translate.setEnabled(!lines.isEmpty()||!result.plain.trim().isEmpty());
        if(!lines.isEmpty()){
            status.setText("Letra sincronizada • toque em um verso para ir até ele");
            for(Lrc.Line line:lines){TextView label=text(line.text.isEmpty()?"♪":line.text,23,Ui.MUTED);label.setPadding(0,dp(14),0,dp(14));label.setOnClickListener(v->{if(player!=null)player.seekTo(line.ms);manualUntil=0;});linesView.addView(label);labels.add(label);}
            linesView.setPadding(0,dp(24),0,dp(160));
        }else if(!result.plain.trim().isEmpty()){
            status.setText("Letra disponível sem sincronização • role para acompanhar");
            TextView plain=text(result.plain,22,Color.WHITE);plain.setLineSpacing(dp(10),1);linesView.addView(plain);
        }else status.setText("Letra não encontrada. Confira título e artista.");
    }
    private void cancelTranslation(){translationGeneration++;if(translationJob!=null){translationJob.cancel();translationJob=null;}if(translator!=null){translator.close();translator=null;}}
    private void translationOptions(){
        if(originalLyrics==null)return;
        List<String> codes=new ArrayList<>(TranslateLanguage.getAllLanguages());Locale display=new Locale("pt","BR");codes.sort(Comparator.comparing(code->new Locale(code).getDisplayLanguage(display)));
        String[] names=new String[codes.size()];for(int i=0;i<codes.size();i++)names[i]=new Locale(codes.get(i)).getDisplayLanguage(display);
        LinearLayout content=column();content.setPadding(dp(20),dp(8),dp(20),dp(8));content.addView(text("Tradução automática no celular, sem cobrança por uso. Na primeira vez, baixa modelos de aproximadamente 30 MB por idioma. A letra precisa estar disponível; não transcreve o áudio cantado. Pode conter erros.",13,Ui.MUTED));
        content.addView(text("Idioma da letra original",14,Ui.TEXT));Spinner source=new Spinner(this);source.setAdapter(Ui.spinnerLabels(this,names));Ui.spinner(source);source.setSelection(Math.max(0,codes.indexOf(getPreferences(0).getString("translate_source","en"))));content.addView(source);
        content.addView(text("Traduzir para",14,Ui.TEXT));Spinner target=new Spinner(this);target.setAdapter(Ui.spinnerLabels(this,names));Ui.spinner(target);target.setSelection(Math.max(0,codes.indexOf(getPreferences(0).getString("translate_target","pt"))));content.addView(target);
        ScrollView settings=new ScrollView(this);settings.addView(content);
        new AlertDialog.Builder(this).setTitle("Traduzir letra").setView(settings).setPositiveButton("Usar Wi-Fi",(d,w)->beginTranslation(codes.get(source.getSelectedItemPosition()),codes.get(target.getSelectedItemPosition()),true)).setNeutralButton("Usar dados móveis",(d,w)->beginTranslation(codes.get(source.getSelectedItemPosition()),codes.get(target.getSelectedItemPosition()),false)).setNegativeButton("Cancelar",null).show();
    }
    private void beginTranslation(String source,String target,boolean wifi){
        if(originalLyrics==null)return;if(source.equals(target)){status.setText("Escolha idiomas diferentes para traduzir.");return;}
        cancelTranslation();final int token=translationGeneration;getPreferences(0).edit().putString("translate_source",source).putString("translate_target",target).apply();originalRows.clear();translationLabels.clear();
        if(!lines.isEmpty()){for(int i=0;i<lines.size();i++){originalRows.add(lines.get(i).text);translationLabels.add(labels.get(i));labels.get(i).setText(lines.get(i).text.isEmpty()?"♪":lines.get(i).text);}}
        else{linesView.removeAllViews();for(String row:originalLyrics.plain.split("\\r?\\n",-1)){originalRows.add(row);TextView label=text(row,22,Ui.TEXT);linesView.addView(label);translationLabels.add(label);}}
        status.setText(wifi?"Preparando idiomas • download inicial por Wi-Fi. A música continua tocando.":"Preparando idiomas • pode usar dados móveis. A música continua tocando.");
        try{translator=new LocalLyricTranslator(source,target);translator.prepare(wifi,()->{
            if(isDestroyed()||token!=translationGeneration||!screenStarted)return;status.setText("Traduzindo no celular • Google ML Kit • a música continua tocando");
            int active=player==null?-1:Lrc.active(lines,player.getCurrentPosition());
            translationJob=new LyricTranslation(originalRows,active,translator,new LyricTranslation.Listener(){
                public void row(int index,String value){if(isDestroyed()||token!=translationGeneration)return;translationLabels.get(index).setText(originalRows.get(index)+"\n"+value);}
                public void complete(){if(isDestroyed()||token!=translationGeneration)return;status.setText(lines.isEmpty()?"Tradução automática • Google ML Kit • sem sincronização na letra original":"Original e tradução sincronizados • tradução automática: Google ML Kit");if(translator!=null){translator.close();translator=null;}translationJob=null;restartTick();}
                public void failure(Exception error){translationFailed(token);}
            });translationJob.start();
        },error->translationFailed(token));}catch(Exception error){translationFailed(token);}
    }
    private void translationFailed(int token){if(isDestroyed()||token!=translationGeneration)return;cancelTranslation();status.setText("Não foi possível preparar a tradução. Confira a conexão para baixar os idiomas e tente novamente. A letra original foi mantida.");}
    private void style(TextView v,boolean current){v.setTextColor(current?Ui.CYAN:Ui.MUTED);v.setTypeface(null,current?Typeface.BOLD:Typeface.NORMAL);}
    private LinearLayout column(){LinearLayout l=new LinearLayout(this);l.setOrientation(LinearLayout.VERTICAL);return l;}
    private TextView text(String s,int size,int color){TextView t=Ui.text(this,s,size,color);t.setPadding(0,dp(6),0,dp(6));if(size>=24)Ui.bold(t);return t;}
    private Button button(String s,View.OnClickListener l){return Ui.button(this,s,l);}
    private int dp(int n){return Math.round(n*getResources().getDisplayMetrics().density);}
    @Override public void onDestroy(){cancelTranslation();generation++;if(request!=null)request.cancel(true);network.shutdownNow();handler.removeCallbacksAndMessages(null);if(connection!=null)MediaController.releaseFuture(connection);super.onDestroy();}
}
