package br.com.onda;

import android.app.*;
import android.content.*;
import android.net.Uri;
import android.os.*;
import android.view.*;
import android.widget.*;
import androidx.media3.common.*;
import androidx.media3.session.MediaController;
import androidx.media3.session.SessionToken;
import com.google.common.util.concurrent.ListenableFuture;
import java.io.*;
import java.util.*;
import java.util.concurrent.*;

/** UI for persisted chapters; decoding belongs to the foreground service, not the Activity. */
@androidx.media3.common.util.UnstableApi
public class AudioChaptersActivity extends Activity {
    private final Handler main=new Handler(Looper.getMainLooper());
    private final ExecutorService worker=Executors.newSingleThreadExecutor();
    private Future<?> task;
    private volatile int generation;
    private boolean started,busy,loading;
    private MediaController player;
    private ListenableFuture<MediaController> connection;
    private Uri owner;
    private String ownerId="",fingerprint="";
    private long duration;
    private AudioChapterStore.Data data;
    private TextView title,status;
    private ProgressBar progress;
    private Button analyze,add,whole,detection,batch;
    private ListView list;
    private ArrayAdapter<String> rows;
    private int playingChapter=-1;
    private final Runnable chapterTicker=this::refreshPlayingChapter;

    private void refreshPlayingChapter(){
        main.removeCallbacks(chapterTicker);
        int active=-1;
        if(started&&same()&&player.isPlaying()&&data!=null){
            long position=AudioChapterPlayback.absolute(player.getCurrentMediaItem(),player.getCurrentPosition());
            if(position>=0&&position<data.duration){
                int low=0,high=data.chapters.size()-1;
                while(low<=high){
                    int middle=(low+high)>>>1;
                    if(data.chapters.get(middle).start<=position){active=middle;low=middle+1;}
                    else high=middle-1;
                }
            }
            main.postDelayed(chapterTicker,750);
        }
        if(playingChapter!=active){
            playingChapter=active;
            rows.notifyDataSetChanged();
        }
    }
    private AlertDialog optionsDialog,editDialog,detectionDialog;
    private String observedScan="";
    private final ChapterScanService.Listener scanListener=state->{if(started&&!isDestroyed()){if(owner!=null&&owner.equals(state.uri)&&!state.running&&!state.token.equals(observedScan))bind();else scanStatus();}};
    @Override public void onCreate(Bundle state){super.onCreate(state);LinearLayout root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);Ui.background(root);root.setOnApplyWindowInsetsListener((v,i)->{root.setPadding(Ui.dp(this,16),Ui.dp(this,8)+i.getSystemWindowInsetTop(),Ui.dp(this,16),Ui.dp(this,8)+i.getSystemWindowInsetBottom());return i;});setContentView(root);LinearLayout header=new LinearLayout(this);header.setGravity(Gravity.CENTER_VERTICAL);Button back=Ui.button(this,"‹",v->finish());back.setContentDescription("Voltar das faixas da coletânea");header.addView(back,new LinearLayout.LayoutParams(Ui.dp(this,48),-2));header.addView(Ui.text(this,"Faixas da coletânea",20,Ui.TEXT),new LinearLayout.LayoutParams(0,-2,1));root.addView(header);title=Ui.text(this,"Escolha um arquivo de áudio na biblioteca.",16,Ui.CYAN);root.addView(title);Button info=Ui.button(this,"?",v->new AlertDialog.Builder(this).setTitle("Faixas da coletânea").setMessage("A análise procura pausas no áudio, sem reconhecer nomes de músicas. Em Detecção, escolha Conservadora, Equilibrada ou Sensível. Os modos Equilibrada e Sensível consideram o volume do próprio arquivo e confirmam a retomada do som para reduzir cortes em estalos. Mixes contínuos e trechos muito curtos podem não ser separados. As divisões são aproximadas.\n\nToque numa faixa para ouvir a partir dela; toque em ⋮ para editar nomes, início e fim, salvar um MP3 ou remover uma divisão. Você também pode adicionar divisões manualmente. Use ⇩ no topo para marcar e salvar várias faixas em MP3, em uma subpasta de Onda/Áudios. Ao editar, a repetição do trecho é desativada; escolha a faixa novamente depois. Para repetir só a selecionada, volte ao tocador e ative ↻ 1. Desligar a repetição libera o restante da coletânea. As marcações não alteram o áudio original. A exportação cria um novo MP3 somente quando solicitada. A reprodução é pausada durante a análise. Ela continua ao minimizar o Onda ou apagar a tela. Acompanhe e cancele pela notificação ou pelo botão Cancelar análise. As divisões anteriores são mantidas se você cancelar. Não reinicia sozinha se o Android encerrar o processo.").setPositiveButton("Entendi",null).show());info.setContentDescription("Como analisar uma coletânea");header.addView(info,new LinearLayout.LayoutParams(Ui.dp(this,48),-2));batch=Ui.button(this,"⇩",v->{if(data!=null&&!busy&&!loading&&same())ChapterBatchExportActivity.open(this,owner,fingerprint,title.getText().toString(),data.duration);});batch.setContentDescription("Selecionar várias faixas para MP3");batch.setTooltipText("Salvar várias faixas em MP3");header.addView(batch,new LinearLayout.LayoutParams(Ui.dp(this,48),-2));TextView help=Ui.text(this,"Divisões aproximadas por pausas. Mixes contínuos podem não separar. Arquivo original preservado.",13,Ui.MUTED);root.addView(help);LinearLayout exports=new LinearLayout(this);
exports.addView(Ui.button(this,"Montar MP3 único",v->openMix()),new LinearLayout.LayoutParams(0,-2,1));
exports.addView(Ui.button(this,"Compartilhar faixas",v->shareChapters(-1)),new LinearLayout.LayoutParams(0,-2,1));
root.addView(exports);status=Ui.text(this,"Conectando ao tocador…",14,Ui.TEXT);status.setContentDescription("Estado da análise de coletânea");root.addView(status);progress=new ProgressBar(this,null,android.R.attr.progressBarStyleHorizontal);progress.setMax(100);progress.setVisibility(View.GONE);root.addView(progress,new LinearLayout.LayoutParams(-1,Ui.dp(this,16)));analyze=Ui.button(this,"Analisar pausas no arquivo",v->{if(busy)cancel();else scan();});analyze.setContentDescription("Analisar pausas na coletânea");analyze.setEnabled(false);Ui.primary(analyze);root.addView(analyze);detection=Ui.button(this,"",v->detectionDialog=ChapterDetection.show(this,this::controls));root.addView(detection);LinearLayout actions=new LinearLayout(this);add=Ui.button(this,"Adicionar faixa",v->addChapter());whole=Ui.button(this,"Arquivo inteiro",v->clearSelection());actions.addView(add,new LinearLayout.LayoutParams(0,-2,1));actions.addView(whole,new LinearLayout.LayoutParams(0,-2,1));root.addView(actions);rows=new ArrayAdapter<String>(this,android.R.layout.simple_list_item_1,new ArrayList<>()){@Override public View getView(int position,View reusable,ViewGroup parent){LinearLayout row=new LinearLayout(AudioChaptersActivity.this);row.setGravity(Gravity.CENTER_VERTICAL);boolean playing=position==playingChapter;TextView view=Ui.text(AudioChaptersActivity.this,playing?"▶ Tocando agora\n"+getItem(position):getItem(position),15,playing?Ui.CYAN:Ui.TEXT);view.setPadding(Ui.dp(AudioChaptersActivity.this,12),Ui.dp(AudioChaptersActivity.this,10),Ui.dp(AudioChaptersActivity.this,8),Ui.dp(AudioChaptersActivity.this,10));view.setMinHeight(Ui.dp(AudioChaptersActivity.this,64));row.addView(view,new LinearLayout.LayoutParams(0,-2,1));Button menu=Ui.button(AudioChaptersActivity.this,"⋮",v->edit(position));menu.setFocusable(false);menu.setContentDescription("Opções da "+AudioChapterStore.label(data,position));row.addView(menu,new LinearLayout.LayoutParams(Ui.dp(AudioChaptersActivity.this,48),-2));return row;}};list=new ListView(this);list.setAdapter(rows);list.setContentDescription("Faixas detectadas no áudio original");list.setOnItemClickListener((parent,view,index,id)->play(index));list.setOnItemLongClickListener((parent,view,index,id)->{edit(index);return true;});root.addView(list,new LinearLayout.LayoutParams(-1,0,1));connection=new MediaController.Builder(this,new SessionToken(this,new ComponentName(this,PlaybackService.class))).buildAsync();connection.addListener(()->{if(isDestroyed())return;try{player=connection.get();player.addListener(new Player.Listener(){@Override public void onEvents(Player player,Player.Events events){if(started)refreshPlayingChapter();}@Override public void onMediaItemTransition(MediaItem item,int reason){if(started)bind();}@Override public void onPlaybackStateChanged(int state){if(started&&same()){duration=Math.max(duration,AudioChapterPlayback.duration(player.getCurrentMediaItem(),player.getDuration()));controls();}}});if(started)bind();}catch(Exception error){status.setText("Não foi possível conectar ao tocador. Volte à biblioteca e tente novamente.");}},main::post);}
    private boolean same(){MediaItem item=player==null?null:player.getCurrentMediaItem();return item!=null&&item.localConfiguration!=null&&owner!=null&&ownerId.equals(item.mediaId)&&owner.equals(item.localConfiguration.uri)&&!RadioMedia.is(item);}
    private void bind(){if(player==null)return;MediaItem item=player.getCurrentMediaItem();Uri next=item==null||item.localConfiguration==null?null:item.localConfiguration.uri;boolean local=next!=null&&("content".equals(next.getScheme())||"file".equals(next.getScheme()))&&!RadioMedia.is(item);ChapterScanService.Snapshot scan=ChapterScanService.state(this);boolean completed=local&&scan!=null&&next.equals(scan.uri)&&!scan.running&&!scan.token.equals(observedScan);if(local&&next.equals(owner)&&ownerId.equals(item.mediaId)&&!completed&&(busy||loading||data!=null)){scanStatus();return;}if(completed)observedScan=scan.token;cancelWork();owner=local?next:null;ownerId=local?item.mediaId:"";duration=local?Math.max(0,Math.max(player.getDuration(),LibraryStore.number(item,"durationMs"))):0;data=null;rows.clear();title.setText(local?(item.mediaMetadata.title==null?"Áudio selecionado":item.mediaMetadata.title):"Escolha um arquivo de áudio na biblioteca.");if(!local){status.setText("Este recurso usa um áudio local selecionado no tocador; rádios e links online não são analisados.");controls();return;}loading=true;status.setText("Lendo divisões salvas…");controls();Uri source=owner;long expectedDuration=duration;int request=generation;task=worker.submit(()->{try{String stamp=AudioChapterStore.stamp(this,source);AudioChapterStore.Data saved=AudioChapterStore.load(this,source,stamp,expectedDuration);main.post(()->{if(!valid(request,source))return;loading=false;fingerprint=stamp;data=saved;if(saved!=null)duration=saved.duration;render();status.setText(saved==null?"A análise pausa o áudio e continua com a tela apagada. Os nomes começam como Faixa 1, Faixa 2…":description());scanStatus();});}catch(Exception error){main.post(()->{if(!valid(request,source))return;loading=false;status.setText(DownloadFailure.describe("Divisões salvas",error));controls();});}});}
    private boolean valid(int request,Uri source){return started&&!isDestroyed()&&request==generation&&source.equals(owner)&&same();}
    private void controls(){if(batch!=null)batch.setEnabled(data!=null&&!busy&&!loading&&owner!=null);ChapterScanService.Snapshot active=ChapterScanService.state(this);boolean other=active!=null&&active.running&&(owner==null||!owner.equals(active.uri));if(detection!=null){detection.setText("Detecção: "+ChapterDetection.NAMES[ChapterDetection.get(this)]);detection.setEnabled(!loading&&(active==null||!active.running));}analyze.setEnabled(owner!=null&&!loading&&!other);analyze.setText(busy?"Cancelar análise":data==null?"Analisar pausas no arquivo":"Reanalisar pausas");list.setEnabled(!busy&&!loading);add.setEnabled(owner!=null&&!busy&&!loading&&duration>0);whole.setEnabled(owner!=null&&!busy&&!loading);progress.setVisibility(busy?View.VISIBLE:View.GONE);}
    private final ChapterSharing sharing=new ChapterSharing(this);
    private void shareChapters(int index){
        if(data==null||busy||loading||!same()){
            Toast.makeText(this,"Selecione uma coletânea com divisões salvas.",Toast.LENGTH_SHORT).show();
            return;
        }
        sharing.choose(owner,fingerprint,data,index);
    }
    private void openMix(){
        if(data==null||busy||loading||!same()){
            Toast.makeText(this,"Selecione uma coletânea com divisões salvas.",Toast.LENGTH_SHORT).show();
            return;
        }
        org.json.JSONArray clips=new org.json.JSONArray();
        try{
            for(int i=0;i<data.chapters.size();i++){
                long start=data.chapters.get(i).start;
                long end=i+1<data.chapters.size()?data.chapters.get(i+1).start:data.duration;
                clips.put(new org.json.JSONObject().put("uri",owner.toString()).put("stamp",fingerprint)
                        .put("label",AudioChapterStore.label(data,i)).put("start",start).put("end",end));
            }
            startActivity(new Intent(this,MixMp3Activity.class).putExtra("clips",clips.toString()).putExtra("choose_clips",true));
        }catch(org.json.JSONException error){status.setText("Não foi possível abrir as faixas.");}
    }
    private void render(){rows.clear();if(data!=null)for(int i=0;i<data.chapters.size();i++){long start=data.chapters.get(i).start,end=i+1<data.chapters.size()?data.chapters.get(i+1).start:data.duration;rows.add(AudioChapterStore.label(data,i)+"\n"+time(start)+" → "+time(end));}refreshPlayingChapter();rows.notifyDataSetChanged();}
    private String description(){return data==null?"Nenhuma divisão salva.":data.chapters.size()<2?"Não encontrei pausas claras para separar músicas. O áudio continua inteiro.":data.chapters.size()+" faixas aproximadas. Confira as divisões antes de usá-las.";}
    private void scanStatus(){
        if(!started)return;ChapterScanService.Snapshot scan=ChapterScanService.state(this);boolean own=scan!=null&&owner!=null&&owner.equals(scan.uri);
        busy=own&&scan.running;
        if(busy){progress.setIndeterminate(scan.total<=0);if(scan.total>0)progress.setProgress((int)Math.min(100,scan.at*100/scan.total));status.setText(scan.message);}
        else if(scan!=null&&scan.running)status.setText("Já há uma análise em andamento: "+scan.title+". Acompanhe ou cancele pela notificação.");
        else if(own&&scan.token.equals(observedScan))status.setText("done".equals(scan.phase)?description():scan.message);
        String notified=getIntent().getStringExtra("scan_uri");if(notified!=null&&owner!=null&&!owner.toString().equals(notified)&&!busy)status.setText("Resultado salvo para "+getIntent().getStringExtra("scan_title")+". Selecione essa coletânea no tocador para ver as faixas.");
        controls();
    }
    private void scan(){
        if(!same()||loading){bind();return;}ChapterScanService.Snapshot active=ChapterScanService.state(this);if(active!=null&&active.running){scanStatus();return;}
        cancelWork();clearSelection();player.pause();busy=true;progress.setIndeterminate(true);status.setText("Iniciando análise em segundo plano…");controls();
        try{if(Build.VERSION.SDK_INT>=33&&checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS)!=android.content.pm.PackageManager.PERMISSION_GRANTED)requestPermissions(new String[]{android.Manifest.permission.POST_NOTIFICATIONS},913);if(!ChapterScanService.start(this,owner,ownerId,title.getText().toString(),duration)){busy=false;scanStatus();}}
        catch(RuntimeException error){busy=false;status.setText(DownloadFailure.describe("Iniciar análise",error));controls();}
    }
    private void cancelWork(){generation++;if(task!=null){task.cancel(true);task=null;}busy=false;loading=false;}
    private void cancel(){ChapterScanService.Snapshot active=ChapterScanService.state(this);if(active!=null&&active.running&&owner!=null&&owner.equals(active.uri)){ChapterScanService.cancel(this,active);status.setText("Cancelando análise…");}else scanStatus();}
    private void play(int index){if(busy||loading||data==null||index<0||index>=data.chapters.size()||!same()){Toast.makeText(this,"O arquivo do tocador mudou. Escolha a coletânea novamente.",Toast.LENGTH_SHORT).show();return;}MediaItem chosen=AudioChapterPlayback.select(player.getCurrentMediaItem(),data,index,fingerprint);Bundle args=new Bundle();args.putBundle("item",chosen.toBundleIncludeLocalConfiguration());com.google.common.util.concurrent.ListenableFuture<androidx.media3.session.SessionResult> result=player.sendCustomCommand(new androidx.media3.session.SessionCommand(AudioChapterPlayback.SELECT,Bundle.EMPTY),args);result.addListener(()->{if(!started||isDestroyed())return;try{if(result.get().resultCode!=androidx.media3.session.SessionResult.RESULT_SUCCESS)status.setText("O arquivo mudou. Escolha a faixa novamente.");}catch(Exception error){status.setText("Não foi possível selecionar a faixa. Tente novamente.");}},main::post);status.setText("Ouvindo "+AudioChapterStore.label(data,index)+". Use ↻ 1 no tocador para repetir só esta faixa.");}
    private void clearSelection(){
        if(!same())return;
        Bundle args=new Bundle();args.putString("id",ownerId);args.putString("uri",owner.toString());
        player.sendCustomCommand(new androidx.media3.session.SessionCommand(AudioChapterPlayback.CLEAR,Bundle.EMPTY),args);
        status.setText("Arquivo inteiro liberado. A posição e a pausa foram mantidas.");
    }
    private EditText field(LinearLayout box,String label,String value){
        box.addView(Ui.text(this,label,14,Ui.MUTED));EditText input=new EditText(this);Ui.input(input);input.setSingleLine(true);input.setText(value);box.addView(input,new LinearLayout.LayoutParams(-1,-2));return input;
    }
    private void addChapter(){
        if(!same()||busy||loading||duration<=0)return;
        AudioChapterStore.Data base=data==null?ChapterEdits.full(duration):data;
        Uri source=owner;long at=AudioChapterPlayback.absolute(player.getCurrentMediaItem(),player.getCurrentPosition());
        LinearLayout box=new LinearLayout(this);box.setOrientation(LinearLayout.VERTICAL);box.setPadding(Ui.dp(this,16),0,Ui.dp(this,16),0);
        EditText name=field(box,"Nome (opcional)","");name.setFilters(new android.text.InputFilter[]{new android.text.InputFilter.LengthFilter(120)});
        EditText start=field(box,"Início • minutos:segundos.milissegundos",ChapterEdits.format(at));
        TextView error=Ui.text(this,"A divisão separa a faixa anterior neste horário. O áudio original é preservado.",14,Ui.MUTED);box.addView(error);
        AlertDialog dialog=new AlertDialog.Builder(this).setTitle("Adicionar faixa").setView(box).setNegativeButton("Cancelar",null).setPositiveButton("Salvar",null).create();dialog.setOnShowListener(d->dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(v->{
            if(!same()||!source.equals(owner)||busy||loading){dialog.dismiss();return;}
            try{AudioChapterStore.Data edited=ChapterEdits.add(base,ChapterEdits.parse(start.getText().toString()),name.getText().toString());saveEdited(source,edited);dialog.dismiss();}catch(IllegalArgumentException ex){error.setText(ex.getMessage());}
        }));dialog.show();
    }
    private void edit(int index){
        if(busy||loading||data==null||index<0||index>=data.chapters.size()||!same())return;
        AudioChapterStore.Data previous=data;Uri source=owner;
        String[] options=index==0?new String[]{"Editar nome e horários","Salvar faixa em MP3","Compartilhar faixa"}:new String[]{"Editar nome e horários","Salvar faixa em MP3","Remover esta divisão","Compartilhar faixa"};
        optionsDialog=new AlertDialog.Builder(this).setTitle(AudioChapterStore.label(previous,index)).setItems(options,(dialog,which)->{
            if(data!=previous||!source.equals(owner)||!same())return;
            if(which==options.length-1){shareChapters(index);return;}
            if(which==1){ChapterExportActivity.open(this,source,fingerprint,previous,index);return;}
            if(which==2){new AlertDialog.Builder(this).setTitle("Remover divisão?").setMessage("Este trecho será unido à faixa anterior. O arquivo original permanece intacto.").setNegativeButton("Cancelar",null).setPositiveButton("Remover",(d,w)->{if(data==previous&&same()&&source.equals(owner))saveEdited(source,ChapterEdits.remove(previous,index));}).show();return;}
            LinearLayout box=new LinearLayout(this);box.setOrientation(LinearLayout.VERTICAL);box.setPadding(Ui.dp(this,16),0,Ui.dp(this,16),0);
            EditText name=field(box,"Nome da faixa",AudioChapterStore.label(previous,index));name.setFilters(new android.text.InputFilter[]{new android.text.InputFilter.LengthFilter(120)});
            EditText start=field(box,"Início • minutos:segundos.milissegundos",ChapterEdits.format(previous.chapters.get(index).start));start.setEnabled(index>0);
            EditText end=field(box,"Fim • minutos:segundos.milissegundos",ChapterEdits.format(index+1<previous.chapters.size()?previous.chapters.get(index+1).start:previous.duration));end.setEnabled(index+1<previous.chapters.size());
            TextView error=Ui.text(this,"Alterar um limite também ajusta a faixa vizinha. A repetição do trecho será desativada; selecione a faixa novamente depois.",14,Ui.MUTED);box.addView(error);ScrollView scroll=new ScrollView(this);scroll.addView(box);
            AlertDialog editor=new AlertDialog.Builder(this).setTitle("Editar faixa").setView(scroll).setNegativeButton("Cancelar",null).setPositiveButton("Salvar",null).create();editDialog=editor;editor.setOnShowListener(d->editor.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(v->{
                if(data!=previous||!source.equals(owner)||!same()||busy||loading){editor.dismiss();return;}
                try{saveEdited(source,ChapterEdits.update(previous,index,name.getText().toString(),ChapterEdits.parse(start.getText().toString()),ChapterEdits.parse(end.getText().toString())));editor.dismiss();}catch(IllegalArgumentException ex){error.setText(ex.getMessage());}
            }));editor.show();
        }).setNegativeButton("Fechar",null).show();
    }
    private void saveEdited(Uri source,AudioChapterStore.Data edited){clearSelection();String stamp=fingerprint;int request=generation;loading=true;controls();task=worker.submit(()->{try{AudioChapterStore.save(this,source,stamp,edited);main.post(()->{if(!valid(request,source))return;loading=false;data=edited;render();status.setText(description());controls();});}catch(Exception error){main.post(()->{if(!valid(request,source))return;loading=false;status.setText(DownloadFailure.describe("Salvar divisões",error));controls();});}});}
    static String time(long ms){long seconds=Math.max(0,ms/1000);return seconds>=3600?String.format(Locale.ROOT,"%d:%02d:%02d",seconds/3600,seconds/60%60,seconds%60):String.format(Locale.ROOT,"%d:%02d",seconds/60,seconds%60);}
    @Override protected void onStart(){super.onStart();started=true;ChapterScanService.listen(scanListener);if(player!=null)bind();}
    @Override protected void onNewIntent(Intent intent){super.onNewIntent(intent);setIntent(intent);if(started&&player!=null)bind();}
    @Override protected void onStop(){started=false;refreshPlayingChapter();ChapterScanService.unlisten(scanListener);if(detectionDialog!=null)detectionDialog.dismiss();if(optionsDialog!=null)optionsDialog.dismiss();if(editDialog!=null)editDialog.dismiss();cancelWork();controls();super.onStop();}
    @Override protected void onDestroy(){sharing.close();cancelWork();main.removeCallbacksAndMessages(null);worker.shutdownNow();if(connection!=null)MediaController.releaseFuture(connection);super.onDestroy();}
}
