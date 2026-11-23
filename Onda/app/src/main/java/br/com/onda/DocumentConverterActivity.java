package br.com.onda;

import android.app.*;
import android.content.*;
import android.database.Cursor;
import android.net.Uri;
import android.os.*;
import android.provider.*;
import android.view.*;
import android.widget.*;
import androidx.core.content.FileProvider;
import org.json.JSONArray;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.*;
import java.util.concurrent.*;

/** User-selected documents only. No network, recurring work, or changes to source files. */
@androidx.media3.common.util.UnstableApi
public class DocumentConverterActivity extends Activity {
 private static final int PICK=9731,SAVE=9732;
 private final ExecutorService worker=Executors.newSingleThreadExecutor();
 private final ArrayList<Uri> sources=new ArrayList<>();
 private DocumentConverter.Mode mode=DocumentConverter.Mode.IMAGES_PDF;
 private Spinner modes;private TextView details,status;private Button choose,convert,cancel,save,share,open;
 private volatile LocalAiModels.Cancel cancellation;private boolean busy;private File result;private String selectionFile;private long lastProgress;private boolean exporting;
 @Override public void onCreate(Bundle state){super.onCreate(state);
  if(state!=null){try{mode=DocumentConverter.Mode.valueOf(state.getString("mode","IMAGES_PDF"));}catch(Exception ignored){}selectionFile=state.getString("selection");String name=state.getString("result");if(name!=null&&name.matches("Onda-documento-[a-f0-9-]{36}\\.(pdf|txt|zip)")){try{File file=new File(DocumentConverter.folder(this),name);if(file.isFile())result=file;}catch(IOException ignored){}}exporting=state.getBoolean("exporting");}
  LinearLayout root=column();Ui.background(root);root.setOnApplyWindowInsetsListener((v,i)->{root.setPadding(Ui.dp(this,16),Ui.dp(this,10)+i.getSystemWindowInsetTop(),Ui.dp(this,16),Ui.dp(this,10)+i.getSystemWindowInsetBottom());return i;});setContentView(root);
  LinearLayout header=new LinearLayout(this);header.setGravity(Gravity.CENTER_VERTICAL);Button back=Ui.button(this,"‹",v->finish());back.setContentDescription("Voltar do conversor de documentos");header.addView(back,new LinearLayout.LayoutParams(Ui.dp(this,48),Ui.dp(this,48)));TextView heading=Ui.text(this,"Documentos e PDF",22,Ui.TEXT);heading.setMaxLines(1);heading.setEllipsize(android.text.TextUtils.TruncateAt.END);header.addView(heading,new LinearLayout.LayoutParams(0,-2,1));root.addView(header);
  ScrollView scroll=new ScrollView(this);scroll.setFillViewport(true);LinearLayout body=column();scroll.addView(body);root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
  body.addView(Ui.text(this,"Converta no celular, sem enviar documentos à internet. Os originais são preservados.",15,Ui.MUTED));
  body.addView(Ui.text(this,"Tipo de conversão",14,Ui.CYAN));modes=new Spinner(this);String[] labels=Arrays.stream(DocumentConverter.Mode.values()).map(m->m.label).toArray(String[]::new);modes.setAdapter(Ui.spinnerLabels(this,labels));Ui.spinner(modes);modes.setMinimumHeight(Ui.dp(this,56));modes.setSelection(mode.ordinal());modes.setContentDescription("Tipo de conversão de documento");body.addView(modes,new LinearLayout.LayoutParams(-1,-2));
  details=Ui.text(this,"",14,Ui.MUTED);details.setPadding(0,Ui.dp(this,8),0,Ui.dp(this,12));body.addView(details);
  choose=Ui.button(this,"Escolher arquivo",v->pick());body.addView(choose,new LinearLayout.LayoutParams(-1,-2));
  status=Ui.text(this,result==null?"Escolha os arquivos para começar.":"Arquivo convertido disponível. Você pode abrir, salvar ou compartilhar.",14,Ui.CYAN);status.setPadding(0,Ui.dp(this,12),0,Ui.dp(this,12));status.setAccessibilityLiveRegion(View.ACCESSIBILITY_LIVE_REGION_POLITE);body.addView(status);
  convert=Ui.button(this,"Converter",v->begin());body.addView(convert,new LinearLayout.LayoutParams(-1,-2));cancel=Ui.button(this,"Interromper",v->stop());body.addView(cancel,new LinearLayout.LayoutParams(-1,-2));
  open=Ui.button(this,"Abrir resultado",v->openResult());save=Ui.button(this,"Salvar uma cópia",v->saveResult());share=Ui.button(this,"Compartilhar arquivo",v->shareResult());for(Button button:new Button[]{open,save,share})body.addView(button,new LinearLayout.LayoutParams(-1,-2));
  body.addView(Ui.text(this,"PDF → imagens cria um ZIP com uma PNG por página, até 1.600 pixels no maior lado. Fotos → PDF usa uma foto por página A4, na ordem recebida do seletor, ajustando a orientação. GIF usa o primeiro quadro. Documentos com senha ou restrição de cópia não são desbloqueados. Sem limite fixo de páginas ou fotos; depende do espaço e da memória. O processamento para ao sair desta tela. Resultados temporários podem ser removidos pelo Android: use Salvar para guardar uma cópia.",13,Ui.MUTED));
  modes.setOnItemSelectedListener(new android.widget.AdapterView.OnItemSelectedListener(){public void onNothingSelected(AdapterView<?> parent){}public void onItemSelected(AdapterView<?> parent,View view,int position,long id){DocumentConverter.Mode selected=DocumentConverter.Mode.values()[position];if(selected!=mode){mode=selected;sources.clear();selectionFile=null;result=null;status.setText("Escolha os arquivos para esta conversão.");}describe();update();}});
  describe();update();
  if(selectionFile!=null)restoreSelection(selectionFile);
  else if(state==null&&getIntent().getData()!=null){mode=DocumentConverter.Mode.PDF_TEXT;modes.setSelection(mode.ordinal());sources.add(getIntent().getData());rememberSelection();describe();status.setText("PDF recebido do leitor. Escolha Converter para extrair o texto, ou mude o tipo de conversão.");update();}
 }
 private LinearLayout column(){LinearLayout box=new LinearLayout(this);box.setOrientation(LinearLayout.VERTICAL);return box;}
 private void describe(){switch(mode){case IMAGES_PDF:details.setText("JPG, PNG, WebP e outras fotos que o Android consiga abrir. Selecione uma ou várias imagens.");choose.setText("Escolher fotos");break;case TEXT_PDF:details.setText("TXT, CSV, MD, JSON e LOG em UTF-8 ou UTF-16. O conteúdo vira texto paginado; não executa código nem transforma dados em planilha.");choose.setText("Escolher texto");break;case DOCX_PDF:details.setText("Converte somente o texto principal de arquivos .docx. Não preserva tabelas, imagens, cabeçalhos, estilos ou a diagramação do Word. DOC, XLS e PPT não são suportados.");choose.setText("Escolher DOCX");break;case PDF_IMAGES:details.setText("Transforma todas as páginas do PDF em imagens PNG, reunidas em um arquivo ZIP para salvar ou compartilhar.");choose.setText("Escolher PDF");break;case PDF_TEXT:details.setText("Extrai o texto selecionável de todas as páginas para TXT. PDFs digitalizados precisam do OCR no leitor; a diagramação original não é mantida.");choose.setText("Escolher PDF");break;}}
 private void update(){modes.setEnabled(!busy&&!exporting);choose.setEnabled(!busy&&!exporting);convert.setEnabled(!busy&&!exporting&&!sources.isEmpty());cancel.setVisibility(busy?View.VISIBLE:View.GONE);boolean ready=result!=null&&result.isFile()&&!busy&&!exporting;for(Button button:new Button[]{save,share,open})button.setEnabled(ready);}
 private void pick(){if(busy)return;Intent pick=new Intent(Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION|Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
  if(mode==DocumentConverter.Mode.IMAGES_PDF)pick.setType("image/*").putExtra(Intent.EXTRA_ALLOW_MULTIPLE,true);
  else if(mode==DocumentConverter.Mode.PDF_IMAGES||mode==DocumentConverter.Mode.PDF_TEXT)pick.setType("application/pdf");
  else pick.setType("*/*");
  try{startActivityForResult(pick,PICK);}catch(ActivityNotFoundException e){status.setText("O seletor de arquivos do Android não está disponível.");}}
 private void rememberSelection(){final List<Uri> snapshot=new ArrayList<>(sources);worker.execute(()->{try{File file=File.createTempFile("onda-doc-selection-",".json",getCacheDir());JSONArray array=new JSONArray();for(Uri uri:snapshot)array.put(uri.toString());Files.write(file.toPath(),array.toString().getBytes(StandardCharsets.UTF_8));runOnUiThread(()->{if(!isDestroyed())selectionFile=file.getName();});}catch(Exception ignored){}});}
 private void restoreSelection(String name){if(!name.matches("onda-doc-selection-.*\\.json"))return;busy=true;update();worker.execute(()->{ArrayList<Uri> restored=new ArrayList<>();try{JSONArray array=new JSONArray(new String(Files.readAllBytes(new File(getCacheDir(),name).toPath()),StandardCharsets.UTF_8));for(int i=0;i<array.length();i++){Uri uri=Uri.parse(array.getString(i));if("content".equals(uri.getScheme()))restored.add(uri);}}catch(Exception ignored){}runOnUiThread(()->{if(isDestroyed())return;busy=false;sources.clear();sources.addAll(restored);if(result==null)status.setText(sources.isEmpty()?"Selecione novamente os arquivos.":sources.size()+" arquivo(s) selecionado(s).");update();});});}
 private void begin(){if(busy||sources.isEmpty())return;final List<Uri> inputs=new ArrayList<>(sources);final DocumentConverter.Mode selected=mode;busy=true;result=null;lastProgress=0;LocalAiModels.Cancel token=new LocalAiModels.Cancel();cancellation=token;status.setText("Convertendo… mantenha esta tela aberta.");update();worker.execute(()->{try{File output=DocumentConverter.convert(this,inputs,selected,token,(done,total)->{long now=SystemClock.elapsedRealtime();if(now-lastProgress<250&&done!=total)return;lastProgress=now;runOnUiThread(()->{if(!isDestroyed()&&cancellation==token)status.setText(total>0?"Processando página "+done+" de "+total+"…":"Criando página "+done+"…");});});if(token.cancelled()||isDestroyed()){output.delete();throw new InterruptedIOException();}runOnUiThread(()->{if(isDestroyed()){output.delete();return;}if(token.cancelled()){output.delete();failed(token,new InterruptedIOException());return;}busy=false;cancellation=null;result=output;status.setText("Concluído • "+selected.extension.toUpperCase(Locale.ROOT)+" • "+android.text.format.Formatter.formatShortFileSize(this,output.length())+"\nAbra, salve ou compartilhe o novo arquivo.");update();});}catch(Exception|OutOfMemoryError e){failed(token,e);}});}
 private void failed(LocalAiModels.Cancel token,Throwable error){runOnUiThread(()->{if(isDestroyed()||cancellation!=token)return;busy=false;cancellation=null;String message=token.cancelled()?"Operação interrompida. Os originais foram preservados.":error instanceof OutOfMemoryError?"Faltou memória para este documento. Tente converter menos páginas ou fotos por vez.":error.getMessage();status.setText(message==null?"Não foi possível converter. Confira o formato e o espaço disponível.":message);update();});}
 private void stop(){LocalAiModels.Cancel token=cancellation;if(token!=null){token.cancel();status.setText("Interrompendo…");}}
 private Uri resultUri(){return FileProvider.getUriForFile(this,getPackageName()+".share",result);}
 private void shareResult(){if(result==null)return;try{startActivity(Intent.createChooser(ImageSharing.send(this,result,mode.mime,null),"Compartilhar documento"));}catch(ActivityNotFoundException e){status.setText("Nenhum aplicativo de compartilhamento disponível.");}}
 private void openResult(){if(result==null)return;Intent intent=new Intent(Intent.ACTION_VIEW).setDataAndType(resultUri(),mode.mime).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);intent.setClipData(ClipData.newRawUri("Documento do Onda",resultUri()));if(mode.mime.equals("application/pdf"))intent.setClass(this,PdfActivity.class);try{startActivity(intent);}catch(ActivityNotFoundException e){status.setText("Não há aplicativo para abrir este formato. Use Salvar ou Compartilhar.");}}
 private void saveResult(){if(result==null)return;exporting=true;update();try{startActivityForResult(new Intent(Intent.ACTION_CREATE_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType(mode.mime).putExtra(Intent.EXTRA_TITLE,result.getName()),SAVE);}catch(ActivityNotFoundException e){exporting=false;update();status.setText("Não foi possível abrir o seletor de destino.");}}
 private void saveTo(Uri target){exporting=false;if(result==null||sources.contains(target)||target.equals(resultUri())){status.setText("Escolha um novo arquivo para preservar o original.");update();return;}File file=result;busy=true;LocalAiModels.Cancel token=new LocalAiModels.Cancel();cancellation=token;status.setText("Salvando cópia…");update();worker.execute(()->{try{try(InputStream in=new FileInputStream(file);OutputStream out=getContentResolver().openOutputStream(target,"wt")){if(out==null)throw new IOException("Destino indisponível.");DocumentConverter.copy(in,out,token);}token.check();runOnUiThread(()->{if(isDestroyed()||cancellation!=token)return;busy=false;cancellation=null;status.setText("Cópia salva no local escolhido. O arquivo original foi preservado.");update();});}catch(Exception e){try{DocumentsContract.deleteDocument(getContentResolver(),target);}catch(Exception ignored){try{getContentResolver().delete(target,null,null);}catch(Exception ignoredAgain){}}failed(token,e);}});}
 @Override public void onActivityResult(int request,int code,Intent data){super.onActivityResult(request,code,data);if(request==SAVE){if(code==RESULT_OK&&data!=null&&data.getData()!=null)saveTo(data.getData());else{exporting=false;update();}return;}if(request!=PICK||code!=RESULT_OK||data==null)return;
  sources.clear();result=null;ClipData clips=data.getClipData();if(clips!=null){for(int i=0;i<clips.getItemCount();i++){Uri uri=clips.getItemAt(i).getUri();if(uri!=null&&!sources.contains(uri))sources.add(uri);}}else if(data.getData()!=null)sources.add(data.getData());if(mode!=DocumentConverter.Mode.IMAGES_PDF&&sources.size()>1)sources.subList(1,sources.size()).clear();
  for(Uri uri:sources){try{getContentResolver().takePersistableUriPermission(uri,Intent.FLAG_GRANT_READ_URI_PERMISSION);}catch(Exception ignored){}}
  status.setText(sources.size()+" arquivo(s) selecionado(s). Toque em Converter.");rememberSelection();update();
 }
 @Override public void onSaveInstanceState(Bundle state){super.onSaveInstanceState(state);state.putString("mode",mode.name());state.putString("selection",selectionFile);if(result!=null)state.putString("result",result.getName());state.putBoolean("exporting",exporting);}
 @Override protected void onStop(){super.onStop();if(busy)stop();}
 @Override protected void onDestroy(){stop();worker.shutdownNow();super.onDestroy();}
}
