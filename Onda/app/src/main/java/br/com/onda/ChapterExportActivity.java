package br.com.onda;

import android.app.*;
import android.content.*;
import android.net.Uri;
import android.os.*;
import android.view.*;
import android.widget.*;
import java.io.*;
import java.util.concurrent.*;

/** Explicit local export. No service, network request, wake lock, or background scan. */
public class ChapterExportActivity extends Activity {
    private static final int CREATE=71;
    private final Handler main=new Handler(Looper.getMainLooper());
    private final ExecutorService worker=Executors.newSingleThreadExecutor();
    private Future<?> task;private volatile int generation;private boolean started,busy;
    private Uri source,pending,saved;private String stamp,name;private long start,end,duration;
    private TextView status;private Button export,quality,share;private ProgressBar progress;
    static void open(Context context,Uri uri,String stamp,AudioChapterStore.Data data,int index){
        context.startActivity(new Intent(context,ChapterExportActivity.class).setData(uri).putExtra("stamp",stamp).putExtra("name",AudioChapterStore.label(data,index)).putExtra("start",data.chapters.get(index).start).putExtra("end",index+1<data.chapters.size()?data.chapters.get(index+1).start:data.duration).putExtra("duration",data.duration));
    }
    @Override public void onCreate(Bundle state){
        super.onCreate(state);Intent input=getIntent();source=input.getData();stamp=input.getStringExtra("stamp");name=input.getStringExtra("name");start=input.getLongExtra("start",-1);end=input.getLongExtra("end",-1);duration=input.getLongExtra("duration",0);
        if(state!=null){String uri=state.getString("pending"),complete=state.getString("saved");pending=uri==null?null:Uri.parse(uri);saved=complete==null?null:Uri.parse(complete);}
        LinearLayout root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);Ui.background(root);root.setOnApplyWindowInsetsListener((v,i)->{root.setPadding(Ui.dp(this,16),Ui.dp(this,8)+i.getSystemWindowInsetTop(),Ui.dp(this,16),Ui.dp(this,8)+i.getSystemWindowInsetBottom());return i;});setContentView(root);
        LinearLayout header=new LinearLayout(this);header.setGravity(Gravity.CENTER_VERTICAL);header.addView(Ui.button(this,"‹",v->finish()),new LinearLayout.LayoutParams(Ui.dp(this,48),-2));TextView heading=Ui.text(this,"Salvar faixa em MP3",20,Ui.TEXT);heading.setMaxLines(2);header.addView(heading,new LinearLayout.LayoutParams(0,-2,1));root.addView(header);
        ScrollView scroll=new ScrollView(this);LinearLayout body=new LinearLayout(this);body.setOrientation(LinearLayout.VERTICAL);scroll.addView(body);root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
        body.addView(Ui.text(this,name==null?"Escolha uma faixa na tela de coletâneas.":name,20,Ui.CYAN));
        if(validInput())body.addView(Ui.text(this,ChapterEdits.format(start)+" → "+ChapterEdits.format(end),16,Ui.TEXT));
        body.addView(Ui.text(this,"Cria um novo arquivo com apenas este trecho. O áudio original é preservado. A conversão ocorre no celular; mantenha esta tela aberta. Sair cancela e remove a cópia incompleta.",15,Ui.MUTED));
        quality=Ui.button(this,"",v->Mp3Quality.show(this,this::controls));body.addView(quality);
        export=Ui.button(this,"Salvar MP3",v->{if(busy){cancel();return;}Intent create=new Intent(Intent.ACTION_CREATE_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType("audio/mpeg").putExtra(Intent.EXTRA_TITLE,safeName(name)+".mp3");try{startActivityForResult(create,CREATE);}catch(ActivityNotFoundException error){status.setText("Nenhum seletor de arquivos disponível neste celular.");}});Ui.primary(export);body.addView(export);
        progress=new ProgressBar(this,null,android.R.attr.progressBarStyleHorizontal);progress.setMax(100);body.addView(progress,new LinearLayout.LayoutParams(-1,Ui.dp(this,16)));
        status=Ui.text(this,validInput()?"Escolha onde salvar a nova faixa.":"Abra Faixas da coletânea, toque em ⋮ e escolha Salvar faixa em MP3.",15,Ui.TEXT);body.addView(status);
        share=Ui.button(this,"Compartilhar MP3 salvo",v->{if(saved==null)return;Intent send=new Intent(Intent.ACTION_SEND).setType("audio/mpeg").putExtra(Intent.EXTRA_STREAM,saved).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);send.setClipData(ClipData.newRawUri("Faixa MP3",saved));try{startActivity(Intent.createChooser(send,"Compartilhar faixa"));}catch(ActivityNotFoundException error){status.setText("Nenhum aplicativo disponível para compartilhar.");}});body.addView(share);controls();
    }
    private static String safeName(String value){String result=value==null?"Faixa":value.replaceAll("[\\\\/:*?\"<>|\\p{Cntrl}]","_").trim();return result.isEmpty()?"Faixa":result.substring(0,Math.min(100,result.length()));}
    private boolean validInput(){return source!=null&&("file".equals(source.getScheme())||"content".equals(source.getScheme()))&&stamp!=null&&start>=0&&end>start&&end<=duration;}
    private void controls(){if(export==null)return;export.setEnabled(validInput());export.setText(busy?"Cancelar conversão":"Salvar MP3");quality.setText("Qualidade: "+Mp3Quality.get(this)+" kbps");quality.setEnabled(!busy);progress.setVisibility(busy?View.VISIBLE:View.GONE);share.setVisibility(saved==null?View.GONE:View.VISIBLE);}
    @Override protected void onActivityResult(int request,int result,Intent data){super.onActivityResult(request,result,data);if(request==CREATE&&result==RESULT_OK&&data!=null){Uri target=data.getData();if(target!=null&&target.equals(source)){status.setText("Escolha um novo arquivo; não sobrescreva a coletânea.");return;}pending=target;}}
    @Override protected void onResume(){super.onResume();started=true;if(pending!=null&&!busy){Uri target=pending;pending=null;convert(target);}}
    private void convert(Uri target){
        if(!validInput())return;busy=true;saved=null;int request=++generation,bitrate=Mp3Quality.get(this);progress.setProgress(0);status.setText("Convertendo somente o trecho escolhido…");controls();
        task=worker.submit(()->{File temporary=null;boolean complete=false,canDelete=false;try{
            ChapterMp3Exporter.Control control=new ChapterMp3Exporter.Control(){public void check()throws IOException{if(Thread.currentThread().isInterrupted()||generation!=request)throw new InterruptedIOException("Conversão cancelada");}public void progress(long at,long total){main.post(()->{if(!started||request!=generation)return;progress.setProgress((int)Math.min(100,at*100/Math.max(1,total)));});}};
            control.check();if(!stamp.equals(AudioChapterStore.stamp(this,source)))throw new IOException("O arquivo original mudou. Selecione a faixa novamente.");
            AudioChapterStore.Data data=AudioChapterStore.load(this,source,stamp,duration);boolean matching=false;
            if(data!=null)for(int i=0;i<data.chapters.size();i++)if(data.chapters.get(i).start==start&&(i+1<data.chapters.size()?data.chapters.get(i+1).start:data.duration)==end)matching=true;
            if(!matching)throw new IOException("Os horários foram alterados. Selecione a faixa novamente.");
            try(android.content.res.AssetFileDescriptor original=getContentResolver().openAssetFileDescriptor(source,"r");android.content.res.AssetFileDescriptor destination=getContentResolver().openAssetFileDescriptor(target,"r")){
                if(original==null||destination==null)throw new IOException("Não foi possível conferir o destino");
                android.system.StructStat a=android.system.Os.fstat(original.getFileDescriptor()),b=android.system.Os.fstat(destination.getFileDescriptor());
                if(a.st_dev==b.st_dev&&a.st_ino==b.st_ino||b.st_size>0)throw new IOException("Escolha um novo arquivo vazio; o original não será sobrescrito.");
            }
            canDelete=true;
            temporary=File.createTempFile("chapter-export-",".mp3",getCacheDir());
            try(MediaInput.Direct direct=MediaInput.open(this,source)){if(direct==null)throw new IOException("Este arquivo não permite leitura direta. Salve-o no celular e tente novamente.");ChapterMp3Exporter.convert(direct,temporary,bitrate,start,end,control);}
            control.check();if(!stamp.equals(AudioChapterStore.stamp(this,source)))throw new IOException("O arquivo original mudou durante a conversão.");
            try(InputStream in=new BufferedInputStream(new FileInputStream(temporary));OutputStream out=getContentResolver().openOutputStream(target,"wt")){if(out==null)throw new IOException("Não foi possível abrir o destino");byte[] buffer=new byte[65536];int n;while((n=in.read(buffer))!=-1){control.check();out.write(buffer,0,n);}out.flush();}
            control.check();complete=true;main.post(()->{if(!started||request!=generation)return;busy=false;saved=target;status.setText("Faixa MP3 salva. O arquivo original foi preservado.");controls();});
        }catch(Exception error){main.post(()->{if(!started||request!=generation)return;busy=false;status.setText(DownloadFailure.describe("Salvar faixa",error));controls();});}finally{if(temporary!=null)temporary.delete();if(!complete&&canDelete)try{android.provider.DocumentsContract.deleteDocument(getContentResolver(),target);}catch(Exception ignored){}}});
    }
    private void cancel(){generation++;if(task!=null){task.cancel(true);task=null;}busy=false;status.setText("Conversão cancelada. O original foi preservado.");controls();}
    @Override protected void onStop(){started=false;if(busy)cancel();super.onStop();}
    @Override protected void onSaveInstanceState(Bundle state){super.onSaveInstanceState(state);if(pending!=null)state.putString("pending",pending.toString());if(saved!=null)state.putString("saved",saved.toString());}
    @Override protected void onDestroy(){generation++;if(task!=null)task.cancel(true);worker.shutdownNow();main.removeCallbacksAndMessages(null);super.onDestroy();}
}
