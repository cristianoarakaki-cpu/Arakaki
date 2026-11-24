package br.com.onda;

import android.app.*;
import android.content.*;
import android.net.Uri;
import android.os.*;
import android.view.*;
import android.widget.*;
import java.io.*;
import java.util.concurrent.*;

/** User-requested export UI; the foreground service owns conversion and its destination descriptor. */
@androidx.media3.common.util.UnstableApi
public class ChapterExportActivity extends Activity {
    private static final int CREATE=71;
    private boolean started,busy,otherBusy;
    private final ChapterExportService.Listener listener=state->{if(started&&!isDestroyed())sync();};
    private Uri source,pending,saved;private String stamp,name;private long start,end,duration;
    private TextView status;private Button export,quality,share,other;private ProgressBar progress;
    static void open(Context context,Uri uri,String stamp,AudioChapterStore.Data data,int index){
        context.startActivity(new Intent(context,ChapterExportActivity.class).putExtra("source",uri.toString()).putExtra("stamp",stamp).putExtra("name",AudioChapterStore.label(data,index)).putExtra("start",data.chapters.get(index).start).putExtra("end",index+1<data.chapters.size()?data.chapters.get(index+1).start:data.duration).putExtra("duration",data.duration));
    }
    @Override public void onCreate(Bundle state){
        super.onCreate(state);Intent input=getIntent();String sourceText=input.getStringExtra("source");source=sourceText==null?input.getData():Uri.parse(sourceText);stamp=input.getStringExtra("stamp");name=input.getStringExtra("name");start=input.getLongExtra("start",-1);end=input.getLongExtra("end",-1);duration=input.getLongExtra("duration",0);
        if(state!=null){String uri=state.getString("pending"),complete=state.getString("saved");pending=uri==null?null:Uri.parse(uri);saved=complete==null?null:Uri.parse(complete);}
        LinearLayout root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);Ui.background(root);root.setOnApplyWindowInsetsListener((v,i)->{root.setPadding(Ui.dp(this,16),Ui.dp(this,8)+i.getSystemWindowInsetTop(),Ui.dp(this,16),Ui.dp(this,8)+i.getSystemWindowInsetBottom());return i;});setContentView(root);
        LinearLayout header=new LinearLayout(this);header.setGravity(Gravity.CENTER_VERTICAL);header.addView(Ui.button(this,"‹",v->finish()),new LinearLayout.LayoutParams(Ui.dp(this,48),-2));TextView heading=Ui.text(this,"Salvar faixa em MP3",20,Ui.TEXT);heading.setMaxLines(2);header.addView(heading,new LinearLayout.LayoutParams(0,-2,1));root.addView(header);
        ScrollView scroll=new ScrollView(this);LinearLayout body=new LinearLayout(this);body.setOrientation(LinearLayout.VERTICAL);scroll.addView(body);root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
        body.addView(Ui.text(this,name==null?"Escolha uma faixa na tela de coletâneas.":name,20,Ui.CYAN));
        if(validInput())body.addView(Ui.text(this,ChapterEdits.format(start)+" → "+ChapterEdits.format(end),16,Ui.TEXT));
        body.addView(Ui.text(this,"Cria um novo arquivo com apenas este trecho. O áudio original é preservado. A conversão ocorre no celular e continua ao minimizar o Onda ou apagar a tela. Acompanhe e cancele pela notificação. O processamento é encerrado ao concluir ou cancelar.",15,Ui.MUTED));
        quality=Ui.button(this,"",v->Mp3Quality.show(this,this::controls));body.addView(quality);
        export=Ui.button(this,"Salvar MP3",v->{if(busy){cancel();return;}Intent create=new Intent(Intent.ACTION_CREATE_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType("audio/mpeg").putExtra(Intent.EXTRA_TITLE,safeName(name)+".mp3");try{startActivityForResult(create,CREATE);}catch(ActivityNotFoundException error){status.setText("Nenhum seletor de arquivos disponível neste celular.");}});Ui.primary(export);body.addView(export);
        progress=new ProgressBar(this,null,android.R.attr.progressBarStyleHorizontal);progress.setMax(100);body.addView(progress,new LinearLayout.LayoutParams(-1,Ui.dp(this,16)));
        status=Ui.text(this,validInput()?"Escolha onde salvar a nova faixa.":"Abra Faixas da coletânea, toque em ⋮ e escolha Salvar faixa em MP3.",15,Ui.TEXT);body.addView(status);
        share=Ui.button(this,"Compartilhar MP3 salvo",v->{if(saved==null)return;Intent send=new Intent(Intent.ACTION_SEND).setType("audio/mpeg").putExtra(Intent.EXTRA_STREAM,saved).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);send.setClipData(ClipData.newRawUri("Faixa MP3",saved));try{startActivity(Intent.createChooser(send,"Compartilhar faixa"));}catch(ActivityNotFoundException error){status.setText("Nenhum aplicativo disponível para compartilhar.");}catch(SecurityException error){status.setText("O provedor não manteve acesso ao MP3. Abra o arquivo salvo pelo Android para compartilhar.");}});body.addView(share);other=Ui.button(this,"Ver conversão em andamento",v->{ChapterExportService.Snapshot active=ChapterExportService.state(this);if(active!=null&&active.running)startActivity(active.job.screen(this));});body.addView(other);controls();
    }
    private static String safeName(String value){String result=value==null?"Faixa":value.replaceAll("[\\\\/:*?\"<>|\\p{Cntrl}]","_").trim();return result.isEmpty()?"Faixa":result.substring(0,Math.min(100,result.length()));}
    private boolean validInput(){return source!=null&&("file".equals(source.getScheme())||"content".equals(source.getScheme()))&&stamp!=null&&start>=0&&end>start&&end<=duration;}
    private void controls(){if(export==null)return;export.setEnabled(validInput()&&!otherBusy);export.setText(busy?"Cancelar conversão":"Salvar MP3");quality.setText("Novos MP3: "+Mp3Quality.get(this)+" kbps");quality.setEnabled(!busy);progress.setVisibility(busy?View.VISIBLE:View.GONE);share.setVisibility(saved==null?View.GONE:View.VISIBLE);if(other!=null)other.setVisibility(otherBusy?View.VISIBLE:View.GONE);}
    @Override protected void onActivityResult(int request,int result,Intent data){super.onActivityResult(request,result,data);if(request==CREATE&&result==RESULT_OK&&data!=null){Uri target=data.getData();if(target!=null&&target.equals(source)){status.setText("Escolha um novo arquivo; não sobrescreva a coletânea.");return;}if(target!=null&&"content".equals(target.getScheme()))try{int grants=data.getFlags()&(Intent.FLAG_GRANT_READ_URI_PERMISSION|Intent.FLAG_GRANT_WRITE_URI_PERMISSION);if(grants!=0&&(data.getFlags()&Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)!=0)getContentResolver().takePersistableUriPermission(target,grants);}catch(SecurityException|IllegalArgumentException ignored){}pending=target;}}
    private void sync(){
        ChapterExportService.Snapshot state=ChapterExportService.state(this);boolean own=state!=null&&state.job.matches(source,stamp,start,end);otherBusy=state!=null&&state.running&&!own;busy=own&&state.running;
        if(own){saved="done".equals(state.phase)?state.job.target:null;status.setText(state.message);progress.setIndeterminate(state.total<=0);if(state.total>0)progress.setProgress((int)Math.min(100,state.at*100/state.total));}
        else if(otherBusy)status.setText("Já há uma conversão em andamento: "+state.job.title+".");controls();
    }
    @Override protected void onStart(){super.onStart();started=true;ChapterExportService.listen(listener);sync();}
    @Override protected void onResume(){super.onResume();if(pending!=null&&!busy){Uri target=pending;pending=null;convert(target);}}
    private void convert(Uri target){
        if(!validInput())return;ChapterExportService.Snapshot active=ChapterExportService.state(this);if(active!=null&&active.running){sync();return;}
        ChapterExportJob job=new ChapterExportJob(java.util.UUID.randomUUID().toString(),source,target,stamp,name,start,end,duration,Mp3Quality.get(this));
        try{if(Build.VERSION.SDK_INT>=33&&checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS)!=android.content.pm.PackageManager.PERMISSION_GRANTED)requestPermissions(new String[]{android.Manifest.permission.POST_NOTIFICATIONS},914);if(ChapterExportService.start(this,job)){busy=true;saved=null;progress.setIndeterminate(true);status.setText("Preparando a conversão em segundo plano…");controls();}else sync();}
        catch(IOException|RuntimeException error){busy=false;status.setText(DownloadFailure.describe("Iniciar conversão",error));controls();}
    }
    private void cancel(){ChapterExportService.Snapshot state=ChapterExportService.state(this);if(state!=null&&state.running&&state.job.matches(source,stamp,start,end)){ChapterExportService.cancel(this,state);status.setText("Cancelando conversão…");}}
    @Override protected void onStop(){started=false;ChapterExportService.unlisten(listener);super.onStop();}
    @Override protected void onNewIntent(Intent intent){super.onNewIntent(intent);setIntent(intent);pending=null;saved=null;recreate();}
    @Override protected void onSaveInstanceState(Bundle state){super.onSaveInstanceState(state);if(pending!=null)state.putString("pending",pending.toString());if(saved!=null)state.putString("saved",saved.toString());}
}
