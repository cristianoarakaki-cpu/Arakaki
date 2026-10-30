package br.com.onda;
import android.app.*;
import android.content.*;
import android.net.Uri;
import android.os.Bundle;
import android.view.*;
import android.webkit.*;
import android.widget.*;

/** Official mobile website in the foreground only. Downloads use the separate existing analyzer. */
@androidx.media3.common.util.UnstableApi
public class YouTubeActivity extends Activity {
 private LinearLayout holder;private TextView status;private Button formats;private WebView web;
 private String lastUrl="https://m.youtube.com/";private boolean visible;
 static boolean allowed(String raw){try{java.net.URI uri=new java.net.URI(raw);return raw.length()<=4096&&"https".equalsIgnoreCase(uri.getScheme())&&uri.getUserInfo()==null&&uri.getPort()==-1&&MediaLinks.isYoutube(raw);}catch(Exception e){return false;}}
 static String downloadUrl(String raw){try{return DownloadLinks.resolve(raw);}catch(Exception e){return "";}}
 @Override public void onCreate(Bundle saved){super.onCreate(saved);if(saved!=null&&allowed(saved.getString("url","")))lastUrl=saved.getString("url");LinearLayout root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);Ui.background(root);root.setOnApplyWindowInsetsListener((v,i)->{root.setPadding(Ui.dp(this,12),Ui.dp(this,8)+i.getSystemWindowInsetTop(),Ui.dp(this,12),Ui.dp(this,8)+i.getSystemWindowInsetBottom());return i;});setContentView(root);
  LinearLayout header=new LinearLayout(this);header.setGravity(Gravity.CENTER_VERTICAL);Button back=Ui.button(this,"‹",v->finish());back.setContentDescription("Voltar do YouTube");header.addView(back,new LinearLayout.LayoutParams(Ui.dp(this,48),-2));TextView title=Ui.text(this,"YouTube no Onda",22,Ui.TEXT);header.addView(title,new LinearLayout.LayoutParams(0,-2,1));Button menu=Ui.menuButton(this,"Menu do YouTube",v->Ui.menu(this,v,new String[]{"Início do YouTube","Abrir no navegador","Central de downloads"},new String[]{"Início do YouTube","Abrir YouTube no navegador","Central de downloads"},new Runnable[]{()->load("https://m.youtube.com/"),this::external,()->startActivity(new Intent(this,DownloadCenterActivity.class))}));header.addView(menu,new LinearLayout.LayoutParams(-2,-2));root.addView(header);DownloadTabs.add(this,root,true);
  status=Ui.text(this,"Escolha um vídeo e consulte os formatos. A disponibilidade depende do YouTube.",12,Ui.MUTED);status.setContentDescription("Estado do YouTube no Onda");root.addView(status);holder=new LinearLayout(this);holder.setOrientation(LinearLayout.VERTICAL);root.addView(holder,new LinearLayout.LayoutParams(-1,0,1));formats=Ui.button(this,"Ver formatos para baixar",v->analyze());formats.setContentDescription("Consultar formatos do vídeo do YouTube");Ui.primary(formats);root.addView(formats,new LinearLayout.LayoutParams(-1,-2));formats.setEnabled(false);
 }
 @android.annotation.SuppressLint("SetJavaScriptEnabled") private void createBrowser(){
  try{web=new WebView(this);WebSettings settings=web.getSettings();settings.setJavaScriptEnabled(true);settings.setDomStorageEnabled(true);settings.setAllowFileAccess(false);settings.setAllowContentAccess(false);settings.setJavaScriptCanOpenWindowsAutomatically(false);settings.setSupportMultipleWindows(false);settings.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);settings.setMediaPlaybackRequiresUserGesture(true);CookieManager.getInstance().setAcceptThirdPartyCookies(web,false);web.setContentDescription("Página oficial do YouTube");
   web.setWebViewClient(new WebViewClient(){@Override public boolean shouldOverrideUrlLoading(WebView view,WebResourceRequest request){String url=request.getUrl().toString();if(allowed(url))return false;if(request.isForMainFrame())status.setText("Esse endereço abre fora da aba do YouTube. Use Abrir no navegador para continuar.");return true;}@Override public void doUpdateVisitedHistory(WebView view,String url,boolean reload){remember(url);}@Override public void onPageFinished(WebView view,String url){remember(url);}@Override public void onReceivedError(WebView view,WebResourceRequest request,WebResourceError error){if(request.isForMainFrame())status.setText("Não foi possível carregar o YouTube. Confira a conexão ou abra no navegador.");}});
   web.setDownloadListener((url,agent,disposition,mime,length)->status.setText("Abra o vídeo e toque em Ver formatos para baixar."));holder.addView(web,new LinearLayout.LayoutParams(-1,-1));web.resumeTimers();web.loadUrl(lastUrl);
  }catch(RuntimeException error){WebView failed=web;web=null;if(failed!=null){holder.removeView(failed);failed.stopLoading();failed.destroy();}status.setText("Atualize o Android System WebView ou abra o YouTube no navegador.");}
 }
 private void remember(String url){if(!visible||!allowed(url))return;lastUrl=url;formats.setEnabled(!downloadUrl(url).isEmpty());status.setText(downloadUrl(url).isEmpty()?"Escolha um vídeo ou playlist para consultar os formatos.":"Vídeo selecionado • consulte áudio ou vídeo disponíveis.");}
 private void load(String url){if(web!=null&&allowed(url))web.loadUrl(url);}
 private void analyze(){String url=downloadUrl(web==null?lastUrl:web.getUrl());if(url.isEmpty()){status.setText("Abra um vídeo ou playlist antes de consultar os formatos.");return;}startActivity(new Intent(this,DownloadsActivity.class).putExtra("analyze_link",url).addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT|Intent.FLAG_ACTIVITY_SINGLE_TOP));}
 private void external(){try{startActivity(new Intent(Intent.ACTION_VIEW,Uri.parse(lastUrl)));}catch(ActivityNotFoundException error){status.setText("Nenhum navegador disponível.");}}
 @Override protected void onResume(){super.onResume();visible=true;if(web==null)createBrowser();else{web.onResume();web.resumeTimers();}}
 @Override protected void onPause(){visible=false;if(web!=null){web.evaluateJavascript("document.querySelectorAll('video,audio').forEach(function(m){m.pause();});",null);web.onPause();web.pauseTimers();}super.onPause();}
 @Override protected void onStop(){if(web!=null){WebView old=web;web=null;holder.removeView(old);old.stopLoading();old.destroy();}super.onStop();}
 @Override public void onBackPressed(){if(web!=null&&web.canGoBack())web.goBack();else super.onBackPressed();}
 @Override protected void onSaveInstanceState(Bundle state){state.putString("url",lastUrl);super.onSaveInstanceState(state);}
 @Override protected void onDestroy(){if(web!=null){holder.removeView(web);web.destroy();web=null;}super.onDestroy();}
}
