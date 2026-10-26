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
    private final int green=Ui.CYAN, muted=Ui.MUTED;
    private final ArrayList<MediaItem> songs = new ArrayList<>();
    private final ExecutorService scanner = Executors.newSingleThreadExecutor();
    private final Handler handler = new Handler(Looper.getMainLooper());
    private MediaController player;
    private ListenableFuture<MediaController> connection;
    private LinearLayout rows,nowPanel,mainNavigation;
    private TextView status, title, artist, elapsed, total;
    private Button play, shuffle, repeat, favorite, allTab, favoritesTab, searchFilter;
    private final Map<String,View> rowViews=new HashMap<>();
    private String activeRowId="";
    private SeekBar seek;
    private EditText localSearch;
    private String query = "";
    private int searchScope = 0;
    private boolean onlyFavorites = false, seeking = false;
    private boolean screenStarted = false, libraryReady=false, keyboardVisible=false;
    private final VoiceAssistant voiceAssistant=new VoiceAssistant();
    private String pendingVoice;
    private MediaItem pendingAudio;private long pendingAudioPosition;private int audioRequest;
    private Set<String> favorites;
    private SharedPreferences prefs;
    private final Runnable progress = new Runnable() { public void run() {
        if (!screenStarted||keyboardVisible) return;
        if (player != null && !seeking) { seek.setProgress((int)player.getCurrentPosition()); elapsed.setText(time(player.getCurrentPosition())); }
        if (player != null && player.isPlaying()) handler.postDelayed(this, 1000);
    }};

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        prefs = getSharedPreferences("library", MODE_PRIVATE);
        favorites = new HashSet<>(prefs.getStringSet("favorites", Collections.emptySet()));
        LinearLayout root=column();Ui.background(root);
        root.setOnApplyWindowInsetsListener((v,insets)->{root.setPadding(dp(20),dp(12)+insets.getSystemWindowInsetTop(),dp(20),dp(12)+insets.getSystemWindowInsetBottom());return insets;});setContentView(root);
        LinearLayout topBar=new LinearLayout(this);topBar.setGravity(Gravity.CENTER_VERTICAL);topBar.addView(Ui.art(this,38,0));
        LinearLayout identity=column();TextView brand=Ui.text(this,"onda",27,Ui.TEXT);brand.setLetterSpacing(.08f);Ui.bold(brand);identity.addView(brand);TextView subbrand=Ui.text(this,"MEDIA PLAYER",9,muted);subbrand.setLetterSpacing(.18f);identity.addView(subbrand);
        LinearLayout.LayoutParams identityParams=new LinearLayout.LayoutParams(0,-2,1);identityParams.leftMargin=dp(10);topBar.addView(identity,identityParams);
        Button menu=Ui.menuButton(this,"Menu da biblioteca",this::showLibraryMenu);topBar.addView(menu,new LinearLayout.LayoutParams(dp(48),dp(48)));root.addView(topBar);
        LinearLayout section=new LinearLayout(this);section.setGravity(Gravity.CENTER_VERTICAL);TextView library=Ui.text(this,"Minhas músicas",24,Ui.TEXT);Ui.bold(library);section.addView(library,new LinearLayout.LayoutParams(0,-2,1));
        searchFilter=button("Filtrar",v->filter());Ui.ghost(searchFilter);searchFilter.setContentDescription("Filtrar busca no celular");section.addView(searchFilter,new LinearLayout.LayoutParams(dp(90),dp(48)));LinearLayout.LayoutParams sectionParams=new LinearLayout.LayoutParams(-1,dp(56));sectionParams.topMargin=dp(8);root.addView(section,sectionParams);
        LinearLayout searchRow=new LinearLayout(this);LinearLayout.LayoutParams searchParams=new LinearLayout.LayoutParams(-1,dp(50));searchParams.bottomMargin=dp(8);root.addView(searchRow,searchParams);
        EditText search=new EditText(this);localSearch=search;Ui.input(search);search.setHint("Buscar no celular");search.setContentDescription("Buscar música, artista ou álbum no celular");searchRow.addView(search,new LinearLayout.LayoutParams(0,-1,1));
        search.addTextChangedListener(new TextWatcher(){public void beforeTextChanged(CharSequence s,int st,int c,int a){}public void onTextChanged(CharSequence s,int st,int before,int count){query=s.toString();render();}public void afterTextChanged(Editable e){}});
        Button voice=Ui.voiceButton(this,"Busca por voz no celular",v->VoiceSearch.start(this,true));LinearLayout.LayoutParams voiceParams=new LinearLayout.LayoutParams(dp(48),-1);voiceParams.leftMargin=dp(8);searchRow.addView(voice,voiceParams);
        LinearLayout tabs=new LinearLayout(this);allTab=button("Todas",v->{onlyFavorites=false;render();});favoritesTab=button("Favoritas",v->{onlyFavorites=true;render();});
        LinearLayout.LayoutParams tabParams=new LinearLayout.LayoutParams(0,dp(48),1);tabParams.rightMargin=dp(8);tabs.addView(allTab,tabParams);tabs.addView(favoritesTab,new LinearLayout.LayoutParams(0,dp(48),1));
        root.addView(tabs);
        status=label("Preparando biblioteca…",12,muted);root.addView(status);
        ScrollView scroll=new ScrollView(this);scroll.setFillViewport(false);scroll.setClipToPadding(false);scroll.setPadding(0,dp(4),0,dp(6));rows=column();scroll.addView(rows);root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
        LinearLayout now=column();nowPanel=now;now.setPadding(dp(14),dp(12),dp(14),dp(8));Ui.playerCard(now);root.addView(now);
        now.addView(Ui.eyebrow(this,"TOCANDO AGORA"));
        LinearLayout songInfo=new LinearLayout(this);songInfo.setGravity(Gravity.CENTER_VERTICAL);songInfo.setMinimumHeight(dp(64));LinearLayout.LayoutParams songInfoParams=new LinearLayout.LayoutParams(-1,-2);songInfoParams.topMargin=dp(3);now.addView(songInfo,songInfoParams);songInfo.addView(Ui.art(this,44,0));
        LinearLayout metadata=column();title=Ui.text(this,"Selecione uma música",16,Ui.TEXT);Ui.bold(title);title.setMaxLines(1);title.setEllipsize(android.text.TextUtils.TruncateAt.END);metadata.addView(title);artist=Ui.text(this,"Sua trilha começa aqui",12,muted);artist.setMaxLines(1);artist.setEllipsize(android.text.TextUtils.TruncateAt.END);LinearLayout.LayoutParams artistParams=new LinearLayout.LayoutParams(-1,-2);artistParams.topMargin=dp(5);metadata.addView(artist,artistParams);LinearLayout.LayoutParams metadataParams=new LinearLayout.LayoutParams(0,-2,1);metadataParams.leftMargin=dp(10);metadataParams.rightMargin=dp(8);songInfo.addView(metadata,metadataParams);
        favorite=Ui.favoriteButton(this,v->toggleFavorite());favorite.setEnabled(false);songInfo.addView(favorite,new LinearLayout.LayoutParams(dp(48),dp(48)));
        seek=new SeekBar(this);seek.setContentDescription("Posição na música");now.addView(seek,new LinearLayout.LayoutParams(-1,dp(32)));seek.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener(){public void onProgressChanged(SeekBar b,int p,boolean u){if(u)elapsed.setText(time(p));}public void onStartTrackingTouch(SeekBar b){seeking=true;}public void onStopTrackingTouch(SeekBar b){if(player!=null)player.seekTo(b.getProgress());seeking=false;}});
        LinearLayout times=new LinearLayout(this);elapsed=Ui.text(this,"0:00",11,muted);total=Ui.text(this,"0:00",11,muted);total.setGravity(Gravity.END);times.addView(elapsed,new LinearLayout.LayoutParams(0,-2,1));times.addView(total,new LinearLayout.LayoutParams(0,-2,1));now.addView(times);
        LinearLayout controls=new LinearLayout(this);controls.setGravity(Gravity.CENTER_VERTICAL);
        shuffle=Ui.transport(this,"shuffle",v->{if(player!=null){player.setShuffleModeEnabled(!player.getShuffleModeEnabled());refresh();}});shuffle.setContentDescription("Alternar modo aleatório");
        Button previous=Ui.transport(this,"previous",v->{if(player!=null)player.seekToPrevious();});previous.setContentDescription("Música anterior");
        play=Ui.transport(this,"play",v->{if(player==null)return;if(player.isPlaying())player.pause();else if(player.getMediaItemCount()>0){if(player.getPlaybackState()==Player.STATE_ENDED)player.seekToDefaultPosition();player.prepare();player.play();}});play.setContentDescription("Reproduzir");
        Button next=Ui.transport(this,"next",v->{if(player!=null)player.seekToNext();});next.setContentDescription("Próxima música");
        repeat=Ui.transport(this,"repeat",v->{if(player!=null){player.setRepeatMode((player.getRepeatMode()+1)%3);refresh();}});repeat.setContentDescription("Alternar repetição");
        for(Button b:new Button[]{shuffle,previous,play,next,repeat}){LinearLayout.LayoutParams params=new LinearLayout.LayoutParams(0,dp(56),1);if(b==play){FrameLayout holder=new FrameLayout(this);holder.addView(b,new FrameLayout.LayoutParams(dp(52),dp(52),Gravity.CENTER));controls.addView(holder,params);}else controls.addView(b,params);}LinearLayout.LayoutParams controlsParams=new LinearLayout.LayoutParams(-1,dp(60));controlsParams.topMargin=dp(4);now.addView(controls,controlsParams);
        mainNavigation=Ui.navigation(this,0);root.addView(mainNavigation);
        root.getViewTreeObserver().addOnGlobalLayoutListener(()->{android.graphics.Rect frame=new android.graphics.Rect();root.getWindowVisibleDisplayFrame(frame);boolean visible=root.getRootView().getHeight()-frame.bottom>dp(150);if(visible==keyboardVisible)return;keyboardVisible=visible;nowPanel.setVisibility(visible?View.GONE:View.VISIBLE);mainNavigation.setVisibility(visible?View.GONE:View.VISIBLE);restartProgress();});
        connection=new MediaController.Builder(this,new SessionToken(this,new ComponentName(this,PlaybackService.class))).buildAsync();
        connection.addListener(()->{try{player=connection.get();player.addListener(new Player.Listener(){@Override public void onEvents(Player p,Player.Events e){if(e.size()!=1||!e.contains(Player.EVENT_VOLUME_CHANGED))refresh();}@Override public void onPlayerError(PlaybackException e){new AlertDialog.Builder(MainActivity.this).setTitle("Não foi possível tocar").setMessage("O arquivo pode estar indisponível ou usar um codec incompatível com este aparelho. Tente outra música.").setPositiveButton("OK",null).show();}});refresh();playExternal();if(pendingVoice!=null&&libraryReady){String phrase=pendingVoice;pendingVoice=null;handleVoice(phrase);}}catch(Exception e){status.setText("Falha ao conectar o tocador. Feche e abra o app.");}},handler::post);
        pendingVoice=getIntent().getStringExtra("voice_phrase");if(!receiveAudio(getIntent()))permission();
    }
    @Override protected void onActivityResult(int request,int result,Intent data){super.onActivityResult(request,result,data);if(request==VoiceSearch.REQUEST){String phrase=VoiceSearch.result(result,data);if(!phrase.isEmpty()){handleVoice(phrase);}}}
    @Override protected void onNewIntent(Intent intent){super.onNewIntent(intent);setIntent(intent);receiveAudio(intent);String phrase=intent.getStringExtra("voice_phrase");if(phrase!=null)handleVoice(phrase);}
    private void handleVoice(String phrase){
        if(player==null||!libraryReady){pendingVoice=phrase;return;}
        voiceAssistant.interpret(this,phrase,this::handleVoiceCommand);
    }
    private void handleVoiceCommand(VoiceCommand command){
        if(VoiceControl.execute(this,player,command))return;
        if(command.action==VoiceCommand.Action.FAVORITE_ADD||command.action==VoiceCommand.Action.FAVORITE_REMOVE){
            MediaItem current=player.getCurrentMediaItem();boolean local=false;
            if(current!=null)for(MediaItem item:songs)if(item.mediaId.equals(current.mediaId)){local=true;break;}
            if(!local){VoiceControl.say(this,"Escolha uma música do celular primeiro.");return;}
            if(command.action==VoiceCommand.Action.FAVORITE_ADD)favorites.add(current.mediaId);else favorites.remove(current.mediaId);
            prefs.edit().putStringSet("favorites",new HashSet<>(favorites)).apply();refresh();render();
            VoiceControl.say(this,command.action==VoiceCommand.Action.FAVORITE_ADD?"Música adicionada às favoritas":"Música removida das favoritas");return;
        }
        onlyFavorites=command.action==VoiceCommand.Action.FAVORITES;searchScope=0;
        localSearch.setText(onlyFavorites?"":command.query);render();
        if(command.action==VoiceCommand.Action.PLAY_QUERY||onlyFavorites){
            ArrayList<MediaItem> queue=new ArrayList<>();for(MediaItem item:songs)if((!onlyFavorites||favorites.contains(item.mediaId))&&SearchText.matches(item.mediaMetadata.title+" "+item.mediaMetadata.artist+" "+item.mediaMetadata.albumTitle,query))queue.add(item);
            if(queue.isEmpty()){VoiceControl.say(this,onlyFavorites?"Você ainda não tem músicas favoritas disponíveis. Toque uma música do celular e diga: adicione aos favoritos.":"Nenhuma música encontrada no celular.");return;}player.setMediaItems(queue);player.prepare();player.play();
        }
    }
    private void showLibraryMenu(View anchor){Ui.menu(this,anchor,
        new String[]{"Downloads","Backup e restauração","Playlists","Fila de reprodução","DJ Pessoal","Ajustar sessão","Estúdio de som","Fones e Bluetooth","Coleções inteligentes","Letra da música","Temporizador","Recarregar biblioteca","Atualizações","Comandos de voz","Assistente com IA","Leitor de PDF","Meu espaço","Minhas frases"},
        new String[]{"Downloads","Backup e restauração","Playlists","Fila de reprodução","DJ Pessoal","Ajustar sessão","Estúdio de som","Fones e Bluetooth","Onda Lab","Ver letra da música","Temporizador","Reler arquivos do celular","Atualizações","Comandos de voz","Assistente com IA","Leitor de PDF","Continuar e coleções","Minhas frases"},
        new Runnable[]{()->startActivity(new Intent(this,DownloadsActivity.class)),()->startActivity(new Intent(this,BackupActivity.class)),()->startActivity(new Intent(this,PlaylistsActivity.class)),()->startActivity(new Intent(this,QueueActivity.class)),()->startActivity(new Intent(this,DjActivity.class)),()->DjControls.show(this,player),()->startActivity(new Intent(this,SoundActivity.class)),()->startActivity(new Intent(this,AudioOutputActivity.class)),()->startActivity(new Intent(this,SmartLibraryActivity.class)),this::lyrics,this::sleep,this::permission,()->startActivity(new Intent(this,UpdateActivity.class)),()->VoiceSearch.help(this),()->VoiceAiSettings.show(this),()->startActivity(new Intent(this,PdfActivity.class)),this::openShelf,()->startActivity(new Intent(this,VoicePhrasesActivity.class))});}
    private void openShelf(){if(player!=null){MediaItem item=player.getCurrentMediaItem();if(DjSession.deviceAudio(item)&&item.localConfiguration!=null)ShelfStore.remember(this,"audio",item.localConfiguration.uri.toString(),String.valueOf(item.mediaMetadata.title),Math.max(0,player.getCurrentPosition()),Math.max(player.getDuration(),LibraryStore.number(item,"durationMs")));}startActivity(new Intent(this,ShelfActivity.class));}
    private void lyrics(){if(player==null||player.getCurrentMediaItem()==null){Toast.makeText(this,"Escolha uma música primeiro",Toast.LENGTH_SHORT).show();return;}if(player.getCurrentMediaItem().mediaId.startsWith("catalog:")){Toast.makeText(this,"As letras não são sincronizadas para prévias.",Toast.LENGTH_SHORT).show();return;}startActivity(new Intent(this,LyricsActivity.class));}
    private void filter(){String[] fields={"Todos os campos","Música","Artista","Álbum"};new AlertDialog.Builder(this).setTitle("Buscar por").setSingleChoiceItems(fields,searchScope,(dialog,which)->{searchScope=which;render();dialog.dismiss();}).setNegativeButton("Fechar",null).show();}
    private boolean receiveAudio(Intent intent){
        Uri uri=intent.getData();if(!Intent.ACTION_VIEW.equals(intent.getAction())||uri==null||(!"content".equalsIgnoreCase(uri.getScheme())&&!"file".equalsIgnoreCase(uri.getScheme())))return false;
        int request=++audioRequest;long startPosition=Math.max(0,intent.getLongExtra("onda_start_ms",0));pendingAudio=null;libraryReady=true;status.setText("Abrindo áudio…");
        try{if((intent.getFlags()&Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)!=0)getContentResolver().takePersistableUriPermission(uri,Intent.FLAG_GRANT_READ_URI_PERMISSION);}catch(RuntimeException ignored){}
        scanner.execute(()->{try{MediaItem item=ExternalAudio.read(this,uri,intent.getType());handler.post(()->{if(isDestroyed()||request!=audioRequest)return;pendingAudio=item;long length=LibraryStore.number(item,"durationMs");pendingAudioPosition=length>0?Math.min(startPosition,Math.max(0,length-500)):startPosition;songs.removeIf(s->s.mediaId.equals(item.mediaId));songs.add(item);render();playExternal();});}catch(Exception e){handler.post(()->{if(!isDestroyed()&&request==audioRequest)status.setText("Não foi possível abrir o áudio. Selecione o arquivo novamente no gerenciador.");});}});return true;
    }
    private void playExternal(){if(player==null||pendingAudio==null)return;MediaItem item=pendingAudio;pendingAudio=null;VideoBackgroundService.stopForMusic(this);player.setMediaItem(item,pendingAudioPosition);player.prepare();player.play();refresh();}
    private void permission(){String p=Build.VERSION.SDK_INT>=33?Manifest.permission.READ_MEDIA_AUDIO:Manifest.permission.READ_EXTERNAL_STORAGE;if(checkSelfPermission(p)==PackageManager.PERMISSION_GRANTED)scan();else requestPermissions(new String[]{p},10);}
    @Override public void onRequestPermissionsResult(int code,String[] p,int[] results){super.onRequestPermissionsResult(code,p,results);if(code==10&&results.length>0&&results[0]==PackageManager.PERMISSION_GRANTED)scan();else{status.setText("Permita acesso às músicas para abrir sua biblioteca.");rows.removeAllViews();Button settings=button("Abrir configurações",v->startActivity(new Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,Uri.parse("package:"+getPackageName()))));rows.addView(settings);}}
    private void scan(){status.setText("Buscando músicas no celular…");scanner.execute(()->{ArrayList<MediaItem> found=new ArrayList<>();String error=null;
        try{found.addAll(LibraryStore.scan(this));}catch(Exception e){error="Não foi possível ler a biblioteca. Verifique a permissão e tente atualizar.";}
        String message=error;runOnUiThread(()->{if(isDestroyed())return;songs.clear();songs.addAll(found);libraryReady=true;render();if(pendingVoice!=null&&player!=null){String phrase=pendingVoice;pendingVoice=null;handleVoice(phrase);}if(message!=null)status.setText(message);});});}
    private void render(){
        if(rows==null)return;DownloadedAudio.merge(this,songs);searchFilter.setText(new String[]{"Filtrar","Música","Artista","Álbum"}[searchScope]);Ui.chip(searchFilter,searchScope!=0);rows.removeAllViews();rowViews.clear();activeRowId="";Ui.chip(allTab,!onlyFavorites);Ui.chip(favoritesTab,onlyFavorites);
        ArrayList<MediaItem> visible=new ArrayList<>();
        for(MediaItem item:songs){
            MediaMetadata m=item.mediaMetadata;
            CharSequence text=searchScope==1?m.title:searchScope==2?m.artist:searchScope==3?m.albumTitle:m.title+" "+m.artist+" "+m.albumTitle;
            if(SearchText.matches(text,query)&&(!onlyFavorites||favorites.contains(item.mediaId)))visible.add(item);
        }
        for(MediaItem item:visible){MediaMetadata m=item.mediaMetadata;
            LinearLayout row=Ui.result(this,String.valueOf(m.title),String.valueOf(m.artist),item.mediaId.hashCode(),v->{if(player==null){Toast.makeText(this,"Tocador iniciando…",Toast.LENGTH_SHORT).show();return;}player.setMediaItems(new ArrayList<>(visible),visible.indexOf(item),0);player.prepare();player.play();});
            row.setOnLongClickListener(v->{if(player==null)return true;new AlertDialog.Builder(this).setTitle(String.valueOf(m.title)).setItems(new String[]{"Colocar como próxima","Adicionar ao fim da fila"},(d,which)->QueueEdit.add(this,player,item,which==0)).setNegativeButton("Cancelar",null).show();return true;});
            row.setContentDescription("Tocar "+m.title+", "+m.artist);rows.addView(row);rowViews.put(item.mediaId,row);
        }
        highlightCurrentRow();
        int count=visible.size();status.setText(count+" de "+songs.size()+" músicas no celular"+(onlyFavorites?" • favoritas":""));
        if(count==0)rows.addView(label(songs.isEmpty()?"Sua biblioteca está vazia.\nCopie músicas para a pasta Music do celular e toque em Atualizar.":"Nenhuma música encontrada. Tente outro nome ou ajuste o filtro.",16,muted));
    }
    private void refresh(){if(!screenStarted||player==null)return;MediaItem item=player.getCurrentMediaItem();favorite.setEnabled(item!=null);if(item!=null){title.setText(item.mediaMetadata.title);artist.setText(item.mediaMetadata.artist);favorite.setSelected(favorites.contains(item.mediaId));favorite.setTextColor(favorites.contains(item.mediaId)?Ui.CYAN:Ui.MUTED);favorite.setContentDescription(favorites.contains(item.mediaId)?"Remover dos favoritos":"Adicionar aos favoritos");}else{title.setText("Selecione uma música");artist.setText("Sua trilha começa aqui");favorite.setSelected(false);favorite.setTextColor(Ui.MUTED);favorite.setContentDescription("Adicionar aos favoritos");}play.setText(player.isPlaying()?"❚❚":"▶");play.setContentDescription(player.isPlaying()?"Pausar":"Reproduzir");shuffle.setTextColor(player.getShuffleModeEnabled()?green:muted);repeat.setText(player.getRepeatMode()==Player.REPEAT_MODE_ONE?"↻ 1":"↻");repeat.setTextColor(player.getRepeatMode()!=Player.REPEAT_MODE_OFF?green:muted);long duration=player.getDuration();if(duration<=0&&item!=null)duration=LibraryStore.number(item,"durationMs");seek.setMax(duration>0?(int)Math.min(Integer.MAX_VALUE,duration):0);total.setText(time(duration));highlightCurrentRow();restartProgress();}
    private void toggleFavorite(){if(player==null||player.getCurrentMediaItem()==null)return;String id=player.getCurrentMediaItem().mediaId;if(!favorites.remove(id))favorites.add(id);prefs.edit().putStringSet("favorites",new HashSet<>(favorites)).apply();refresh();render();}
    private void sleep(){String[] options={"Desativar","15 minutos","30 minutos","60 minutos","120 minutos","Ao terminar esta música","Após 3 músicas","Após 5 músicas"};int[] mins={0,15,30,60,120};new AlertDialog.Builder(this).setTitle("Parar reprodução após…").setItems(options,(dialog,which)->{if(player==null)return;Bundle args=new Bundle();if(which>=5){if(player.getMediaItemCount()==0||player.getPlaybackState()==Player.STATE_ENDED){Toast.makeText(this,"Escolha uma música primeiro",Toast.LENGTH_SHORT).show();return;}args.putInt("tracks",which==5?1:which==6?3:5);}else args.putInt("minutes",mins[which]);player.sendCustomCommand(new SessionCommand("sleep",Bundle.EMPTY),args);Toast.makeText(this,which>=5?"A reprodução vai pausar após "+(which==5?1:which==6?3:5)+" música(s) concluída(s)":which==0?"Temporizador desativado":"A música vai pausar em "+mins[which]+" minutos",Toast.LENGTH_SHORT).show();}).show();}
    private LinearLayout column(){LinearLayout v=new LinearLayout(this);v.setOrientation(LinearLayout.VERTICAL);return v;}
    private TextView label(String text,int size,int color){TextView t=Ui.text(this,text,size,color);t.setPadding(0,dp(6),0,dp(6));return t;}
    private Button button(String text,View.OnClickListener listener){return Ui.button(this,text,listener);}
    private void highlightCurrentRow(){String id=player!=null&&player.getCurrentMediaItem()!=null?player.getCurrentMediaItem().mediaId:"";if(id.equals(activeRowId))return;View old=rowViews.get(activeRowId);if(old!=null)Ui.card(old,false);View selected=rowViews.get(id);if(selected!=null)Ui.card(selected,true);activeRowId=id;}
    private int dp(int n){return Math.round(n*getResources().getDisplayMetrics().density);}
    private String time(long ms){long s=Math.max(0,ms)/1000;return String.format(Locale.ROOT,"%d:%02d",s/60,s%60);}
    private void restartProgress(){handler.removeCallbacks(progress);if(screenStarted&&!keyboardVisible)handler.post(progress);}
    @Override protected void onStart(){super.onStart();screenStarted=true;Set<String> latest=new HashSet<>(prefs.getStringSet("favorites",Collections.emptySet()));boolean changed=!latest.equals(favorites);favorites=latest;render();refresh();restartProgress();}
    @Override protected void onStop(){screenStarted=false;handler.removeCallbacks(progress);super.onStop();}
    @Override public void onDestroy(){handler.removeCallbacksAndMessages(null);scanner.shutdownNow();if(connection!=null)MediaController.releaseFuture(connection);super.onDestroy();}
}
