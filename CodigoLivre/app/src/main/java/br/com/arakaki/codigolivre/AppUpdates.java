package br.com.arakaki.codigolivre;

import android.app.*;
import android.content.*;
import android.content.pm.*;
import android.net.Uri;
import android.os.*;
import android.provider.Settings;
import android.widget.*;
import java.io.*;
import java.net.*;
import javax.net.ssl.HttpsURLConnection;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.*;
import java.util.*;
import java.util.concurrent.*;
import org.json.JSONObject;

final class AppUpdates {
    private static final String INDEX="https://raw.githubusercontent.com/cristianoarakaki-cpu/Arakaki/entrega/codigo-livre-android-offline/CodigoLivre/update.json";
    private static final ExecutorService NETWORK=Executors.newSingleThreadExecutor();
    private final Activity activity;private final java.util.function.BooleanSupplier idle;private volatile boolean closed,working,cancelDownload;private boolean awaitInstall;
    private UpdatePolicy.Info downloaded;
    AppUpdates(Activity activity,java.util.function.BooleanSupplier idle){this.activity=activity;this.idle=idle;
        try{File meta=new File(activity.getFilesDir(),"updates/release.json");if(meta.exists()&&UpdateProvider.apk(activity).exists()){JSONObject j=new JSONObject(new String(Files.readAllBytes(meta.toPath()),StandardCharsets.UTF_8));UpdatePolicy.Info saved=parse(j);if(saved.newerThan(installed()))downloaded=saved;else{meta.delete();UpdateProvider.apk(activity).delete();}}}catch(Exception ignored){}
    }
    private UpdatePolicy.Info parse(JSONObject j)throws Exception{return new UpdatePolicy.Info(j.getLong("versionCode"),j.getString("versionName"),j.getString("url"),j.getString("sha256"),j.getLong("bytes"),j.getString("packageName"),j.optString("notes"));}
    private void ui(Runnable r){activity.runOnUiThread(()->{if(!closed&&!activity.isFinishing())r.run();});}
    private SharedPreferences prefs(){return activity.getSharedPreferences("atualizacoes",Context.MODE_PRIVATE);}
    void automatic(){if(!working&&prefs().getBoolean("automatic",false)&&System.currentTimeMillis()-prefs().getLong("last",0)>24*60*60*1000L){prefs().edit().putLong("last",System.currentTimeMillis()).apply();check(false);}}
    void menu(){
        Switch toggle=new Switch(activity);toggle.setPadding(32,24,32,24);toggle.setText("Verificar ao abrir (até uma vez por dia)");toggle.setTextColor(android.graphics.Color.WHITE);toggle.setChecked(prefs().getBoolean("automatic",false));toggle.setOnCheckedChangeListener((v,on)->prefs().edit().putBoolean("automatic",on).apply());
        String version;try{version=activity.getPackageManager().getPackageInfo(activity.getPackageName(),0).versionName;}catch(Exception e){version="?";}
        AlertDialog.Builder b=new AlertDialog.Builder(activity).setTitle("Atualizações · versão "+version).setMessage("A IA continua local. Somente a verificação e o download acessam o GitHub, sem enviar perguntas ou arquivos. A instalação é confirmada pelo Android e preserva os dados quando o pacote e a assinatura são os mesmos.\n\nA verificação automática é opcional e acontece ao abrir o app; o download começa após seu toque.").setView(toggle).setPositiveButton("Verificar agora",(d,w)->check(true)).setNegativeButton("Fechar",null);
        if(downloaded!=null)b.setNeutralButton("Instalar baixada",(d,w)->install());b.show();
    }
    private long installed()throws Exception{return activity.getPackageManager().getPackageInfo(activity.getPackageName(),0).getLongVersionCode();}
    private static HttpsURLConnection connection(String url)throws IOException{
        UpdatePolicy.trusted(url);HttpsURLConnection c=(HttpsURLConnection)new URL(url).openConnection();c.setConnectTimeout(15000);c.setReadTimeout(30000);c.setInstanceFollowRedirects(false);c.setRequestProperty("User-Agent","CodigoLivre-Android-Updater");
        if(c.getResponseCode()!=200){int status=c.getResponseCode();c.disconnect();throw new IOException("Servidor respondeu HTTP "+status+". Tente novamente mais tarde.");}return c;
    }
    private void check(boolean manual){
        if(working){Toast.makeText(activity,"Já há uma verificação ou download em andamento.",Toast.LENGTH_SHORT).show();return;}working=true;
        if(manual)Toast.makeText(activity,"Verificando atualizações…",Toast.LENGTH_SHORT).show();
        NETWORK.execute(()->{
            try{HttpsURLConnection c=connection(INDEX);String text;try(InputStream in=c.getInputStream()){text=new String(CodeFiles.read(in,128*1024),StandardCharsets.UTF_8);}finally{c.disconnect();}
                JSONObject j=new JSONObject(text);UpdatePolicy.Info info=parse(j);
                prefs().edit().putLong("last",System.currentTimeMillis()).apply();working=false;
                if(info.newerThan(installed()))ui(()->new AlertDialog.Builder(activity).setTitle("Nova versão "+info.name).setMessage(info.notes+"\n\nDownload: "+String.format(Locale.ROOT,"%.1f MB",info.bytes/1e6)+". O Android solicitará a confirmação da instalação.").setPositiveButton("Baixar",(d,w)->download(info)).setNegativeButton("Depois",null).show());
                else if(manual)ui(()->new AlertDialog.Builder(activity).setMessage("Você já está na versão disponível neste canal.").setPositiveButton("OK",null).show());
            }catch(Exception e){working=false;if(manual)ui(()->error(e));}
        });
    }
    private void download(UpdatePolicy.Info info){
        if(working)return;working=true;cancelDownload=false;
        LinearLayout content=new LinearLayout(activity);content.setOrientation(LinearLayout.VERTICAL);content.setPadding(32,24,32,24);ProgressBar bar=new ProgressBar(activity,null,android.R.attr.progressBarStyleHorizontal);bar.setMax(100);content.addView(bar);TextView label=new TextView(activity);label.setTextColor(android.graphics.Color.WHITE);content.addView(label);
        AlertDialog dialog=new AlertDialog.Builder(activity).setTitle("Baixando atualização "+info.name).setView(content).setCancelable(false).setNegativeButton("Cancelar",(d,w)->cancelDownload=true).create();dialog.show();
        NETWORK.execute(()->{File temp=new File(activity.getFilesDir(),"updates/download.tmp");
            try{temp.getParentFile().mkdirs();MessageDigest hash=MessageDigest.getInstance("SHA-256");HttpsURLConnection c=connection(info.url);long total=0,last=0;
                try(InputStream in=c.getInputStream();FileOutputStream out=new FileOutputStream(temp)){byte[] buffer=new byte[65536];int n;while((n=in.read(buffer))!=-1){if(closed||cancelDownload)throw new IOException("Download interrompido.");total+=n;if(total>info.bytes||total>UpdatePolicy.MAX_APK)throw new IOException("Tamanho do APK diferente do esperado.");hash.update(buffer,0,n);out.write(buffer,0,n);long now=SystemClock.elapsedRealtime();if(now-last>200){last=now;int percent=(int)(100L*total/info.bytes);long count=total;ui(()->{bar.setProgress(percent);label.setText(String.format(Locale.ROOT,"%d%% · %.1f / %.1f MB",percent,count/1e6,info.bytes/1e6));});}}out.getFD().sync();}finally{c.disconnect();}
                if(closed||cancelDownload)throw new IOException("Download interrompido.");
                if(total!=info.bytes||!UpdatePolicy.validDigest(info.sha,hash.digest()))throw new IOException("O arquivo não passou na verificação SHA256/tamanho. Nenhuma instalação foi iniciada.");
                verify(temp,info);Files.move(temp.toPath(),UpdateProvider.apk(activity).toPath(),StandardCopyOption.REPLACE_EXISTING,StandardCopyOption.ATOMIC_MOVE);JSONObject metadata=new JSONObject();metadata.put("versionCode",info.version);metadata.put("versionName",info.name);metadata.put("url",info.url);metadata.put("sha256",info.sha);metadata.put("bytes",info.bytes);metadata.put("packageName",UpdatePolicy.PACKAGE);metadata.put("notes",info.notes);
                File metaTemp=new File(activity.getFilesDir(),"updates/release.tmp");try(FileOutputStream m=new FileOutputStream(metaTemp)){m.write(metadata.toString().getBytes(StandardCharsets.UTF_8));}Files.move(metaTemp.toPath(),new File(activity.getFilesDir(),"updates/release.json").toPath(),StandardCopyOption.REPLACE_EXISTING,StandardCopyOption.ATOMIC_MOVE);downloaded=info;
                ui(()->{dialog.dismiss();new AlertDialog.Builder(activity).setTitle("Atualização verificada").setMessage("Versão "+info.name+" baixada. Assinatura, pacote, versão e SHA256 conferidos. A instalação fecha o aplicativo; finalize a análise antes de instalar.").setPositiveButton("Instalar",(d,w)->install()).setNegativeButton("Depois",null).show();});
            }catch(Exception e){ui(()->{dialog.dismiss();if(!cancelDownload)error(e);});}finally{temp.delete();working=false;}
        });
    }
    private List<String> signers(PackageInfo p)throws Exception{List<String> result=new ArrayList<>();if(p.signingInfo==null)throw new IOException("Assinatura ausente no pacote.");for(android.content.pm.Signature s:p.signingInfo.getApkContentsSigners())result.add(UpdatePolicy.hex(MessageDigest.getInstance("SHA-256").digest(s.toByteArray())));return result;}
    private void verify(File apk,UpdatePolicy.Info info)throws Exception{
        PackageManager pm=activity.getPackageManager();PackageInfo candidate=pm.getPackageArchiveInfo(apk.getAbsolutePath(),PackageManager.GET_SIGNING_CERTIFICATES),current=pm.getPackageInfo(activity.getPackageName(),PackageManager.GET_SIGNING_CERTIFICATES);
        if(candidate==null||!activity.getPackageName().equals(candidate.packageName)||candidate.getLongVersionCode()!=info.version||!info.name.equals(candidate.versionName)||candidate.getLongVersionCode()<=current.getLongVersionCode()||!UpdatePolicy.sameSigners(signers(current),signers(candidate)))throw new IOException("APK incompatível, assinatura diferente ou versão inválida. Atualização recusada.");
    }
    private void install(){
        if(downloaded==null)return;
        if(!idle.getAsBoolean()){new AlertDialog.Builder(activity).setMessage("Finalize a operação atual antes de instalar. O APK já está baixado; use Atualizações → Instalar baixada depois.").setPositiveButton("OK",null).show();return;}
        try{verify(UpdateProvider.apk(activity),downloaded);
            if(!activity.getPackageManager().canRequestPackageInstalls()){awaitInstall=true;activity.startActivity(new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,Uri.parse("package:"+activity.getPackageName())));Toast.makeText(activity,"Autorize a instalação deste app e volte para confirmar.",Toast.LENGTH_LONG).show();return;}
            Intent intent=new Intent(Intent.ACTION_VIEW).setDataAndType(UpdateProvider.URI,"application/vnd.android.package-archive").addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);intent.setClipData(ClipData.newRawUri("Atualização verificada",UpdateProvider.URI));activity.startActivity(intent);
        }catch(Exception e){error(e);}
    }
    void resume(){if(awaitInstall){awaitInstall=false;if(activity.getPackageManager().canRequestPackageInstalls())install();}}
    void close(){closed=true;}
    private void error(Exception e){new AlertDialog.Builder(activity).setTitle("Atualização não concluída").setMessage((e.getMessage()==null?e.getClass().getSimpleName():e.getMessage())+"\n\nA IA e seus arquivos continuam disponíveis offline.").setPositiveButton("OK",null).show();}
}
