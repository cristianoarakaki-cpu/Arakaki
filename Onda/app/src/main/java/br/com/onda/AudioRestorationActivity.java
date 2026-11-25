package br.com.onda;

import android.app.*;import android.content.*;import android.database.Cursor;import android.media.MediaMetadataRetriever;import android.net.Uri;import android.os.*;import android.provider.OpenableColumns;import android.view.*;import android.widget.*;
import androidx.media3.common.*;import androidx.media3.exoplayer.ExoPlayer;
import java.io.*;import java.util.concurrent.*;

/** Explicit local cleanup, with bounded preview and a separately owned foreground export. */
@androidx.media3.common.util.UnstableApi
public class AudioRestorationActivity extends Activity {
 private static final int PICK=88;private static final long PREVIEW=12000;
 private final ExecutorService worker=Executors.newSingleThreadExecutor();private Future<?> work;private int generation,profile=RestorationDsp.VOICE;private boolean busy,started;
 private Uri source;private String name,stamp;private long duration,start;private File preview;private ExoPlayer player;
 private TextView title,status,time;private Button choose,mode,prepare,original,treated,save;private SeekBar position;
 @Override public void onCreate(Bundle state){super.onCreate(state);
  LinearLayout root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);Ui.background(root);root.setOnApplyWindowInsetsListener((v,i)->{root.setPadding(Ui.dp(this,16),Ui.dp(this,8)+i.getSystemWindowInsetTop(),Ui.dp(this,16),Ui.dp(this,8)+i.getSystemWindowInsetBottom());return i;});setContentView(root);
  LinearLayout head=new LinearLayout(this);head.setGravity(Gravity.CENTER_VERTICAL);head.addView(Ui.button(this,"‹",v->finish()),new LinearLayout.LayoutParams(Ui.dp(this,48),-2));head.addView(Ui.text(this,"Restaurar gravação",21,Ui.TEXT),new LinearLayout.LayoutParams(0,-2,1));root.addView(head);
  ScrollView scroll=new ScrollView(this);LinearLayout body=new LinearLayout(this);body.setOrientation(LinearLayout.VERTICAL);scroll.addView(body);root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
  body.addView(Ui.text(this,"Uma nova vida para seu áudio",20,Ui.CYAN));body.addView(Ui.text(this,"Suaviza graves de fundo e chiado agudo, com redução leve de ruído nas pausas. Compare antes de salvar: o tratamento também pode reduzir agudos e detalhes suaves. Não recupera áudio perdido ou distorcido.",15,Ui.MUTED));
  choose=Ui.button(this,"Escolher áudio ou vídeo",v->{Intent pick=new Intent(Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType("*/*").putExtra(Intent.EXTRA_MIME_TYPES,new String[]{"audio/*","video/*"}).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION|Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);try{startActivityForResult(pick,PICK);}catch(ActivityNotFoundException e){status.setText("Nenhum seletor de arquivos disponível.");}});body.addView(choose);
  title=Ui.text(this,"Nenhum arquivo escolhido",18,Ui.TEXT);body.addView(title);
  mode=Ui.button(this,"",v->new AlertDialog.Builder(this).setTitle("Tratamento suave").setSingleChoiceItems(new String[]{"Voz • mais redução de chiado","Música • preserva mais agudos"},profile-1,(d,which)->{invalidatePreview();profile=which+1;d.dismiss();controls();}).setNegativeButton("Cancelar",null).show());body.addView(mode);
  time=Ui.text(this,"Prévia de até 12 segundos",15,Ui.MUTED);body.addView(time);position=new SeekBar(this);position.setMax(1000);position.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener(){public void onStartTrackingTouch(SeekBar s){invalidatePreview();}public void onProgressChanged(SeekBar s,int p,boolean user){if(user){start=Math.max(0,duration-PREVIEW)*p/1000;updateTime();}}public void onStopTrackingTouch(SeekBar s){controls();}});body.addView(position);
  prepare=Ui.button(this,"Preparar comparação",v->preparePreview());Ui.primary(prepare);body.addView(prepare);
  original=Ui.button(this,"Ouvir original",v->play(false));treated=Ui.button(this,"Ouvir restaurada",v->play(true));body.addView(original);body.addView(treated);body.addView(Ui.button(this,"Parar prévia",v->{if(busy){invalidatePreview();status.setText("Prévia cancelada.");controls();}else stopPlayer();}));
  status=Ui.text(this,"Escolha um arquivo do celular. Nada é enviado à internet.",15,Ui.TEXT);body.addView(status);
  save=Ui.button(this,"Salvar cópia restaurada em MP3",v->{stopPlayer();startActivity(new Intent(this,ChapterExportActivity.class).putExtra("source",source.toString()).putExtra("stamp",stamp).putExtra("name",name+" - restaurada").putExtra("start",0L).putExtra("end",duration).putExtra("duration",duration).putExtra("restoration_profile",profile));});body.addView(save);body.addView(Ui.text(this,"Processa apenas quando solicitado. A prévia para ao sair desta tela; a cópia completa continua em segundo plano pela notificação. O original é preservado.",14,Ui.MUTED));controls();
  if(state!=null){profile=state.getInt("profile",1);start=state.getLong("start",0);String uri=state.getString("source");if(uri!=null)load(Uri.parse(uri));}
 }
 private void updateTime(){if(time!=null)time.setText("Comparação: "+ChapterEdits.format(start)+" → "+ChapterEdits.format(Math.min(duration,start+PREVIEW)));}
 private void controls(){boolean ready=source!=null&&duration>0&&!busy;choose.setEnabled(!busy);mode.setText(profile==1?"Perfil: voz suave":"Perfil: música suave");mode.setEnabled(!busy);position.setEnabled(ready);prepare.setEnabled(ready);save.setEnabled(ready);original.setEnabled(ready&&preview!=null);treated.setEnabled(ready&&preview!=null);updateTime();}
 private void stopPlayer(){if(player!=null){player.release();player=null;}}
 private void invalidatePreview(){generation++;if(work!=null)work.cancel(true);work=null;busy=false;stopPlayer();if(preview!=null){preview.delete();preview=null;}}
 private void load(Uri uri){invalidatePreview();source=null;duration=0;busy=true;status.setText("Conferindo o arquivo…");controls();int ticket=generation;Context c=getApplicationContext();work=worker.submit(()->{String label="Gravação",fingerprint;long length;try{
   try(Cursor cursor=c.getContentResolver().query(uri,new String[]{OpenableColumns.DISPLAY_NAME},null,null,null)){if(cursor!=null&&cursor.moveToFirst())label=cursor.getString(0);}
   MediaMetadataRetriever retriever=new MediaMetadataRetriever();try{retriever.setDataSource(c,uri);length=Long.parseLong(retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION));}finally{retriever.release();}
   try(MediaInput.Direct input=MediaInput.open(c,uri)){if(input==null||length<=0)throw new IOException("O arquivo precisa ter áudio e permitir leitura direta.");}
   fingerprint=AudioChapterStore.stamp(c,uri);String finalLabel=label;long finalLength=length;
   runOnUiThread(()->{if(ticket!=generation||isDestroyed())return;source=uri;name=finalLabel;stamp=fingerprint;duration=finalLength;start=Math.min(Math.max(0,start),Math.max(0,duration-PREVIEW));position.setProgress((int)(duration>PREVIEW?start*1000/(duration-PREVIEW):0));title.setText(name);busy=false;status.setText("Escolha um perfil e prepare a comparação.");controls();});
  }catch(Exception e){runOnUiThread(()->{if(ticket!=generation||isDestroyed())return;busy=false;status.setText(DownloadFailure.describe("Abrir gravação",e));controls();});}});}
 private void preparePreview(){invalidatePreview();busy=true;status.setText("Preparando 12 segundos para comparar…");controls();int ticket=generation,selectedProfile=profile;Uri uri=source;String fingerprint=stamp;long from=start,to=Math.min(duration,from+PREVIEW);Context c=getApplicationContext();
  work=worker.submit(()->{File out=new File(c.getCacheDir(),"restoration-preview-"+java.util.UUID.randomUUID()+".mp3");try{
   ChapterMp3Exporter.Control control=new ChapterMp3Exporter.Control(){public void check()throws IOException{if(Thread.currentThread().isInterrupted())throw new InterruptedIOException("Prévia cancelada");}public void progress(long at,long total){}};control.check();
   if(!fingerprint.equals(AudioChapterStore.stamp(c,uri)))throw new IOException("O arquivo mudou. Escolha-o novamente.");
   try(MediaInput.Direct input=MediaInput.open(c,uri)){if(input==null)throw new IOException("Arquivo indisponível");ChapterMp3Exporter.convert(input,out,192,from,to,selectedProfile,control);}control.check();
   if(!fingerprint.equals(AudioChapterStore.stamp(c,uri)))throw new IOException("O arquivo mudou durante a prévia.");
   runOnUiThread(()->{if(ticket!=generation||!started||isDestroyed()){out.delete();return;}preview=out;busy=false;status.setText("Prévia pronta. Compare os dois sons no mesmo trecho antes de salvar.");controls();});
  }catch(Exception e){out.delete();runOnUiThread(()->{if(ticket!=generation||isDestroyed())return;busy=false;status.setText(DownloadFailure.describe("Preparar prévia",e));controls();});}});
 }
 private void play(boolean restored){if(preview==null||source==null)return;stopPlayer();
  player=new ExoPlayer.Builder(this).setAudioAttributes(new AudioAttributes.Builder().setUsage(C.USAGE_MEDIA).setContentType(C.AUDIO_CONTENT_TYPE_MUSIC).build(),true).build();
  MediaItem item=restored?MediaItem.fromUri(Uri.fromFile(preview)):new MediaItem.Builder().setUri(source).setClippingConfiguration(new MediaItem.ClippingConfiguration.Builder().setStartPositionMs(start).setEndPositionMs(Math.min(duration,start+PREVIEW)).build()).build();
  player.addListener(new Player.Listener(){public void onPlayerError(PlaybackException error){status.setText("Não foi possível reproduzir a prévia: "+error.getErrorCodeName());stopPlayer();}});player.setMediaItem(item);player.prepare();player.play();status.setText(restored?"Ouvindo a cópia restaurada":"Ouvindo o original no mesmo trecho");
 }
 @Override protected void onStart(){super.onStart();started=true;}
 @Override protected void onStop(){started=false;stopPlayer();if(busy){invalidatePreview();if(status!=null)status.setText("Prévia interrompida. Prepare novamente ao retornar.");controls();}super.onStop();}
 @Override protected void onDestroy(){invalidatePreview();worker.shutdownNow();super.onDestroy();}
 @Override protected void onSaveInstanceState(Bundle state){super.onSaveInstanceState(state);state.putInt("profile",profile);state.putLong("start",start);if(source!=null)state.putString("source",source.toString());}
 @Override protected void onActivityResult(int request,int result,Intent data){super.onActivityResult(request,result,data);if(request==PICK&&result==RESULT_OK&&data!=null&&data.getData()!=null){Uri uri=data.getData();if((data.getFlags()&Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)!=0)try{getContentResolver().takePersistableUriPermission(uri,Intent.FLAG_GRANT_READ_URI_PERMISSION);}catch(SecurityException ignored){}start=0;load(uri);}}
}
