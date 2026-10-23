package br.com.onda;

import android.app.*;
import android.content.*;
import android.os.*;
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
public class PlaylistsActivity extends Activity {
    private final ExecutorService worker=Executors.newSingleThreadExecutor();
    private final Map<String,MediaItem> library=new LinkedHashMap<>();
    private List<PlaylistStore.Entry> lists;private PlaylistStore.Entry selected;
    private LinearLayout root;private TextView heading,status;private ListView rows;private Button add,play,options;
    private MediaController player;private ListenableFuture<MediaController> connection;private boolean loaded;
    @Override public void onCreate(Bundle state){super.onCreate(state);lists=PlaylistStore.read(this);
        root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);Ui.background(root);root.setOnApplyWindowInsetsListener((v,i)->{root.setPadding(Ui.dp(this,16),Ui.dp(this,12)+i.getSystemWindowInsetTop(),Ui.dp(this,16),Ui.dp(this,12)+i.getSystemWindowInsetBottom());return i;});setContentView(root);
        LinearLayout header=new LinearLayout(this);header.setGravity(Gravity.CENTER_VERTICAL);Button back=Ui.button(this,"‹",v->back());back.setContentDescription("Voltar das playlists");Ui.ghost(back);header.addView(back,new LinearLayout.LayoutParams(Ui.dp(this,48),Ui.dp(this,48)));heading=Ui.text(this,"Playlists",24,Ui.TEXT);Ui.bold(heading);heading.setMaxLines(1);heading.setEllipsize(TextUtils.TruncateAt.END);header.addView(heading,new LinearLayout.LayoutParams(0,-2,1));options=Ui.button(this,"⋮",v->listOptions());options.setContentDescription("Opções da playlist");header.addView(options,new LinearLayout.LayoutParams(Ui.dp(this,48),Ui.dp(this,48)));root.addView(header);
        status=Ui.text(this,"",13,Ui.MUTED);status.setPadding(0,Ui.dp(this,12),0,Ui.dp(this,12));root.addView(status);
        rows=new ListView(this);rows.setDivider(null);rows.setDividerHeight(Ui.dp(this,6));root.addView(rows,new LinearLayout.LayoutParams(-1,0,1));rows.setOnItemClickListener((p,v,i,id)->{if(selected==null){selected=lists.get(i);render();}else trackOptions(i);});
        LinearLayout actions=new LinearLayout(this);add=Ui.button(this,"Nova playlist",v->{if(selected==null)nameDialog(null);else chooseSongs();});add.setContentDescription("Criar playlist ou adicionar músicas");actions.addView(add,new LinearLayout.LayoutParams(0,Ui.dp(this,48),1));play=Ui.button(this,"Ouvir lista",v->start());play.setContentDescription("Tocar playlist");Ui.primary(play);actions.addView(play,new LinearLayout.LayoutParams(0,Ui.dp(this,48),1));root.addView(actions);render();
        connection=new MediaController.Builder(this,new SessionToken(this,new ComponentName(this,PlaybackService.class))).buildAsync();connection.addListener(()->{if(isDestroyed())return;try{player=connection.get();render();}catch(Exception e){status.setText("Não foi possível conectar o tocador. Abra novamente pela biblioteca.");}},this::runOnUiThread);
        worker.execute(()->{try{List<MediaItem> found=LibraryStore.scan(this);runOnUiThread(()->{if(isDestroyed())return;for(MediaItem item:found)library.put(item.mediaId,item);loaded=true;render();});}catch(Exception e){runOnUiThread(()->{if(!isDestroyed())status.setText("Permita acesso às músicas na biblioteca e reabra as playlists.");});}});
    }
    private void back(){if(selected!=null){selected=null;render();}else finish();}
    @Override public void onBackPressed(){back();}
    private void save(){PlaylistStore.save(this,lists);render();}
    private List<MediaItem> playable(){List<MediaItem> out=new ArrayList<>();if(selected!=null)for(String id:selected.songs){MediaItem item=library.get(id);if(item!=null)out.add(item);}return out;}
    private void render(){
        boolean detail=selected!=null;heading.setText(detail?selected.name:"Playlists");options.setVisibility(detail?View.VISIBLE:View.GONE);add.setText(detail?"Adicionar músicas":"Nova playlist");add.setEnabled(detail?loaded:lists.size()<100);play.setVisibility(detail?View.VISIBLE:View.GONE);play.setEnabled(loaded&&player!=null&&!playable().isEmpty());
        List<String> labels=new ArrayList<>();
        if(detail){int available=playable().size();status.setText(!loaded?"Lendo biblioteca…":selected.songs.size()+" músicas • "+available+" disponíveis. Toque numa faixa para mover ou remover.");for(int i=0;i<selected.songs.size();i++){MediaItem item=library.get(selected.songs.get(i));labels.add((i+1)+". "+(item==null?"Arquivo indisponível":item.mediaMetadata.title+"\n"+item.mediaMetadata.artist));}if(selected.songs.isEmpty())status.setText("Lista vazia. Adicione músicas do celular.");}
        else{status.setText(lists.isEmpty()?"Suas músicas, na sua ordem. Crie a primeira playlist.":lists.size()+" playlists salvas no aparelho");for(PlaylistStore.Entry e:lists)labels.add(e.name+"\n"+e.songs.size()+" músicas");}
        rows.setAdapter(new ArrayAdapter<String>(this,android.R.layout.simple_list_item_1,labels){@Override public View getView(int i,View recycled,ViewGroup parent){TextView text=(TextView)super.getView(i,recycled,parent);text.setTextColor(Ui.TEXT);text.setTextSize(15);text.setPadding(Ui.dp(PlaylistsActivity.this,14),Ui.dp(PlaylistsActivity.this,14),Ui.dp(PlaylistsActivity.this,14),Ui.dp(PlaylistsActivity.this,14));Ui.card(text,false);return text;}});
    }
    private void nameDialog(PlaylistStore.Entry entry){EditText name=new EditText(this);name.setSingleLine(true);name.setHint("Nome da playlist");name.setFilters(new InputFilter[]{new InputFilter.LengthFilter(60)});if(entry!=null)name.setText(entry.name);AlertDialog dialog=new AlertDialog.Builder(this).setTitle(entry==null?"Nova playlist":"Renomear playlist").setView(name).setNegativeButton("Cancelar",null).setPositiveButton("Salvar",null).create();dialog.setOnShowListener(v->dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(button->{String value=name.getText().toString().trim();if(value.isEmpty()){name.setError("Digite um nome");return;}for(PlaylistStore.Entry other:lists)if(other!=entry&&SearchText.normalize(other.name).equals(SearchText.normalize(value))){name.setError("Já existe uma playlist com esse nome");return;}if(entry==null){selected=new PlaylistStore.Entry(UUID.randomUUID().toString(),value);lists.add(selected);}else entry.name=value;save();dialog.dismiss();}));dialog.show();}
    private void listOptions(){if(selected==null)return;new AlertDialog.Builder(this).setTitle(selected.name).setItems(new String[]{"Renomear","Excluir playlist"},(d,i)->{if(i==0)nameDialog(selected);else new AlertDialog.Builder(this).setTitle("Excluir playlist?").setMessage("Os arquivos de música continuam no celular.").setNegativeButton("Cancelar",null).setPositiveButton("Excluir",(confirm,which)->{lists.remove(selected);selected=null;save();}).show();}).show();}
    private void trackOptions(int index){new AlertDialog.Builder(this).setTitle("Organizar música").setItems(new String[]{"Mover para cima","Mover para baixo","Remover da playlist"},(d,which)->{if(which==0&&index>0)Collections.swap(selected.songs,index,index-1);if(which==1&&index<selected.songs.size()-1)Collections.swap(selected.songs,index,index+1);if(which==2)selected.songs.remove(index);save();}).show();}
    private void chooseSongs(){if(!loaded||selected==null)return;PlaylistStore.Entry owner=selected;Set<String> chosen=new HashSet<>(owner.songs);List<MediaItem> results=new ArrayList<>();
        LinearLayout box=new LinearLayout(this);box.setOrientation(LinearLayout.VERTICAL);EditText search=new EditText(this);search.setSingleLine(true);search.setHint("Buscar música ou artista");search.setContentDescription("Buscar músicas para playlist");box.addView(search);ListView picks=new ListView(this);picks.setChoiceMode(ListView.CHOICE_MODE_MULTIPLE);box.addView(picks,new LinearLayout.LayoutParams(-1,Ui.dp(this,280)));
        Runnable filter=()->{String query=SearchText.normalize(search.getText().toString());results.clear();List<String> labels=new ArrayList<>();for(MediaItem item:library.values())if(SearchText.matches(item.mediaMetadata.title+" "+item.mediaMetadata.artist,query)){results.add(item);labels.add(item.mediaMetadata.title+" — "+item.mediaMetadata.artist);}picks.setAdapter(new ArrayAdapter<>(this,android.R.layout.simple_list_item_multiple_choice,labels));for(int i=0;i<results.size();i++)picks.setItemChecked(i,chosen.contains(results.get(i).mediaId));};filter.run();
        picks.setOnItemClickListener((p,v,i,id)->{String song=results.get(i).mediaId;if(picks.isItemChecked(i))chosen.add(song);else chosen.remove(song);});search.addTextChangedListener(new TextWatcher(){public void beforeTextChanged(CharSequence s,int start,int count,int after){}public void onTextChanged(CharSequence s,int start,int before,int count){filter.run();}public void afterTextChanged(Editable e){}});
        new AlertDialog.Builder(this).setTitle("Escolher músicas").setView(box).setNegativeButton("Cancelar",null).setPositiveButton("Salvar seleção",(d,w)->{if(chosen.size()>2000){Toast.makeText(this,"Limite de 2.000 músicas por playlist",Toast.LENGTH_LONG).show();return;}owner.songs.removeIf(id->!chosen.contains(id));for(String id:library.keySet())if(chosen.contains(id)&&!owner.songs.contains(id))owner.songs.add(id);save();}).show();
    }
    private void start(){List<MediaItem> queue=playable();if(player==null||queue.isEmpty())return;player.setShuffleModeEnabled(false);player.setRepeatMode(Player.REPEAT_MODE_OFF);player.setMediaItems(queue,0,0);player.prepare();player.play();startActivity(new Intent(this,MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP|Intent.FLAG_ACTIVITY_SINGLE_TOP));finish();}
    @Override public void onDestroy(){worker.shutdownNow();if(connection!=null)MediaController.releaseFuture(connection);super.onDestroy();}
}
