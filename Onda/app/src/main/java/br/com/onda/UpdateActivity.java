package br.com.onda;

import android.app.*;
import android.content.*;
import android.net.Uri;
import android.os.*;
import android.provider.Settings;
import android.graphics.Color;
import android.view.*;
import android.widget.*;
import androidx.core.content.FileProvider;
import java.io.File;
import java.util.concurrent.*;

public class UpdateActivity extends Activity {
    private final Handler handler=new Handler(Looper.getMainLooper());
    private final ExecutorService worker=Executors.newSingleThreadExecutor();
    private TextView status;
    private Button action;
    private ProgressBar progress;
    private UpdateRepository.Update available;
    private File ready;
    private int currentVersion;
    private boolean awaitingPermission=false;
    @Override public void onCreate(Bundle state){
        super.onCreate(state);LinearLayout root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);Ui.background(root);
        root.setOnApplyWindowInsetsListener((v,i)->{root.setPadding(Ui.dp(this,20),Ui.dp(this,12)+i.getSystemWindowInsetTop(),Ui.dp(this,20),Ui.dp(this,12)+i.getSystemWindowInsetBottom());return i;});setContentView(root);
        Button back=Ui.button(this,"‹ Biblioteca",v->finish());Ui.ghost(back);back.setGravity(Gravity.START|Gravity.CENTER_VERTICAL);root.addView(back);root.addView(Ui.art(this,64,0));
        TextView heading=label("Atualizações do Onda",26);root.addView(heading);
        try{android.content.pm.PackageInfo info=getPackageManager().getPackageInfo(getPackageName(),0);currentVersion=info.versionCode;root.addView(label("Versão instalada: "+info.versionName,16));}catch(Exception ignored){}
        root.addView(label("Atualize mantendo suas músicas e favoritos. O Android vai pedir sua confirmação para instalar.",16));
        status=label("Toque abaixo para consultar as versões disponíveis.",16);status.setPadding(Ui.dp(this,16),Ui.dp(this,16),Ui.dp(this,16),Ui.dp(this,16));Ui.card(status,false);root.addView(status);
        progress=new ProgressBar(this,null,android.R.attr.progressBarStyleHorizontal);progress.setMax(100);progress.setVisibility(View.GONE);root.addView(progress);
        action=Ui.button(this,"Verificar atualizações",null);Ui.primary(action);action.setOnClickListener(v->{if(ready!=null)install();else if(available!=null)download();else check();});LinearLayout.LayoutParams actionParams=new LinearLayout.LayoutParams(-1,Ui.dp(this,52));actionParams.topMargin=Ui.dp(this,16);root.addView(action,actionParams);
        root.addView(label("Downloads exigem internet. A instalação é confirmada pelo Android e preserva os dados deste Onda Música.",13));
    }
    private TextView label(String s,int size){TextView t=Ui.text(this,s,size,size>=24?Ui.TEXT:Ui.MUTED);t.setPadding(0,Ui.dp(this,10),0,Ui.dp(this,10));if(size>=24)Ui.bold(t);return t;}
    private void check(){action.setEnabled(false);status.setText("Consultando atualizações…");worker.submit(()->{try{UpdateRepository.Update update=UpdateRepository.latest(getPackageName());handler.post(()->{if(isDestroyed())return;action.setEnabled(true);if(update==null||update.code<=currentVersion){status.setText("Seu Onda está atualizado.");action.setText("Verificar novamente");}else{available=update;status.setText("Nova versão disponível: "+update.version);action.setText("Baixar versão "+update.version);}});}catch(Exception e){failed("Não foi possível consultar. Verifique a internet ou tente mais tarde.");}});}
    private void download(){action.setEnabled(false);progress.setVisibility(View.VISIBLE);progress.setIndeterminate(true);status.setText("Baixando atualização…");UpdateRepository.Update update=available;
        worker.submit(()->{try{File apk=UpdateRepository.download(getApplicationContext(),update,(bytes,total)->handler.post(()->{if(isDestroyed())return;if(total>0){progress.setIndeterminate(false);progress.setProgress((int)(100*bytes/total));}status.setText("Baixando atualização: "+String.format(java.util.Locale.getDefault(),"%.1f MB",bytes/1048576.0));}));handler.post(()->{if(isDestroyed())return;ready=apk;progress.setVisibility(View.GONE);action.setEnabled(true);action.setText("Instalar atualização");status.setText("Download conferido. Toque em Instalar atualização para continuar.");});}catch(Exception e){failed("Não foi possível preparar a atualização. "+e.getMessage());}});
    }
    private void install(){
        if(ready==null||!ready.isFile()){ready=null;action.setText("Baixar atualização");status.setText("O download foi removido. Baixe novamente.");return;}
        if(!getPackageManager().canRequestPackageInstalls()){
            new AlertDialog.Builder(this).setTitle("Permitir atualização pelo Onda").setMessage("Na próxima tela, permita que o Onda Música instale atualizações. Depois volte para confirmar a instalação.").setPositiveButton("Abrir configurações",(d,w)->{try{awaitingPermission=true;startActivity(new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,Uri.parse("package:"+getPackageName())));}catch(ActivityNotFoundException e){awaitingPermission=false;status.setText("Abra as configurações do Android e permita instalar apps por esta origem.");}}).setNegativeButton("Agora não",null).show();return;
        }
        try{Uri uri=FileProvider.getUriForFile(this,getPackageName()+".updates",ready);Intent intent=new Intent(Intent.ACTION_VIEW).setDataAndType(uri,"application/vnd.android.package-archive").addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);startActivity(intent);}catch(Exception e){status.setText("Não foi possível abrir o instalador do Android. Tente novamente.");}
    }
    private void failed(String message){handler.post(()->{if(isDestroyed())return;progress.setVisibility(View.GONE);action.setEnabled(true);status.setText(message);});}
    @Override protected void onResume(){super.onResume();if(awaitingPermission){awaitingPermission=false;if(getPackageManager().canRequestPackageInstalls())install();else status.setText("A permissão não foi concedida. Você pode tentar novamente quando quiser.");}}
    @Override public void onDestroy(){worker.shutdownNow();handler.removeCallbacksAndMessages(null);super.onDestroy();}
}
