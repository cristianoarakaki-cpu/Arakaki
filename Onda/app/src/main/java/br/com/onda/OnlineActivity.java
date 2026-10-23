package br.com.onda;

import android.app.Activity;
import android.content.*;
import android.graphics.Color;
import android.os.*;
import android.text.*;
import android.view.*;
import android.view.inputmethod.InputMethodManager;
import android.widget.*;
import androidx.media3.common.*;
import androidx.media3.session.MediaController;
import androidx.media3.session.SessionToken;
import com.google.common.util.concurrent.ListenableFuture;
import org.json.JSONArray;
import java.util.*;
import java.util.concurrent.*;

@androidx.media3.common.util.UnstableApi
public class OnlineActivity extends Activity {
    private final Handler handler=new Handler(Looper.getMainLooper());
    private final ExecutorService worker=Executors.newFixedThreadPool(2);
    private Future<?> request;
    private ListenableFuture<MediaController> connection;
    private MediaController player;
    private AutoCompleteTextView query;
    private EditText trackFilter;
    private Spinner mode, ordering, source;
    private TextView sourceLabel, sourceFooter;
    private Button storeButton;
    private TextView status, playing;
    private LinearLayout results, filterPanel;
    private Button pause;
    private int generation=0, page=1, activeMode=0, activeSort=0, activeSource=OnlineRepository.CATALOG;
    private String activeQuery="";
    private OnlineRepository.Page savedPage;
    private OnlineRepository.Show currentShow;
    private List<OnlineRepository.Track> showTracks=Collections.emptyList();
    private final int green=Ui.CYAN, muted=Ui.MUTED;
    @Override public void onCreate(Bundle state){
        super.onCreate(state);
        LinearLayout root=column();Ui.background(root);
        root.setOnApplyWindowInsetsListener((v,i)->{root.setPadding(dp(20),dp(12)+i.getSystemWindowInsetTop(),dp(20),dp(12)+i.getSystemWindowInsetBottom());return i;});setContentView(root);
        LinearLayout header=new LinearLayout(this);header.setGravity(Gravity.CENTER_VERTICAL);header.addView(text("Explorar",27,Color.WHITE),new LinearLayout.LayoutParams(0,-2,1));Button menu=Ui.menuButton(this,"Menu de explorar",v->Ui.menu(this,v,new String[]{"Fontes e filtros","Letra da música"},new String[]{"Fontes e filtros","Ver letra da música"},new Runnable[]{this::toggleFilters,this::lyrics}));header.addView(menu,new LinearLayout.LayoutParams(dp(48),dp(48)));root.addView(header);
        sourceLabel=text("Músicas e artistas • prévias do catálogo",13,muted);root.addView(sourceLabel);
        query=new AutoCompleteTextView(this);query.setThreshold(1);query.setSingleLine(true);query.setTextColor(Color.WHITE);query.setHintTextColor(muted);query.setHint("Nome da música ou artista");query.setContentDescription("Buscar no acervo online");query.setImeOptions(android.view.inputmethod.EditorInfo.IME_ACTION_SEARCH);query.setOnEditorActionListener((v,id,event)->{if(id==android.view.inputmethod.EditorInfo.IME_ACTION_SEARCH){search();return true;}return false;});Ui.input(query);LinearLayout.LayoutParams queryParams=new LinearLayout.LayoutParams(-1,dp(52));queryParams.setMargins(0,dp(8),0,dp(8));LinearLayout queryRow=new LinearLayout(this);queryRow.addView(query,new LinearLayout.LayoutParams(0,-1,1));Button voice=Ui.voiceButton(this,"Busca por voz na internet",v->VoiceSearch.start(this,false));LinearLayout.LayoutParams voiceParams=new LinearLayout.LayoutParams(dp(48),-1);voiceParams.leftMargin=dp(8);queryRow.addView(voice,voiceParams);root.addView(queryRow,queryParams);updateSuggestions();
        filterPanel=column();filterPanel.setVisibility(View.GONE);root.addView(filterPanel);LinearLayout filters=new LinearLayout(this);
        mode=spinner(new String[]{"Tudo", "Artista", "Música"},"Tipo de busca online");
        source=spinner(new String[]{"Catálogo • prévias", "Shows completos"},"Fonte da busca online");
        ordering=spinner(new String[]{"Relevância", "Mais populares", "Shows recentes"},"Ordenar resultados");
        LinearLayout.LayoutParams modeParams=new LinearLayout.LayoutParams(0,dp(48),1);modeParams.rightMargin=dp(8);filters.addView(source,modeParams);filters.addView(mode,new LinearLayout.LayoutParams(0,dp(48),1));filterPanel.addView(filters);ordering.setVisibility(View.GONE);filterPanel.addView(ordering,new LinearLayout.LayoutParams(-1,dp(48)));
        source.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener(){public void onItemSelected(AdapterView<?> p,View v,int position,long id){ordering.setVisibility(position==OnlineRepository.LIVE?View.VISIBLE:View.GONE);sourceLabel.setText(position==OnlineRepository.LIVE?"Shows ao vivo • Internet Archive":"Músicas e artistas • prévias do catálogo");}public void onNothingSelected(AdapterView<?> p){}});
        sourceLabel.setOnClickListener(v->toggleFilters());sourceLabel.setContentDescription("Fontes e filtros da busca online");
        Button submit=button("Buscar online  ↗",v->search());Ui.primary(submit);submit.setGravity(Gravity.CENTER);LinearLayout.LayoutParams submitParams=new LinearLayout.LayoutParams(-1,dp(48));submitParams.setMargins(0,dp(10),0,dp(4));root.addView(submit,submitParams);
        status=text("Encontre músicas e artistas. As prévias são trechos; shows completos ficam na outra fonte.",13,muted);root.addView(status);
        trackFilter=new EditText(this);trackFilter.setSingleLine(true);trackFilter.setTextColor(Color.WHITE);trackFilter.setHintTextColor(muted);trackFilter.setHint("Buscar faixa neste show");trackFilter.setContentDescription("Filtrar faixas do show pelo nome");Ui.input(trackFilter);trackFilter.setVisibility(View.GONE);root.addView(trackFilter);
        trackFilter.addTextChangedListener(new TextWatcher(){public void beforeTextChanged(CharSequence s,int st,int c,int a){}public void afterTextChanged(Editable e){}public void onTextChanged(CharSequence s,int st,int before,int count){if(currentShow!=null)renderTracks();}});
        ScrollView scroll=new ScrollView(this);results=column();scroll.addView(results);root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));LinearLayout emptyState=column();emptyState.setGravity(Gravity.CENTER);emptyState.setPadding(0,dp(24),0,dp(16));emptyState.addView(Ui.art(this,76,0));TextView emptyTitle=text("Encontre sua música",20,Ui.TEXT);Ui.bold(emptyTitle);emptyTitle.setGravity(Gravity.CENTER);emptyState.addView(emptyTitle);TextView emptyDetail=text("Busque pelo nome ou toque no microfone.",13,muted);emptyDetail.setGravity(Gravity.CENTER);emptyState.addView(emptyDetail);results.addView(emptyState,new LinearLayout.LayoutParams(-1,-2));
        playing=text("Escolha uma faixa para ouvir no Onda.",14,green);LinearLayout miniPlayer=column();miniPlayer.setPadding(dp(14),dp(10),dp(14),dp(8));Ui.playerCard(miniPlayer);miniPlayer.addView(Ui.eyebrow(this,"TOCANDO AGORA"));miniPlayer.addView(playing);root.addView(miniPlayer);
        LinearLayout controls=new LinearLayout(this);pause=button("Reproduzir",v->{if(player!=null&&player.getMediaItemCount()>0){if(player.isPlaying())player.pause();else{player.prepare();player.play();}}});controls.addView(pause,new LinearLayout.LayoutParams(0,dp(48),1));controls.addView(button("Próxima",v->{if(player!=null)player.seekToNext();}),new LinearLayout.LayoutParams(0,dp(48),1));Ui.primary(pause);pause.setGravity(Gravity.CENTER);miniPlayer.addView(controls);
        storeButton=button("Abrir música completa no Apple Music  ↗",v->openStore());storeButton.setVisibility(View.GONE);root.addView(storeButton);
        sourceFooter=text("Prévias: Apple Music / iTunes • sem download offline.\nA disponibilidade varia por música e região.",11,muted);root.addView(sourceFooter);root.addView(Ui.navigation(this,2));
        connection=new MediaController.Builder(this,new SessionToken(this,new ComponentName(this,PlaybackService.class))).buildAsync();
        connection.addListener(()->{if(isDestroyed())return;try{player=connection.get();player.addListener(new Player.Listener(){@Override public void onEvents(Player p,Player.Events e){if(e.size()!=1||!e.contains(Player.EVENT_VOLUME_CHANGED))refresh();}@Override public void onPlayerError(PlaybackException e){status.setText("Falha ao reproduzir. Verifique a internet ou escolha outra faixa.");}});refresh();}catch(Exception e){status.setText("Não foi possível conectar ao tocador. Volte e tente novamente.");}},handler::post);
    }
    private void toggleFilters(){filterPanel.setVisibility(filterPanel.getVisibility()==View.VISIBLE?View.GONE:View.VISIBLE);}
    private void lyrics(){if(player==null||player.getCurrentMediaItem()==null){Toast.makeText(this,"Escolha uma música primeiro.",Toast.LENGTH_SHORT).show();return;}if(player.getCurrentMediaItem().mediaId.startsWith("catalog:")){Toast.makeText(this,"As letras não são sincronizadas para prévias.",Toast.LENGTH_SHORT).show();return;}startActivity(new Intent(this,LyricsActivity.class));}
    private Spinner spinner(String[] labels,String description){Spinner s=new Spinner(this);s.setAdapter(new ArrayAdapter<>(this,R.layout.spinner_item,labels));s.setContentDescription(description);Ui.spinner(s);return s;}
    private int startRequest(){if(request!=null)request.cancel(true);results.removeAllViews();return ++generation;}
    private void search(){
        String input=query.getText().toString().trim();if(SearchText.catalogTerm(input).length()<2){status.setText("Digite pelo menos duas letras para buscar.");return;}
        ((InputMethodManager)getSystemService(INPUT_METHOD_SERVICE)).hideSoftInputFromWindow(query.getWindowToken(),0);query.dismissDropDown();
        activeQuery=input;activeMode=mode.getSelectedItemPosition();activeSort=ordering.getSelectedItemPosition();activeSource=source.getSelectedItemPosition();savedPage=null;saveRecent(input);loadPage(1);
    }
    private void loadPage(int number){
        int id=startRequest();currentShow=null;trackFilter.setVisibility(View.GONE);status.setText((activeSource==OnlineRepository.CATALOG?"Buscando músicas":"Buscando shows")+" • página "+number+"…");
        final String term=activeQuery;final int searchMode=activeMode, sort=activeSort, searchSource=activeSource;
        request=worker.submit(()->{try{OnlineRepository.Page found=OnlineRepository.search(term,searchMode,sort,number,searchSource);handler.post(()->{if(isDestroyed()||id!=generation)return;page=number;savedPage=found;renderPage();});}catch(Exception e){handler.post(()->{if(isDestroyed()||id!=generation)return;status.setText("Não foi possível consultar o serviço. "+e.getMessage()+" Verifique a internet e tente novamente.");results.addView(button("Tentar novamente",v->loadPage(number)));});}});
    }
    private void renderPage(){
        currentShow=null;trackFilter.setVisibility(View.GONE);results.removeAllViews();if(savedPage==null)return;
        status.setText(savedPage.shows.isEmpty()?(savedPage.catalog?"Nenhuma prévia encontrada neste catálogo. Tente outro nome de música ou artista.":"Nenhum show disponível para essa busca. Tente a fonte Catálogo • prévias."):savedPage.total+(savedPage.catalog?" prévias encontradas":" shows encontrados")+" • página "+page+(savedPage.broadened?" • busca ampliada":""));
        for(OnlineRepository.Show show:savedPage.shows){LinearLayout row=Ui.result(this,show.isPreview()?show.title:show.artist,show.isPreview()?show.artist+" • PRÉVIA":show.title,show.id.hashCode(),v->{if(show.isPreview())preview(show);else open(show);});row.setContentDescription(show.isPreview()?"Ouvir prévia de "+show.title+", "+show.artist:"Abrir show de "+show.artist);results.addView(row);}
        if(page>1)results.addView(button("‹ Página anterior",v->loadPage(page-1)));
        if(page*20<savedPage.total&&!savedPage.shows.isEmpty())results.addView(button("Mais resultados ›",v->loadPage(page+1)));
    }
    private void open(OnlineRepository.Show show){
        int id=startRequest();currentShow=null;trackFilter.setVisibility(View.GONE);status.setText("Carregando faixas: "+show.title);
        request=worker.submit(()->{try{List<OnlineRepository.Track> tracks=OnlineRepository.tracks(show);handler.post(()->{if(isDestroyed()||id!=generation)return;showTracks=tracks;currentShow=show;trackFilter.setVisibility(View.VISIBLE);trackFilter.setText(activeMode==2?activeQuery:"");renderTracks();});}catch(Exception e){handler.post(()->{if(isDestroyed()||id!=generation)return;status.setText("Falha ao abrir o show. Verifique a internet.");results.addView(button("Tentar novamente",v->open(show)));results.addView(button("‹ Voltar aos resultados",v->renderPage()));});}});
    }
    private void renderTracks(){
        if(currentShow==null)return;results.removeAllViews();results.addView(button("‹ Voltar aos resultados",v->renderPage()));
        final OnlineRepository.Show show=currentShow;
        final ArrayList<MediaItem> queue=new ArrayList<>();
        for(OnlineRepository.Track t:showTracks)queue.add(new MediaItem.Builder().setMediaId("archive:"+t.url).setUri(t.url).setMediaMetadata(new MediaMetadata.Builder().setTitle(t.title).setArtist(show.artist).setAlbumTitle(show.title).build()).build());
        int found=0;for(int index=0;index<showTracks.size();index++){if(!SearchText.matches(showTracks.get(index).title,trackFilter.getText().toString()))continue;found++;final int position=index;results.addView(Ui.result(this,showTracks.get(index).title,"Faixa "+(index+1)+" • "+show.artist,index,v->{if(player==null){status.setText("Tocador iniciando. Tente novamente em instantes.");return;}player.setMediaItems(queue,position,0);player.prepare();player.play();refresh();}));}
        status.setText(show.artist+" • "+found+" de "+showTracks.size()+" faixas\n"+show.title);
        if(showTracks.isEmpty())results.addView(text("Este show não tem faixas MP3 disponíveis. Tente outro resultado.",15,muted));
        else if(found==0){results.addView(text("Nenhuma faixa com esse nome. O termo pode estar apenas na descrição do show.",15,muted));results.addView(button("Mostrar todas as faixas",v->trackFilter.setText("")));}
    }
    private List<String> recent(){ArrayList<String> values=new ArrayList<>();try{JSONArray array=new JSONArray(getSharedPreferences("online-search",MODE_PRIVATE).getString("recent","[]"));for(int i=0;i<array.length();i++)values.add(array.getString(i));}catch(Exception ignored){}return values;}
    private void updateSuggestions(){query.setAdapter(new ArrayAdapter<>(this,android.R.layout.simple_dropdown_item_1line,recent()));}
    private void saveRecent(String input){List<String> values=recent();values.removeIf(v->SearchText.normalize(v).equals(SearchText.normalize(input)));values.add(0,input);while(values.size()>8)values.remove(values.size()-1);getSharedPreferences("online-search",MODE_PRIVATE).edit().putString("recent",new JSONArray(values).toString()).apply();updateSuggestions();}
    private void preview(OnlineRepository.Show track){
        if(player==null){status.setText("Tocador iniciando. Tente novamente.");return;}
        Bundle info=new Bundle();info.putBoolean("preview",true);info.putString("storeUrl",track.storeUrl);
        MediaItem item=new MediaItem.Builder().setMediaId("catalog:"+track.id).setUri(track.previewUrl).setMediaMetadata(new MediaMetadata.Builder().setTitle(track.title+" (prévia)").setArtist(track.artist).setAlbumTitle(track.album).setExtras(info).build()).build();
        player.setMediaItem(item);player.prepare();player.play();status.setText("Prévia de "+track.title+" • para a faixa completa, use o link do Apple Music.");refresh();
    }
    private void openStore(){if(player==null||player.getCurrentMediaItem()==null)return;Bundle extras=player.getCurrentMediaItem().mediaMetadata.extras;String url=extras==null?"":extras.getString("storeUrl","");if(!OnlineRepository.allowedStore(url))return;try{startActivity(new Intent(Intent.ACTION_VIEW,android.net.Uri.parse(url)));}catch(ActivityNotFoundException e){Toast.makeText(this,"Não foi possível abrir o link neste celular.",Toast.LENGTH_SHORT).show();}}
    private void refresh(){if(player==null)return;MediaItem item=player.getCurrentMediaItem();playing.setText(item==null?"Escolha uma faixa para ouvir.":item.mediaMetadata.title+" • "+item.mediaMetadata.artist);pause.setText(player.isPlaying()?"Pausar":"Reproduzir");boolean preview=item!=null&&item.mediaId.startsWith("catalog:");storeButton.setVisibility(preview?View.VISIBLE:View.GONE);sourceFooter.setText(preview?"Prévia promocional • Apple Music / iTunes.\nA faixa completa está no link acima.":"Catálogo: prévias do Apple Music / iTunes.\nShows completos: Internet Archive • usa internet.");}
    @Override protected void onActivityResult(int request,int result,Intent data){super.onActivityResult(request,result,data);if(request==VoiceSearch.REQUEST){String phrase=VoiceSearch.result(result,data);if(!phrase.isEmpty()){VoiceCommand command=VoiceCommand.parse(phrase);if(command.action==VoiceCommand.Action.FAVORITES||command.action==VoiceCommand.Action.FAVORITE_ADD||command.action==VoiceCommand.Action.FAVORITE_REMOVE){startActivity(new Intent(this,MainActivity.class).putExtra("voice_phrase",phrase).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP|Intent.FLAG_ACTIVITY_SINGLE_TOP));return;}if(!VoiceControl.execute(this,player,command)){query.setText(command.query);query.setSelection(command.query.length());search();}}}}
    private LinearLayout column(){LinearLayout l=new LinearLayout(this);l.setOrientation(LinearLayout.VERTICAL);return l;}
    private TextView text(String s,int size,int color){TextView t=Ui.text(this,s,size,color);t.setPadding(0,dp(6),0,dp(6));if(size>=24)Ui.bold(t);return t;}
    private Button button(String s,View.OnClickListener l){Button b=Ui.button(this,s,l);b.setGravity(Gravity.START|Gravity.CENTER_VERTICAL);return b;}
    private int dp(int n){return Math.round(n*getResources().getDisplayMetrics().density);}
    @Override public void onDestroy(){generation++;if(request!=null)request.cancel(true);worker.shutdownNow();handler.removeCallbacksAndMessages(null);if(connection!=null)MediaController.releaseFuture(connection);super.onDestroy();}
}
