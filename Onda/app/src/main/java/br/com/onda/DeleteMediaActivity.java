package br.com.onda;

import android.app.*;
import android.content.*;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.*;
import android.provider.*;
import android.widget.*;
import java.io.IOException;
import java.util.*;
import java.util.concurrent.*;

/** Explicit single-file deletion. Never walks directories or requests all-files access. */
@androidx.media3.common.util.UnstableApi
public class DeleteMediaActivity extends Activity {
 static final int REQUEST=9671;private static final int CONSENT=9672,WRITE=9673;
 private final ExecutorService worker=Executors.newSingleThreadExecutor();
 private Uri uri;private String type,id,name="",fingerprint="",phase="confirm";private boolean ready,busy,retried;private TextView details;private Button remove,cancel;
 static void open(Activity a,Uri uri,String title,String type,String id){a.startActivityForResult(new Intent(a,DeleteMediaActivity.class).setData(uri).putExtra("title",title).putExtra("kind",type).putExtra("item_id",id),REQUEST);}
 static boolean media(Uri uri,String kind){if(uri==null||!"content".equals(uri.getScheme())||!"media".equals(uri.getAuthority()))return false;List<String> p=uri.getPathSegments();return p.size()==4&&!p.get(0).isEmpty()&&p.get(1).equals("audio".equals(kind)?"audio":"video")&&p.get(2).equals("media")&&p.get(3).matches("[1-9][0-9]*");}
 @Override public void onCreate(Bundle saved){super.onCreate(saved);uri=getIntent().getData();type=getIntent().getStringExtra("kind");id=getIntent().getStringExtra("item_id");if(id==null||id.length()>256)id="";
  LinearLayout root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);Ui.background(root);root.setOnApplyWindowInsetsListener((v,i)->{root.setPadding(Ui.dp(this,20),Ui.dp(this,16)+i.getSystemWindowInsetTop(),Ui.dp(this,20),Ui.dp(this,16)+i.getSystemWindowInsetBottom());return i;});
  // Use a scrolling confirmation so file names and large accessibility fonts stay readable.
  ScrollView scroll=new ScrollView(this);LinearLayout body=new LinearLayout(this);body.setOrientation(LinearLayout.VERTICAL);scroll.addView(body);root.addView(scroll,new LinearLayout.LayoutParams(-1,-1));body.addView(Ui.text(this,"Excluir arquivo do celular?",23,Ui.TEXT));details=Ui.text(this,"Conferindo o arquivo…",16,Ui.CYAN);details.setPadding(0,Ui.dp(this,20),0,Ui.dp(this,20));body.addView(details);body.addView(Ui.text(this,"Isso remove o arquivo do armazenamento e afeta outros aplicativos. O Onda não possui opção de desfazer. Para apenas tirá-lo da lista, use ocultar.\n\nO Android ou o provedor poderá pedir uma autorização adicional. Cancelar mantém o arquivo.",15,Ui.MUTED));remove=Ui.button(this,"Excluir do celular",v->confirm());remove.setEnabled(false);body.addView(remove);cancel=Ui.button(this,"Cancelar",v->finish());body.addView(cancel);setContentView(root);
  if(uri==null||uri.toString().length()>2048||!"content".equals(uri.getScheme())||!("audio".equals(type)||"video".equals(type))||(!media(uri,type)&&!DocumentsContract.isDocumentUri(this,uri))){error("Este endereço não permite exclusão pelo Onda. Use o gerenciador de arquivos do Android.");return;}
  if(saved!=null){phase=saved.getString("phase","confirm");fingerprint=saved.getString("fingerprint","");name=saved.getString("name","");retried=saved.getBoolean("retried",false);if(phase.startsWith("consent")||phase.equals("permission")){busy=true;details.setText(name+"\nAguardando a confirmação do Android…");cancel.setEnabled(false);return;}}
  phase="confirm";worker.execute(()->{try{Info info=inspect(this,uri,type);runOnUiThread(()->{if(isFinishing()||isDestroyed())return;name=info.name;fingerprint=info.fingerprint;ready=true;details.setText(name+"\n"+uri);remove.setEnabled(true);});}catch(Exception e){runOnUiThread(()->error("Não foi possível conferir o arquivo. Ele pode ter sido removido ou o acesso expirou."));}});
 }
 static final class Info{final String name,fingerprint;Info(String n,String f){name=n;fingerprint=f;}}
 static Info inspect(Context c,Uri uri,String type)throws IOException{String mime=c.getContentResolver().getType(uri);if(mime==null||!(mime.startsWith(type+"/")||("audio".equals(type)&&(mime.equals("application/ogg")||mime.equals("application/x-ogg")))))throw new IOException("Tipo de arquivo diferente");try(Cursor q=c.getContentResolver().query(uri,new String[]{OpenableColumns.DISPLAY_NAME,OpenableColumns.SIZE},null,null,null)){if(q==null||!q.moveToFirst())throw new IOException("Arquivo indisponível");String name=q.getString(0);if(name==null||name.isEmpty())throw new IOException("Nome indisponível");String size=q.isNull(1)?"?":Long.toString(q.getLong(1));return new Info(name,name+"\n"+size+"\n"+mime);}}
 private void confirm(){if(!ready||busy)return;busy=true;ready=false;remove.setEnabled(false);cancel.setEnabled(false);if(media(uri,type)&&Build.VERSION.SDK_INT<=28&&checkSelfPermission(android.Manifest.permission.WRITE_EXTERNAL_STORAGE)!=PackageManager.PERMISSION_GRANTED){phase="permission";requestPermissions(new String[]{android.Manifest.permission.WRITE_EXTERNAL_STORAGE},WRITE);return;}attempt();}
 private void attempt(){phase="deleting";details.setText(name+"\nSolicitando exclusão…");worker.execute(()->{try{if(!fingerprint.equals(inspect(this,uri,type).fingerprint))throw new IOException("O arquivo mudou. Cancele e selecione-o novamente.");if(media(uri,type)&&Build.VERSION.SDK_INT>=30){PendingIntent consent=MediaStore.createDeleteRequest(getContentResolver(),Collections.singletonList(uri));runOnUiThread(()->launch(consent,"consent30"));return;}boolean deleted;if(media(uri,type))deleted=getContentResolver().delete(uri,null,null)>0;else deleted=DocumentsContract.deleteDocument(getContentResolver(),uri);if(!deleted)throw new IOException("O provedor não confirmou a exclusão.");complete();}catch(Exception e){if(Build.VERSION.SDK_INT==29&&media(uri,type)&&e instanceof RecoverableSecurityException&&!retried){PendingIntent consent=((RecoverableSecurityException)e).getUserAction().getActionIntent();runOnUiThread(()->launch(consent,"consent29"));}else runOnUiThread(()->error(e instanceof IOException?e.getMessage():"Sem permissão para excluir este arquivo. Use o gerenciador de arquivos do Android."));}});}
 private void launch(PendingIntent intent,String next){if(isFinishing()||isDestroyed())return;phase=next;try{startIntentSenderForResult(intent.getIntentSender(),CONSENT,null,0,0,0);}catch(Exception e){error("Não foi possível abrir a autorização do Android.");}}
 private void complete(){Context c=getApplicationContext();DownloadedAudio.forget(c,uri.toString());Set<String> favorites=new HashSet<>(c.getSharedPreferences("library",0).getStringSet("favorites",Collections.emptySet()));if(favorites.remove(id))c.getSharedPreferences("library",0).edit().putStringSet("favorites",favorites).apply();runOnUiThread(()->{if(isDestroyed()||isFinishing())return;setResult(RESULT_OK,new Intent().setData(uri).putExtra("item_id",id).putExtra("kind",type));finish();});}
 private void error(String text){if(isDestroyed()||isFinishing())return;busy=false;ready=false;phase="confirm";details.setText(text);remove.setEnabled(false);cancel.setEnabled(true);}
 @Override protected void onActivityResult(int request,int result,Intent data){super.onActivityResult(request,result,data);if(request!=CONSENT)return;if(result!=RESULT_OK){setResult(RESULT_CANCELED);finish();return;}if("consent30".equals(phase)){worker.execute(this::complete);}else if("consent29".equals(phase)){retried=true;attempt();}else error("A confirmação não corresponde à operação atual. Selecione o arquivo novamente.");}
 @Override public void onRequestPermissionsResult(int request,String[] permissions,int[] grants){super.onRequestPermissionsResult(request,permissions,grants);if(request==WRITE){if(grants.length>0&&grants[0]==PackageManager.PERMISSION_GRANTED)attempt();else{setResult(RESULT_CANCELED);finish();}}}
 @Override protected void onSaveInstanceState(Bundle out){super.onSaveInstanceState(out);out.putString("phase",phase);out.putString("fingerprint",fingerprint);out.putString("name",name);out.putBoolean("retried",retried);}
 @Override public void onBackPressed(){if(busy)Toast.makeText(this,"Conclua ou cancele a autorização do Android",Toast.LENGTH_SHORT).show();else super.onBackPressed();}
 @Override public void onDestroy(){worker.shutdown();super.onDestroy();}
}
