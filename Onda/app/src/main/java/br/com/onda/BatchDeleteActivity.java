package br.com.onda;

import android.app.*;
import android.content.*;
import android.net.Uri;
import android.os.Bundle;
import android.widget.*;
import androidx.media3.common.MediaItem;
import org.json.*;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.*;
import java.util.concurrent.*;

/** Explicit selection, one app confirmation, existing per-file Android authorization. */
@androidx.media3.common.util.UnstableApi
public class BatchDeleteActivity extends Activity {
    static final int REQUEST=9674;
    static final class Entry {
        final Uri uri;final String title,kind,id;String fingerprint="";boolean selected;
        Entry(Uri u,String t,String k,String i){uri=u;title=t;kind=k;id=i;}
    }
    private final ArrayList<Entry> entries=new ArrayList<>();
    private final Set<String> deleted=new HashSet<>();
    private final ExecutorService worker=Executors.newSingleThreadExecutor();
    private String token;private int index;private boolean busy,awaiting;
    private ListView list;private TextView status;private Button remove,all,cancel;
    private AlertDialog confirmation;
    static void audio(Activity activity,List<MediaItem> items){ArrayList<Entry> rows=new ArrayList<>();for(MediaItem i:items)if(i.localConfiguration!=null)rows.add(new Entry(i.localConfiguration.uri,String.valueOf(i.mediaMetadata.title),"audio",i.mediaId));open(activity,rows);}
    static void videos(Activity activity,List<VideoStore.Item> items){ArrayList<Entry> rows=new ArrayList<>();for(VideoStore.Item i:items)rows.add(new Entry(i.uri,i.title,"video",""));open(activity,rows);}
    private static void open(Activity activity,List<Entry> rows){
        try{JSONArray data=new JSONArray();Set<String> unique=new HashSet<>();for(Entry e:rows)if(eligible(activity,e)&&unique.add(e.uri.toString()))data.put(json(e));if(data.length()==0){Toast.makeText(activity,"Nenhum arquivo local disponível nesta lista",Toast.LENGTH_LONG).show();return;}String token="onda-delete-"+UUID.randomUUID()+".json";Files.write(file(activity,token).toPath(),data.toString().getBytes(StandardCharsets.UTF_8));activity.startActivityForResult(new Intent(activity,BatchDeleteActivity.class).putExtra("request_file",token),REQUEST);}catch(Exception e){Toast.makeText(activity,"Não foi possível preparar a seleção",Toast.LENGTH_LONG).show();}
    }
    private static boolean eligible(Context c,Entry e){return e.uri!=null&&"content".equals(e.uri.getScheme())&&("audio".equals(e.kind)||"video".equals(e.kind))&&(DeleteMediaActivity.media(e.uri,e.kind)||android.provider.DocumentsContract.isDocumentUri(c,e.uri));}
    private static File file(Context c,String token)throws IOException{if(token==null||!token.matches("onda-delete-[a-f0-9-]{36}\\.json"))throw new IOException("Seleção inválida");return new File(c.getCacheDir(),token);}
    private static JSONObject json(Entry e)throws JSONException{return new JSONObject().put("uri",e.uri.toString()).put("title",e.title).put("kind",e.kind).put("id",e.id).put("fingerprint",e.fingerprint).put("selected",e.selected);}
    private File doneFile()throws IOException{return new File(file(this,token).getPath()+".done");}
    static Set<String> result(Context c,Intent data){Set<String> uris=new HashSet<>();if(data==null)return uris;try{File request=file(c,data.getStringExtra("request_file")),done=new File(request.getPath()+".done");if(done.isFile())for(String line:Files.readAllLines(done.toPath(),StandardCharsets.UTF_8))if(!line.isEmpty())uris.add(new JSONObject(line).getString("uri"));done.delete();request.delete();}catch(Exception ignored){}return uris;}
    @Override public void onCreate(Bundle saved){super.onCreate(saved);token=getIntent().getStringExtra("request_file");
        LinearLayout root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);Ui.background(root);root.setOnApplyWindowInsetsListener((v,i)->{root.setPadding(Ui.dp(this,16),Ui.dp(this,12)+i.getSystemWindowInsetTop(),Ui.dp(this,16),Ui.dp(this,12)+i.getSystemWindowInsetBottom());return i;});setContentView(root);
        root.addView(Ui.text(this,"Selecionar arquivos",23,Ui.TEXT));root.addView(Ui.text(this,"Marque músicas ou vídeos para excluir do celular. A exclusão é permanente.",14,Ui.MUTED));status=Ui.text(this,"",15,Ui.CYAN);status.setContentDescription("Quantidade de arquivos selecionados");root.addView(status);
        all=Ui.button(this,"Selecionar todos",v->{boolean target=!allSelected();for(int i=0;i<entries.size();i++){entries.get(i).selected=target;list.setItemChecked(i,target);}update();});root.addView(all);
        list=new ListView(this);list.setChoiceMode(ListView.CHOICE_MODE_MULTIPLE);list.setContentDescription("Arquivos para exclusão múltipla");root.addView(list,new LinearLayout.LayoutParams(-1,0,1));
        remove=Ui.button(this,"Excluir selecionados",v->prepare());remove.setContentDescription("Excluir arquivos selecionados");root.addView(remove);cancel=Ui.button(this,"Cancelar",v->finishBatch());root.addView(cancel);
        try{JSONArray data=new JSONArray(new String(Files.readAllBytes(file(this,token).toPath()),StandardCharsets.UTF_8));for(int i=0;i<data.length();i++){JSONObject j=data.getJSONObject(i);Entry e=new Entry(Uri.parse(j.getString("uri")),j.getString("title"),j.getString("kind"),j.optString("id"));if(!eligible(this,e))throw new IOException("Arquivo não local");e.fingerprint=j.optString("fingerprint");e.selected=j.optBoolean("selected");entries.add(e);}if(doneFile().isFile())for(String line:Files.readAllLines(doneFile().toPath(),StandardCharsets.UTF_8))if(!line.isEmpty())deleted.add(new JSONObject(line).getString("uri"));}catch(Exception e){status.setText("Não foi possível recuperar a seleção. Volte e selecione novamente.");remove.setEnabled(false);all.setEnabled(false);return;}
        String[] labels=new String[entries.size()];for(int i=0;i<labels.length;i++)labels[i]=entries.get(i).title;list.setAdapter(new ArrayAdapter<>(this,android.R.layout.simple_list_item_multiple_choice,labels));for(int i=0;i<entries.size();i++)list.setItemChecked(i,entries.get(i).selected);list.setOnItemClickListener((p,v,i,id)->{entries.get(i).selected=list.isItemChecked(i);update();});
        if(saved!=null){index=saved.getInt("index");awaiting=saved.getBoolean("awaiting");busy=awaiting;}update();
    }
    private int selectedCount(){int count=0;for(Entry e:entries)if(e.selected&&!deleted.contains(e.uri.toString()))count++;return count;}
    private boolean allSelected(){boolean any=false;for(Entry e:entries)if(!deleted.contains(e.uri.toString())){any=true;if(!e.selected)return false;}return any;}
    private void update(){all.setText(allSelected()?"Desmarcar todos":"Selecionar todos");status.setText(busy?"Excluídos: "+deleted.size()+" • aguardando autorização":"Selecionados: "+selectedCount()+" de "+entries.size());remove.setEnabled(!busy&&selectedCount()>0);all.setEnabled(!busy);list.setEnabled(!busy);cancel.setEnabled(!busy);}
    private void save()throws Exception{JSONArray data=new JSONArray();for(Entry e:entries)data.put(json(e));Files.write(file(this,token).toPath(),data.toString().getBytes(StandardCharsets.UTF_8));}
    private void prepare(){if(busy||selectedCount()==0)return;busy=true;update();worker.execute(()->{try{StringBuilder names=new StringBuilder();int count=0;for(Entry e:entries)if(e.selected&&!deleted.contains(e.uri.toString())){DeleteMediaActivity.Info info=DeleteMediaActivity.inspect(this,e.uri,e.kind);e.fingerprint=info.fingerprint;names.append("\n• ").append(info.name);count++;}String message=count+" arquivos serão excluídos permanentemente. O Android poderá pedir autorização para cada arquivo.\n"+names;runOnUiThread(()->{if(isFinishing()||isDestroyed())return;confirmation=new AlertDialog.Builder(this).setTitle("Excluir selecionados?").setMessage(message).setNegativeButton("Cancelar",(d,w)->{busy=false;update();}).setPositiveButton("Excluir",(d,w)->{try{save();index=0;next();}catch(Exception e){busy=false;update();status.setText("Não foi possível salvar a seleção. Nenhum novo arquivo foi excluído.");}}).setOnCancelListener(d->{busy=false;update();}).show();});}catch(Exception e){runOnUiThread(()->{if(isFinishing()||isDestroyed())return;busy=false;update();status.setText("Um arquivo não está mais acessível. Cancele e selecione novamente; nenhum novo arquivo foi excluído.");});}});}
    private void next(){while(index<entries.size()&&(!entries.get(index).selected||deleted.contains(entries.get(index).uri.toString())))index++;if(index>=entries.size()){finishBatch();return;}Entry e=entries.get(index);awaiting=true;busy=true;update();startActivityForResult(new Intent(this,DeleteMediaActivity.class).setData(e.uri).putExtra("title",e.title).putExtra("kind",e.kind).putExtra("item_id",e.id).putExtra("batch_fingerprint",e.fingerprint),DeleteMediaActivity.REQUEST);}
    @Override protected void onActivityResult(int request,int result,Intent data){super.onActivityResult(request,result,data);if(request!=DeleteMediaActivity.REQUEST||!awaiting)return;awaiting=false;if(result!=RESULT_OK||data==null||index>=entries.size()||!entries.get(index).uri.equals(data.getData())){busy=false;update();status.setText("Excluídos: "+deleted.size()+". Operação interrompida; os demais arquivos foram mantidos.");cancel.setText("Concluir");return;}Entry e=entries.get(index);deleted.add(e.uri.toString());try(FileOutputStream out=new FileOutputStream(doneFile(),true)){out.write((new JSONObject().put("uri",e.uri.toString()).toString()+"\n").getBytes(StandardCharsets.UTF_8));}catch(Exception error){busy=false;update();status.setText("Exclusão interrompida: não foi possível registrar o resultado.");return;}index++;next();}
    private void finishBatch(){setResult(deleted.isEmpty()?RESULT_CANCELED:RESULT_OK,new Intent().putExtra("request_file",token));finish();}
    @Override public void onBackPressed(){if(busy)Toast.makeText(this,"Conclua ou cancele a confirmação do Android",Toast.LENGTH_SHORT).show();else finishBatch();}
    @Override protected void onSaveInstanceState(Bundle state){super.onSaveInstanceState(state);state.putInt("index",index);state.putBoolean("awaiting",awaiting);try{save();}catch(Exception ignored){}}
    @Override public void onDestroy(){if(confirmation!=null)confirmation.dismiss();worker.shutdown();super.onDestroy();}
}
