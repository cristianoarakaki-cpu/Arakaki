package br.com.onda;

import android.Manifest;
import android.app.*;
import android.content.*;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.media.*;
import android.net.Uri;
import android.os.*;
import android.provider.OpenableColumns;
import android.database.Cursor;
import android.text.*;
import android.view.*;
import android.widget.*;
import androidx.media3.session.MediaController;
import androidx.media3.session.SessionToken;
import com.google.common.util.concurrent.ListenableFuture;
import org.videolan.libvlc.LibVLC;
import org.videolan.libvlc.Media;
import org.videolan.libvlc.MediaPlayer;
import org.videolan.libvlc.util.VLCVideoLayout;
import java.util.*;
import java.util.concurrent.*;

@androidx.media3.common.util.UnstableApi
public class VideoActivity extends Activity {
    private static final int PERMISSION=420,OPEN=421;
    private final Handler handler=new Handler(Looper.getMainLooper());
    private final ExecutorService scanner=Executors.newSingleThreadExecutor();
    private final List<VideoStore.Item> videos=new ArrayList<>(),visible=new ArrayList<>();
    private List<VideoStore.Item> queue=Collections.emptyList();private int queueIndex=-1,scanGeneration;
    private VideoStore.Item current;private VideoStore.Item pending;
    private LibVLC engine;private MediaPlayer video;private ParcelFileDescriptor descriptor;
    private MediaController music;private ListenableFuture<MediaController> connection;
    private AudioManager audio;private AudioFocusRequest focus;private boolean hasFocus,started,fullscreen,seeking,software,receiverRegistered,keyboardVisible;
    private LinearLayout root,heading,browser,transport;private FrameLayout surfaceBox;private VLCVideoLayout surface;
    private Button play,full;private TextView now,position,status;private SeekBar seek;private EditText search;
    private BaseAdapter adapter;
    private final BroadcastReceiver noisy=new BroadcastReceiver(){@Override public void onReceive(Context c,Intent i){pauseVideo();}};
    private final Runnable tick=new Runnable(){public void run(){if(!started||video==null)return;update();if(video.isPlaying())handler.postDelayed(this,1000);}};
    @Override public void onCreate(Bundle state){
        super.onCreate(state);buildUi();
        try{
            ArrayList<String> options=new ArrayList<>();options.add("--no-video-title-show");options.add("--no-stats");
            engine=new LibVLC(this,options);video=new MediaPlayer(engine);video.attachViews(surface,null,false,false);
            video.setEventListener(event->{if(isDestroyed())return;switch(event.type){
                case MediaPlayer.Event.Playing:status.setText("Reproduzindo • "+(current==null?"vídeo":VideoText.format(current.file))+(software?" • decoder de software":""));android.util.Log.d("OndaVideo","playing "+(current==null?"":current.file));restartTick();break;
                case MediaPlayer.Event.ESSelected:if(video.getAudioTracksCount()>0&&video.getAudioTrack()>=0)android.util.Log.d("OndaVideo","audio "+(current==null?"":current.file));break;
                case MediaPlayer.Event.Vout:if(event.getVoutCount()>0)android.util.Log.d("OndaVideo","frames "+(current==null?"":current.file));break;
                case MediaPlayer.Event.Paused:case MediaPlayer.Event.Stopped:handler.removeCallbacks(tick);update();break;
                case MediaPlayer.Event.EndReached:handler.removeCallbacks(tick);if(started&&queueIndex>=0&&queueIndex+1<queue.size())open(queue.get(++queueIndex),false);else{update();abandonFocus();}break;
                case MediaPlayer.Event.EncounteredError:handler.removeCallbacks(tick);getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);if(!software&&current!=null&&started){open(current,true);}else{abandonFocus();status.setText("Não foi possível reproduzir este arquivo.");new AlertDialog.Builder(this).setTitle("Vídeo indisponível").setMessage("O arquivo pode estar danificado, protegido ou usar um codec incompatível. Tente outro vídeo.").setPositiveButton("OK",null).show();}break;
                default:break;
            }});
        }catch(RuntimeException|LinkageError e){status.setText("O motor de vídeo não iniciou neste aparelho. Atualize o aplicativo e tente novamente.");return;}
        audio=(AudioManager)getSystemService(AUDIO_SERVICE);
        focus=new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN).setAudioAttributes(new AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_MOVIE).build()).setOnAudioFocusChangeListener(change->{if(video==null)return;if(change==AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK)video.setVolume(25);else if(change==AudioManager.AUDIOFOCUS_GAIN)video.setVolume(100);else{hasFocus=false;pauseVideo();}},handler).build();
        connection=new MediaController.Builder(this,new SessionToken(this,new ComponentName(this,PlaybackService.class))).buildAsync();
        connection.addListener(()->{if(isDestroyed())return;try{music=connection.get();if(pending!=null&&started){VideoStore.Item item=pending;pending=null;open(item,false);}}catch(Exception e){pending=null;status.setText("Não foi possível conectar o áudio. Volte e tente novamente.");}},handler::post);
        IntentFilter filter=new IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY);if(Build.VERSION.SDK_INT>=33)registerReceiver(noisy,filter,Context.RECEIVER_NOT_EXPORTED);else registerReceiver(noisy,filter);receiverRegistered=true;
        permission(false);
    }
    private void buildUi(){
        root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);Ui.background(root);
        root.setOnApplyWindowInsetsListener((v,i)->{int pad=fullscreen?0:Ui.dp(this,16);root.setPadding(pad,fullscreen?0:pad+i.getSystemWindowInsetTop(),pad,fullscreen?0:pad+i.getSystemWindowInsetBottom());return i;});setContentView(root);
        root.getViewTreeObserver().addOnGlobalLayoutListener(()->{
            android.graphics.Rect frame=new android.graphics.Rect();root.getWindowVisibleDisplayFrame(frame);
            boolean visible=root.getRootView().getHeight()-frame.bottom>Ui.dp(this,150);
            if(visible==keyboardVisible||surfaceBox==null)return;keyboardVisible=visible;
            if(visible&&video!=null&&video.isPlaying())pauseVideo();
            surfaceBox.setVisibility(visible?View.GONE:View.VISIBLE);transport.setVisibility(visible?View.GONE:View.VISIBLE);now.setVisibility(visible||fullscreen?View.GONE:View.VISIBLE);
        });
        heading=new LinearLayout(this);heading.setGravity(Gravity.CENTER_VERTICAL);Button back=Ui.button(this,"‹",v->onBackPressed());Ui.ghost(back);back.setContentDescription("Voltar à música");heading.addView(back,new LinearLayout.LayoutParams(Ui.dp(this,48),Ui.dp(this,48)));TextView name=Ui.text(this,"Onda Vídeos",25,Ui.TEXT);Ui.bold(name);heading.addView(name,new LinearLayout.LayoutParams(0,-2,1));Button about=Ui.button(this,"ⓘ",v->about());Ui.ghost(about);about.setContentDescription("Formatos e licenças de vídeo");heading.addView(about,new LinearLayout.LayoutParams(Ui.dp(this,48),Ui.dp(this,48)));root.addView(heading);
        now=Ui.text(this,"Escolha um vídeo para assistir",14,Ui.CYAN);now.setMaxLines(1);now.setEllipsize(TextUtils.TruncateAt.END);now.setPadding(0,Ui.dp(this,8),0,Ui.dp(this,8));root.addView(now);
        surfaceBox=new FrameLayout(this);surfaceBox.setBackgroundColor(Color.BLACK);surface=new VLCVideoLayout(this);surfaceBox.addView(surface,new FrameLayout.LayoutParams(-1,-1));root.addView(surfaceBox,new LinearLayout.LayoutParams(-1,Ui.dp(this,205)));
        transport=new LinearLayout(this);transport.setOrientation(LinearLayout.VERTICAL);Ui.playerCard(transport);transport.setPadding(Ui.dp(this,8),0,Ui.dp(this,8),0);root.addView(transport);
        seek=new SeekBar(this);seek.setContentDescription("Posição no vídeo");transport.addView(seek,new LinearLayout.LayoutParams(-1,Ui.dp(this,24)));
        seek.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener(){public void onProgressChanged(SeekBar b,int progress,boolean user){}public void onStartTrackingTouch(SeekBar b){seeking=true;}public void onStopTrackingTouch(SeekBar b){if(video!=null&&video.isSeekable())video.setTime((long)(video.getLength()*(b.getProgress()/1000d)));seeking=false;update();}});seek.setMax(1000);
        LinearLayout controls=new LinearLayout(this);controls.setGravity(Gravity.CENTER_VERTICAL);play=Ui.button(this,"Reproduzir",v->{if(video==null||current==null)return;if(video.isPlaying())pauseVideo();else resumeVideo();});Ui.primary(play);play.setContentDescription("Reproduzir vídeo");controls.addView(play,new LinearLayout.LayoutParams(Ui.dp(this,105),Ui.dp(this,48)));
        position=Ui.text(this,"0:00 / 0:00",11,Ui.MUTED);position.setGravity(Gravity.CENTER);controls.addView(position,new LinearLayout.LayoutParams(0,-2,1));full=Ui.button(this,"Tela cheia",v->setFullscreen(!fullscreen));Ui.ghost(full);full.setContentDescription("Tela cheia do vídeo");controls.addView(full,new LinearLayout.LayoutParams(Ui.dp(this,110),Ui.dp(this,48)));transport.addView(controls);
        browser=new LinearLayout(this);browser.setOrientation(LinearLayout.VERTICAL);root.addView(browser,new LinearLayout.LayoutParams(-1,0,1));
        LinearLayout actions=new LinearLayout(this);Button allow=Ui.button(this,"Acesso aos vídeos",v->permission(true));Ui.ghost(allow);actions.addView(allow,new LinearLayout.LayoutParams(0,Ui.dp(this,48),1));Button file=Ui.button(this,"Abrir arquivo",v->pickFile());Ui.chip(file,true);file.setContentDescription("Abrir arquivo de vídeo");actions.addView(file,new LinearLayout.LayoutParams(0,Ui.dp(this,48),1));browser.addView(actions);
        search=new EditText(this);Ui.input(search);search.setHint("Buscar vídeo no celular");search.setContentDescription("Buscar vídeos por nome");browser.addView(search,new LinearLayout.LayoutParams(-1,Ui.dp(this,48)));search.addTextChangedListener(new TextWatcher(){public void beforeTextChanged(CharSequence s,int a,int c,int f){}public void afterTextChanged(Editable e){}public void onTextChanged(CharSequence s,int st,int before,int count){render();}});
        status=Ui.text(this,"Seus vídeos ficam no celular.",12,Ui.MUTED);status.setPadding(0,Ui.dp(this,8),0,Ui.dp(this,8));browser.addView(status);
        ListView list=new ListView(this);list.setDivider(null);list.setDividerHeight(Ui.dp(this,6));list.setCacheColorHint(Color.TRANSPARENT);browser.addView(list,new LinearLayout.LayoutParams(-1,0,1));
        adapter=new BaseAdapter(){public int getCount(){return visible.size();}public Object getItem(int i){return visible.get(i);}public long getItemId(int i){return i;}public View getView(int i,View reusable,android.view.ViewGroup parent){LinearLayout row;TextView title,detail;if(reusable==null){row=new LinearLayout(VideoActivity.this);row.setGravity(Gravity.CENTER_VERTICAL);row.setPadding(Ui.dp(VideoActivity.this,12),Ui.dp(VideoActivity.this,12),Ui.dp(VideoActivity.this,12),Ui.dp(VideoActivity.this,12));TextView icon=Ui.text(VideoActivity.this,"▶",23,Ui.CYAN);row.addView(icon,new LinearLayout.LayoutParams(Ui.dp(VideoActivity.this,40),-2));LinearLayout copy=new LinearLayout(VideoActivity.this);copy.setOrientation(LinearLayout.VERTICAL);title=Ui.text(VideoActivity.this,"",15,Ui.TEXT);title.setMaxLines(1);title.setEllipsize(TextUtils.TruncateAt.END);Ui.bold(title);detail=Ui.text(VideoActivity.this,"",12,Ui.MUTED);detail.setPadding(0,Ui.dp(VideoActivity.this,5),0,0);copy.addView(title);copy.addView(detail);row.addView(copy,new LinearLayout.LayoutParams(0,-2,1));row.setTag(new TextView[]{title,detail});}else{row=(LinearLayout)reusable;TextView[] holder=(TextView[])row.getTag();title=holder[0];detail=holder[1];}VideoStore.Item item=visible.get(i);title.setText(item.title);detail.setText(VideoText.format(item.file)+"  •  "+VideoText.duration(item.duration)+"  •  "+android.text.format.Formatter.formatShortFileSize(VideoActivity.this,item.size));Ui.card(row,current!=null&&current.uri.equals(item.uri));row.setContentDescription("Assistir "+item.file);return row;}};
        list.setAdapter(adapter);list.setOnItemClickListener((a,v,i,id)->{queue=new ArrayList<>(visible);queueIndex=i;open(queue.get(i),false);});
    }
    private boolean allowed(){if(Build.VERSION.SDK_INT>=33)return checkSelfPermission(Manifest.permission.READ_MEDIA_VIDEO)==PackageManager.PERMISSION_GRANTED||(Build.VERSION.SDK_INT>=34&&checkSelfPermission(Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED)==PackageManager.PERMISSION_GRANTED);return checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE)==PackageManager.PERMISSION_GRANTED;}
    private void permission(boolean request){if(allowed()&&!request){scan();return;}if(!request){status.setText("Toque em Acesso aos vídeos para listar sua biblioteca, ou em Abrir arquivo.");return;}if(Build.VERSION.SDK_INT>=34)requestPermissions(new String[]{Manifest.permission.READ_MEDIA_VIDEO,Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED},PERMISSION);else requestPermissions(new String[]{Build.VERSION.SDK_INT>=33?Manifest.permission.READ_MEDIA_VIDEO:Manifest.permission.READ_EXTERNAL_STORAGE},PERMISSION);}
    @Override public void onRequestPermissionsResult(int request,String[] permissions,int[] results){super.onRequestPermissionsResult(request,permissions,results);if(request==PERMISSION){if(allowed())scan();else{videos.clear();render();status.setText("Acesso não concedido. Você ainda pode usar Abrir arquivo.");}}}
    private void scan(){final int generation=++scanGeneration;status.setText("Buscando vídeos…");scanner.execute(()->{try{List<VideoStore.Item> found=VideoStore.scan(this);runOnUiThread(()->{if(isDestroyed()||generation!=scanGeneration)return;videos.clear();videos.addAll(found);render();});}catch(Exception e){runOnUiThread(()->{if(!isDestroyed()&&generation==scanGeneration){videos.clear();render();status.setText("Não foi possível listar os vídeos. Use Acesso aos vídeos ou Abrir arquivo.");}});}});}
    private void render(){if(adapter==null)return;visible.clear();for(VideoStore.Item item:videos)if(VideoText.matches(item.title,item.file,search.getText().toString()))visible.add(item);adapter.notifyDataSetChanged();status.setText(visible.size()+" de "+videos.size()+" vídeos"+(videos.isEmpty()?" • use Abrir arquivo para outras pastas":""));}
    private void pickFile(){Intent intent=new Intent(Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType("*/*");try{startActivityForResult(intent,OPEN);}catch(ActivityNotFoundException e){Toast.makeText(this,"Nenhum seletor de arquivos disponível.",Toast.LENGTH_LONG).show();}}
    @Override protected void onActivityResult(int request,int result,Intent data){super.onActivityResult(request,result,data);if(request!=OPEN||result!=RESULT_OK||data==null||data.getData()==null)return;Uri uri=data.getData();String title="Vídeo selecionado";try(Cursor c=getContentResolver().query(uri,new String[]{OpenableColumns.DISPLAY_NAME},null,null,null)){if(c!=null&&c.moveToFirst()&&c.getString(0)!=null)title=c.getString(0);}catch(Exception ignored){}VideoStore.Item item=new VideoStore.Item(uri,title,title,0,0);queue=new ArrayList<>(Collections.singletonList(item));queueIndex=0;open(item,false);}
    private void open(VideoStore.Item item,boolean useSoftware){
        if(video==null||!started)return;if(music==null){pending=item;status.setText("Preparando áudio…");return;}
        music.pause();if(!requestFocus())return;video.stop();closeDescriptor();current=item;software=useSoftware;now.setText(item.title);adapter.notifyDataSetChanged();
        try{
            descriptor=getContentResolver().openFileDescriptor(item.uri,"r");if(descriptor==null)throw new java.io.IOException("Arquivo indisponível");
            Media media=new Media(engine,descriptor.getFileDescriptor());try{media.setHWDecoderEnabled(!useSoftware,false);video.setMedia(media);}finally{media.release();}
            video.play();status.setText(useSoftware?"Reproduzindo com decoder de software":"Abrindo vídeo…");
        }catch(Exception e){abandonFocus();status.setText("Não foi possível abrir o vídeo. O arquivo pode ter sido removido ou o acesso expirou.");Toast.makeText(this,"Tente selecionar o arquivo novamente.",Toast.LENGTH_LONG).show();closeDescriptor();}
    }
    private boolean requestFocus(){if(audio==null||focus==null)return false;hasFocus=audio.requestAudioFocus(focus)==AudioManager.AUDIOFOCUS_REQUEST_GRANTED;if(!hasFocus)Toast.makeText(this,"Áudio ocupado. Tente novamente.",Toast.LENGTH_SHORT).show();return hasFocus;}
    private void abandonFocus(){if(audio!=null&&focus!=null)audio.abandonAudioFocusRequest(focus);hasFocus=false;}
    private void resumeVideo(){if(video==null||current==null||!started||music==null)return;music.pause();if(!requestFocus())return;if(video.getLength()>0&&video.getTime()>=video.getLength()-500){open(current,software);return;}video.play();}
    private void pauseVideo(){if(video!=null){video.pause();android.util.Log.d("OndaVideo","paused");}handler.removeCallbacks(tick);getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);abandonFocus();update();}
    private void update(){if(video==null)return;boolean playing=video.isPlaying();play.setText(playing?"Pausar":"Reproduzir");play.setContentDescription(playing?"Pausar vídeo":"Reproduzir vídeo");long length=Math.max(0,video.getLength()),time=Math.max(0,video.getTime());if(!seeking)seek.setProgress(length>0?(int)Math.min(1000,time*1000/length):0);seek.setEnabled(video.isSeekable());position.setText(VideoText.duration(time)+" / "+VideoText.duration(length));if(started&&playing)getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);else getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);}
    private void restartTick(){handler.removeCallbacks(tick);if(started)handler.post(tick);}
    private void setFullscreen(boolean value){fullscreen=value;heading.setVisibility(value?View.GONE:View.VISIBLE);now.setVisibility(value?View.GONE:View.VISIBLE);browser.setVisibility(value?View.GONE:View.VISIBLE);surfaceBox.setLayoutParams(value?new LinearLayout.LayoutParams(-1,0,1):new LinearLayout.LayoutParams(-1,Ui.dp(this,205)));full.setText(value?"Sair da tela":"Tela cheia");full.setContentDescription(value?"Sair da tela cheia":"Tela cheia do vídeo");getWindow().getDecorView().setSystemUiVisibility(value?View.SYSTEM_UI_FLAG_FULLSCREEN|View.SYSTEM_UI_FLAG_HIDE_NAVIGATION|View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY|View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN|View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION|View.SYSTEM_UI_FLAG_LAYOUT_STABLE:View.SYSTEM_UI_FLAG_LAYOUT_STABLE);setRequestedOrientation(value?ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE:ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED);root.requestApplyInsets();}
    @Override public void onBackPressed(){if(fullscreen)setFullscreen(false);else super.onBackPressed();}
    private void about(){new AlertDialog.Builder(this).setTitle("Motor de vídeo LibVLC").setMessage("Suporte amplo a MP4, MKV, AVI, MOV, WebM, FLV, WMV, MPEG, TS e outros contêineres. A compatibilidade depende dos codecs, do aparelho e do arquivo. Conteúdo com DRM não é suportado.\n\nLibVLC 3.7.7 © VideoLAN e colaboradores, LGPL 2.1 ou posterior. Bibliotecas nativas sem modificações; fonte e instruções de compilação em code.videolan.org/videolan/libvlcjni. O APK inclui a licença em assets/libvlc-license.txt.\n\nO vídeo pausa ao sair da tela para economizar bateria.").setPositiveButton("OK",null).setNeutralButton("Licença",(d,w)->showLicense()).show();}
    private void showLicense(){try(java.io.InputStream input=getAssets().open("libvlc-license.txt")){java.io.ByteArrayOutputStream out=new java.io.ByteArrayOutputStream();byte[] buf=new byte[4096];int n;while((n=input.read(buf))!=-1)out.write(buf,0,n);TextView text=Ui.text(this,out.toString("UTF-8"),12,Ui.TEXT);text.setPadding(24,24,24,24);ScrollView scroll=new ScrollView(this);scroll.addView(text);new AlertDialog.Builder(this).setTitle("LibVLC • LGPL 2.1").setView(scroll).setPositiveButton("Fechar",null).show();}catch(Exception e){Toast.makeText(this,"Licença indisponível.",Toast.LENGTH_SHORT).show();}}
    private void closeDescriptor(){if(descriptor!=null){try{descriptor.close();}catch(java.io.IOException ignored){}descriptor=null;}}
    @Override protected void onStart(){super.onStart();started=true;update();}
    @Override protected void onResume(){super.onResume();if(search!=null&&allowed())scan();}
    @Override protected void onStop(){started=false;pending=null;pauseVideo();super.onStop();}
    @Override public void onDestroy(){handler.removeCallbacksAndMessages(null);scanner.shutdownNow();if(receiverRegistered)unregisterReceiver(noisy);abandonFocus();if(video!=null){video.setEventListener(null);video.stop();video.detachViews();video.release();}closeDescriptor();if(engine!=null)engine.release();if(connection!=null)MediaController.releaseFuture(connection);super.onDestroy();}
}
