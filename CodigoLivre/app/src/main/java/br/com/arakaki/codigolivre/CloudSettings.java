package br.com.arakaki.codigolivre;
import android.app.*;
import android.content.*;
import android.widget.*;
import android.security.keystore.*;
import android.util.Base64;
import java.security.KeyStore;
import javax.crypto.*;
import javax.crypto.spec.GCMParameterSpec;
import java.nio.charset.StandardCharsets;
import java.util.*;
/** Chaves cifradas pelo Android Keystore; nunca incluídas nos checkpoints. */
final class CloudSettings implements CloudRouter.Memory {
 private final SharedPreferences prefs;
 CloudSettings(Context context){prefs=context.getSharedPreferences("cloud",Context.MODE_PRIVATE);}
 boolean enabled(){return prefs.getBoolean("enabled",false);}
 boolean share(){return prefs.getBoolean("share",false);}
 boolean fallback(){return prefs.getBoolean("fallback",true);}
 private javax.crypto.SecretKey secret()throws Exception{KeyStore ks=KeyStore.getInstance("AndroidKeyStore");ks.load(null);String alias="CodigoLivre.cloud.v1";if(!ks.containsAlias(alias)){KeyGenerator g=KeyGenerator.getInstance("AES","AndroidKeyStore");g.init(new KeyGenParameterSpec.Builder(alias,KeyProperties.PURPOSE_ENCRYPT|KeyProperties.PURPOSE_DECRYPT).setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build());g.generateKey();}return (javax.crypto.SecretKey)ks.getKey(alias,null);}
 private String encrypt(String value)throws Exception{Cipher c=Cipher.getInstance("AES/GCM/NoPadding");c.init(Cipher.ENCRYPT_MODE,secret());return Base64.encodeToString(c.getIV(),Base64.NO_WRAP)+":"+Base64.encodeToString(c.doFinal(value.getBytes(StandardCharsets.UTF_8)),Base64.NO_WRAP);}
 private String decrypt(String value)throws Exception{String[] parts=value.split(":",2);Cipher c=Cipher.getInstance("AES/GCM/NoPadding");c.init(Cipher.DECRYPT_MODE,secret(),new GCMParameterSpec(128,Base64.decode(parts[0],Base64.NO_WRAP)));return new String(c.doFinal(Base64.decode(parts[1],Base64.NO_WRAP)),StandardCharsets.UTF_8);}
 List<CloudRouter.Account> accounts()throws Exception{List<CloudRouter.Account> result=new ArrayList<>();for(CloudProtocol.Provider p:CloudProtocol.Provider.values()){String value=prefs.getString(p.name()+".key","");if(!value.isEmpty())result.add(new CloudRouter.Account(p,decrypt(value),prefs.getString(p.name()+".model","")));}return result;}
 public long cooldown(CloudProtocol.Provider p){return prefs.getLong(p.name()+".wait",0);}
 public long lastUsed(CloudProtocol.Provider p){return prefs.getLong(p.name()+".used",0);}
 public void waitUntil(CloudProtocol.Provider p,long time){prefs.edit().putLong(p.name()+".wait",time).apply();}
 public void used(CloudProtocol.Provider p,long time){prefs.edit().putLong(p.name()+".used",time).apply();}
 void menu(Activity activity,Runnable changed){LinearLayout box=new LinearLayout(activity);box.setOrientation(LinearLayout.VERTICAL);box.setPadding(24,12,24,12);
  CheckBox enabled=new CheckBox(activity);enabled.setText("Usar IAs online com alternância automática");enabled.setChecked(enabled());box.addView(enabled);
  CheckBox share=new CheckBox(activity);share.setText("Autorizar envio do código/prévia anexada aos provedores configurados");share.setChecked(share());box.addView(share);
  CheckBox fallback=new CheckBox(activity);fallback.setText("Se todos falharem, tentar modelo local carregado");fallback.setChecked(fallback());box.addView(fallback);
  TextView info=new TextView(activity);info.setText("A pergunta será enviada aos provedores configurados. A alternância respeita cotas; não é ilimitada. Gemini/Groq: use conta sem cobrança habilitada e confira os termos. OpenRouter: somente modelos :free com preço zero no catálogo. Cada serviço tem sua política de dados.");box.addView(info);
  for(CloudProtocol.Provider p:CloudProtocol.Provider.values()){Button b=new Button(activity);long wait=Math.max(0,(cooldown(p)-System.currentTimeMillis()+999)/1000);b.setText(p.label+(prefs.contains(p.name()+".key")?" · configurado":" · configurar")+(wait>0?" · espera "+wait+"s":""));b.setOnClickListener(v->configure(activity,p));box.addView(b);}
  new AlertDialog.Builder(activity).setTitle("IA online · suas chaves").setView(box).setPositiveButton("Salvar",(d,w)->prefs.edit().putBoolean("enabled",enabled.isChecked()).putBoolean("share",share.isChecked()).putBoolean("fallback",fallback.isChecked()).apply()).setNegativeButton("Fechar",null).setOnDismissListener(d->changed.run()).show();
 }
 private void configure(Activity a,CloudProtocol.Provider p){EditText input=new EditText(a);input.setHint("Cole sua chave somente aqui");input.setInputType(129);input.setImportantForAutofill(android.view.View.IMPORTANT_FOR_AUTOFILL_NO);new AlertDialog.Builder(a).setTitle(p.label).setMessage("A chave será cifrada no aparelho. Não envie a chave por mensagens. Consultar o catálogo não testa a cota de geração.").setView(input).setNeutralButton("Criar chave",(d,w)->a.startActivity(new Intent(Intent.ACTION_VIEW,android.net.Uri.parse(p.keyUrl)))).setNegativeButton("Remover",(d,w)->prefs.edit().remove(p.name()+".key").remove(p.name()+".model").remove(p.name()+".wait").apply()).setPositiveButton("Buscar modelos",(d,w)->{
   String key=input.getText().toString().trim();try{CloudProtocol.key(key);}catch(Exception e){Toast.makeText(a,e.getMessage(),Toast.LENGTH_LONG).show();return;}
   ProgressDialog progress=ProgressDialog.show(a,"Modelos","Consultando catálogo…",true,false);
   new Thread(()->{try{List<CloudProtocol.Model> models=new CloudClient().models(p,key);if(models.isEmpty())throw new IllegalStateException("Nenhum modelo compatível disponível.");a.runOnUiThread(()->{progress.dismiss();if(a.isFinishing()||a.isDestroyed())return;String[] names=models.stream().map(m->m.id).toArray(String[]::new);new AlertDialog.Builder(a).setTitle("Escolha o modelo").setItems(names,(dialog,index)->{try{prefs.edit().putString(p.name()+".key",encrypt(key)).putString(p.name()+".model",models.get(index).id).remove(p.name()+".wait").apply();Toast.makeText(a,"Salvo. Ative a IA online no menu e toque Salvar.",Toast.LENGTH_LONG).show();}catch(Exception e){Toast.makeText(a,"Não foi possível proteger a chave.",Toast.LENGTH_LONG).show();}}).show();});}catch(Exception e){a.runOnUiThread(()->{progress.dismiss();if(!a.isFinishing())new AlertDialog.Builder(a).setMessage(e instanceof CloudRouter.Failure?e.getMessage():"Não foi possível consultar o catálogo. Confira conexão e chave.").setPositiveButton("OK",null).show();});}},"cloud-catalog").start();
  }).show();}
}
