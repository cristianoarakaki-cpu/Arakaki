package com.arakaki.prismavoz;

import android.app.*;
import android.content.*;
import android.database.Cursor;
import android.net.*;
import android.os.*;
import android.provider.OpenableColumns;
import android.util.Base64;
import android.webkit.*;
import android.widget.Toast;
import org.json.JSONObject;
import java.io.*;
import java.util.*;
import java.util.concurrent.atomic.AtomicBoolean;

public final class MainActivity extends Activity {
    static final String HOST="appassets.androidplatform.net";
    static final int LIMIT=25*1024*1024;
    private WebView web;
    private ValueCallback<Uri[]> chooser;
    private volatile boolean ready;
    private String pendingName,pendingData;
    private volatile SpeechCatalog catalog;
    private final AtomicBoolean preparingSpeech=new AtomicBoolean(false), importing=new AtomicBoolean(false);
    private UpdateManager updater;
    @Override public void onCreate(Bundle state){
        super.onCreate(state);
        web=new WebView(this);setContentView(web);web.setBackgroundColor(0xfff4f6fb);
        if(Build.VERSION.SDK_INT>=35)web.setOnApplyWindowInsetsListener((v,i)->{android.graphics.Insets b=i.getInsets(android.view.WindowInsets.Type.systemBars()|android.view.WindowInsets.Type.displayCutout());v.setPadding(b.left,b.top,b.right,b.bottom);return i;});
        WebSettings s=web.getSettings();s.setJavaScriptEnabled(true);s.setDomStorageEnabled(true);s.setAllowFileAccess(false);s.setAllowContentAccess(true);s.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);
        web.addJavascriptInterface(new Bridge(),"PrismAndroid");
        web.setWebViewClient(new WebViewClient(){
            @Override public boolean shouldOverrideUrlLoading(WebView v,WebResourceRequest r){return !local(r.getUrl());}
            @Override public WebResourceResponse shouldInterceptRequest(WebView v,WebResourceRequest r){return asset(r.getUrl());}
            @Override public void onPageFinished(WebView v,String url){ready=true;deliverPending();updater.checkAutomatic();}
        });
        web.setWebChromeClient(new WebChromeClient(){@Override public boolean onShowFileChooser(WebView v,ValueCallback<Uri[]> callback,FileChooserParams params){
            if(chooser!=null)chooser.onReceiveValue(null);chooser=callback;
            Intent i=new Intent(Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType("application/pdf");
            try{startActivityForResult(i,10);}catch(Exception e){chooser.onReceiveValue(null);chooser=null;notice("Nenhum seletor de documentos disponível.");}return true;
        }});
        updater=new UpdateManager(this);web.loadUrl("https://"+HOST+"/index.html");receive(getIntent());
    }
    boolean local(Uri uri){return "https".equals(uri.getScheme())&&HOST.equals(uri.getHost());}
    private WebResourceResponse asset(Uri uri){
        if(!local(uri)||uri.getPath()==null||uri.getPath().contains(".."))return response(403);
        String path=uri.getPath();if(path.equals("/"))path="/index.html";
        String mime=path.endsWith(".js")?"application/javascript":path.endsWith(".css")?"text/css":path.endsWith(".html")?"text/html":path.endsWith(".wasm")?"application/wasm":"application/octet-stream";
        try{return new WebResourceResponse(mime,"UTF-8",200,"OK",Collections.emptyMap(),getAssets().open(path.substring(1)));}catch(IOException e){return response(404);}
    }
    private WebResourceResponse response(int code){return new WebResourceResponse("text/plain","UTF-8",code,code==403?"Forbidden":"Not Found",Collections.emptyMap(),new ByteArrayInputStream(new byte[0]));}
    boolean online(){return getPreferences(0).getBoolean("online",false);}
    boolean connected(){ConnectivityManager c=(ConnectivityManager)getSystemService(CONNECTIVITY_SERVICE);Network n=c.getActiveNetwork();NetworkCapabilities caps=c.getNetworkCapabilities(n);return caps!=null&&caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET);}
    void notice(String text){runOnUiThread(()->{if(isFinishing()||isDestroyed())return;Toast.makeText(this,text,Toast.LENGTH_LONG).show();if(ready)web.evaluateJavascript("window.PrismaNotice&&window.PrismaNotice("+JSONObject.quote(text)+")",null);});}
    static byte[] readLimited(InputStream in,int max)throws IOException{try(InputStream source=in;ByteArrayOutputStream out=new ByteArrayOutputStream()){if(source==null)throw new IOException("Arquivo indisponível.");byte[] buffer=new byte[32768];int n;while((n=source.read(buffer))!=-1){if(out.size()+n>max)throw new IOException("Arquivo maior que o limite permitido.");out.write(buffer,0,n);}return out.toByteArray();}}
    private void deliverPending(){if(!ready||pendingData==null)return;String data=pendingData,name=pendingName;pendingData=null;pendingName=null;web.evaluateJavascript("window.PrismaReceive&&window.PrismaReceive("+JSONObject.quote(name)+","+JSONObject.quote(data)+")",null);}
    private void receive(Intent intent){
        if(intent==null)return;Uri uri=Intent.ACTION_VIEW.equals(intent.getAction())?intent.getData():Intent.ACTION_SEND.equals(intent.getAction())?intent.getParcelableExtra(Intent.EXTRA_STREAM):null;
        if(uri==null)return;if(!"content".equals(uri.getScheme())){notice("Abra o PDF pelo seletor de documentos.");return;}
        final Uri source=uri;if(!importing.compareAndSet(false,true)){notice("Aguarde a abertura do PDF.");return;}
        new Thread(()->{try{byte[] data=readLimited(getContentResolver().openInputStream(source),LIMIT);if(!new String(data,0,Math.min(data.length,1024),"ISO-8859-1").contains("%PDF-"))throw new IOException("Este arquivo não é um PDF.");String name="documento.pdf";try(Cursor c=getContentResolver().query(source,new String[]{OpenableColumns.DISPLAY_NAME},null,null,null)){if(c!=null&&c.moveToFirst())name=c.getString(0);}final String finalName=name,encoded=Base64.encodeToString(data,Base64.NO_WRAP);runOnUiThread(()->{pendingName=finalName;pendingData=encoded;deliverPending();});}catch(Exception e){notice(e.getMessage()==null?"Não foi possível abrir o PDF.":e.getMessage());}finally{importing.set(false);}},"voice-open-pdf").start();
    }
    public final class Bridge {
        @JavascriptInterface public String state(){try{return new JSONObject().put("version",getPackageManager().getPackageInfo(getPackageName(),0).versionName).put("onlineAllowed",online()).put("connected",connected()).toString();}catch(Exception e){return "{}";}}
        @JavascriptInterface public void allowOnline(boolean allowed){getPreferences(0).edit().putBoolean("online",allowed).apply();if(!allowed)runOnUiThread(()->SpeechService.stopIfNetwork(MainActivity.this));else runOnUiThread(()->updater.checkAutomatic());}
        @JavascriptInterface public void checkUpdates(){runOnUiThread(()->updater.check());}
        @JavascriptInterface public String speechVoices(){if(catalog==null)runOnUiThread(()->{if(catalog==null&&!isDestroyed())catalog=new SpeechCatalog(MainActivity.this);});return catalog==null?"{\"ready\":false,\"voices\":[]}":catalog.state();}
        @JavascriptInterface public void speechSettings(){runOnUiThread(()->{try{startActivity(new Intent("com.android.settings.TTS_SETTINGS"));}catch(Exception e){try{startActivity(new Intent(android.provider.Settings.ACTION_SETTINGS));}catch(Exception ignored){notice("Abra as configurações de texto para fala do Android.");}}});}
        @JavascriptInterface public String speechState(){return SpeechService.state();}
        @JavascriptInterface public void speechStop(){runOnUiThread(()->{new File(getCacheDir(),"speech-input.json").delete();stopService(new Intent(MainActivity.this,SpeechService.class));});}
        @JavascriptInterface public void speechCommand(String command){if(!"pause".equals(command)&&!"resume".equals(command))return;runOnUiThread(()->{try{String status=new JSONObject(SpeechService.state()).optString("status");if(!"playing".equals(status)&&!"paused".equals(status)&&!"preparing".equals(status))return;startService(new Intent(MainActivity.this,SpeechService.class).setAction("pause".equals(command)?SpeechService.PAUSE:SpeechService.RESUME));}catch(Exception e){notice("Não foi possível controlar a leitura.");}});}
        @JavascriptInterface public void speechStart(String payload){
            if(payload==null||payload.length()>1500000||!preparingSpeech.compareAndSet(false,true)){notice("Aguarde a preparação da leitura ou escolha menos páginas.");return;}
            try{JSONObject data=new JSONObject(payload);if(data.optBoolean("allowNetwork",false)&&!online())throw new IOException("Ative as ações online antes de usar uma voz online.");
                try(FileOutputStream out=new FileOutputStream(new File(getCacheDir(),"speech-input.json"))){out.write(payload.getBytes("UTF-8"));}
                runOnUiThread(()->{try{if(isFinishing()||isDestroyed()){new File(getCacheDir(),"speech-input.json").delete();return;}
                    if(Build.VERSION.SDK_INT>=33&&checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS)!=android.content.pm.PackageManager.PERMISSION_GRANTED)requestPermissions(new String[]{android.Manifest.permission.POST_NOTIFICATIONS},41);
                    startForegroundService(new Intent(MainActivity.this,SpeechService.class).setAction(SpeechService.START));
                }catch(Exception e){new File(getCacheDir(),"speech-input.json").delete();SpeechService.startError(data.optString("session",""),"Não foi possível iniciar a leitura. Mantenha o app aberto e tente novamente.");}finally{preparingSpeech.set(false);}});
            }catch(Exception e){preparingSpeech.set(false);String session="";try{session=new JSONObject(payload).optString("session","");}catch(Exception ignored){}SpeechService.startError(session,e.getMessage()==null?"Não foi possível preparar a leitura.":e.getMessage());}
        }
    }
    @Override protected void onResume(){super.onResume();if(catalog!=null){catalog.close();catalog=null;}if(updater!=null&&ready)updater.checkAutomatic();if(ready)web.evaluateJavascript("window.PrismaSpeech&&window.PrismaSpeech.refreshVoices()",null);}
    @Override protected void onActivityResult(int request,int result,Intent data){super.onActivityResult(request,result,data);if(request==10&&chooser!=null){chooser.onReceiveValue(result==RESULT_OK&&data!=null&&data.getData()!=null?new Uri[]{data.getData()}:null);chooser=null;}if(request==12)updater.install();}
    @Override protected void onNewIntent(Intent intent){super.onNewIntent(intent);if(Intent.ACTION_VIEW.equals(intent.getAction())||Intent.ACTION_SEND.equals(intent.getAction()))new AlertDialog.Builder(this).setTitle("Abrir outro PDF?").setMessage("A leitura atual será interrompida ao abrir o novo documento.").setPositiveButton("Abrir",(d,w)->receive(intent)).setNegativeButton("Cancelar",null).show();}
    @Override public void onBackPressed(){new AlertDialog.Builder(this).setTitle("Sair do Prisma Voz?").setMessage("A leitura em andamento pode continuar pela notificação.").setPositiveButton("Sair",(d,w)->finish()).setNegativeButton("Ficar",null).show();}
    @Override protected void onDestroy(){ready=false;if(catalog!=null)catalog.close();if(chooser!=null)chooser.onReceiveValue(null);web.removeJavascriptInterface("PrismAndroid");web.destroy();super.onDestroy();}
}
