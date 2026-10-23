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
    private static final int PERMISSION=420,OPEN=421,SUBTITLE=422;
    private final Handler handler=new Handler(Looper.getMainLooper());
    private final ExecutorService scanner=Executors.newSingleThreadExecutor();
    private final List<VideoStore.Item> videos=new ArrayList<>(),visible=new ArrayList<>();
    private List<VideoStore.Item> queue=Collections.emptyList();private int queueIndex=-1,scanGeneration;
    private VideoStore.Item current;private VideoStore.Item pending;private long pendingSeek;
    private LibVLC engine;private MediaPlayer video;private ParcelFileDescriptor descriptor;
    private MediaController music;private ListenableFuture<MediaController> connection;
    private AudioManager audio;private AudioFocusRequest focus;private boolean hasFocus,started,fullscreen,seeking,software,receiverRegistered,keyboardVisible;
    private LinearLayout root,heading,browser,transport,navigation;private FrameLayout surfaceBox;private VLCVideoLayout surface;
    private Button play,full;private TextView now,position,status;private SeekBar seek;private EditText search;
    private BaseAdapter adapter;
    private java.io.File subtitleFile;private String subtitleName="";private boolean subtitleEnabled,subtitleAttached,subtitleWasPlaying,ducked,captionsOff;
    private int subtitleGeneration,videoVolume=100;private TextView gestureFeedback;private View gestureLayer;
    private AlertDialog resumeDialog;
    private final Runnable hideGesture=()->{if(gestureFeedback!=null)gestureFeedback.setVisibility(View.GONE);};
    private final BroadcastReceiver noisy=new BroadcastReceiver(){@Override public void onReceive(Context c,Intent i){pauseVideo();}};
    private final Runnable tick=new Runnable(){public void run(){if(!started||video==null)return;update();if(video.isPlaying())handler.postDelayed(this,1000);}};
    @Override public void onCreate(Bundle state){
        super.onCreate(state);videoVolume=Math.max(0,Math.min(100,getSharedPreferences("video_controls",0).getInt("volume",100)));buildUi();
        try{
            ArrayList<String> options=new ArrayList<>();options.add("--no-video-title-show");options.add("--no-stats");
            engine=new LibVLC(this,options);video=new MediaPlayer(engine);video.attachViews(surface,null,false,false);
            video.setEventListener(event->{if(isDestroyed())return;switch(event.type){
                case MediaPlayer.Event.Playing:applyPendingSeek();applyVideoVolume();attachSubtitle();status.setText("Reproduzindo • "+(current==null?"vídeo":VideoText.format(current.file))+(software?" • decoder de software":""));android.util.Log.d("OndaVideo","playing "+(current==null?"":current.file));restartTick();break;
                case MediaPlayer.Event.TimeChanged:if(!video.isPlaying())update();break;
                case MediaPlayer.Event.SeekableChanged:case MediaPlayer.Event.LengthChanged:applyPendingSeek();break;
                case MediaPlayer.Event.ESSelected:if(video.getAudioTracksCount()>0&&video.getAudioTrack()>=0)android.util.Log.d("OndaVideo","audio "+(current==null?"":current.file));if(video.getSpuTrack()>=0)android.util.Log.d("OndaVideo","subtitle-selected "+video.getSpuTrack());break;
                case MediaPlayer.Event.Vout:if(event.getVoutCount()>0)android.util.Log.d("OndaVideo","frames "+(current==null?"":current.file));break;
                case MediaPlayer.Event.Paused:case MediaPlayer.Event.Stopped:handler.removeCallbacks(tick);update();break;
                case MediaPlayer.Event.EndReached:if(current!=null)VideoProgressStore.clear(this,current.uri);handler.removeCallbacks(tick);if(started&&queueIndex>=0&&queueIndex+1<queue.size())open(queue.get(++queueIndex),false);else{update();abandonFocus();}break;
                case MediaPlayer.Event.EncounteredError:handler.removeCallbacks(tick);getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);if(!software&&current!=null&&started){open(current,true,Math.max(0,video.getTime()));}else{abandonFocus();status.setText("Não foi possível reproduzir este arquivo.");new AlertDialog.Builder(this).setTitle("Vídeo indisponível").setMessage("O arquivo pode estar danificado, protegido ou usar um codec incompatível. Tente outro vídeo.").setPositiveButton("OK",null).show();}break;
                default:break;
            }});
        }catch(RuntimeException|LinkageError e){status.setText("O motor de vídeo não iniciou neste aparelho. Atualize o aplicativo e tente novamente.");return;}
        audio=(AudioManager)getSystemService(AUDIO_SERVICE);
        focus=new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN).setAudioAttributes(new AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_MOVIE).build()).setOnAudioFocusChangeListener(change->{if(video==null)return;if(change==AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK){ducked=true;applyVideoVolume();}else if(change==AudioManager.AUDIOFOCUS_GAIN){ducked=false;applyVideoVolume();}else{hasFocus=false;pauseVideo();}},handler).build();
        connection=new MediaController.Builder(this,new SessionToken(this,new ComponentName(this,PlaybackService.class))).buildAsync();
        connection.addListener(()->{if(isDestroyed())return;try{music=connection.get();if(pending!=null&&started){VideoStore.Item item=pending;pending=null;choose(item);}}catch(Exception e){pending=null;status.setText("Não foi possível conectar o áudio. Volte e tente novamente.");}},handler::post);
        IntentFilter filter=new IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY);if(Build.VERSION.SDK_INT>=33)registerReceiver(noisy,filter,Context.RECEIVER_NOT_EXPORTED);else registerReceiver(noisy,filter);receiverRegistered=true;
        receiveView(getIntent());permission(false);
    }
    private void buildUi(){
        root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);Ui.background(root);
        root.setOnApplyWindowInsetsListener((v,i)->{int pad=fullscreen?0:Ui.dp(this,16);root.setPadding(pad,fullscreen?0:pad+i.getSystemWindowInsetTop(),pad,fullscreen?0:pad+i.getSystemWindowInsetBottom());return i;});setContentView(root);
        root.getViewTreeObserver().addOnGlobalLayoutListener(()->{
            android.graphics.Rect frame=new android.graphics.Rect();root.getWindowVisibleDisplayFrame(frame);
            boolean visible=root.getRootView().getHeight()-frame.bottom>Ui.dp(this,150);
            if(visible==keyboardVisible||surfaceBox==null)return;keyboardVisible=visible;
            if(visible&&video!=null&&video.isPlaying())pauseVideo();
            surfaceBox.setVisibility(visible?View.GONE:View.VISIBLE);transport.setVisibility(visible?View.GONE:View.VISIBLE);now.setVisibility(visible||fullscreen?View.GONE:View.VISIBLE);if(navigation!=null)navigation.setVisibility(visible||fullscreen?View.GONE:View.VISIBLE);
        });
        heading=new LinearLayout(this);heading.setGravity(Gravity.CENTER_VERTICAL);Button back=Ui.button(this,"‹",v->onBackPressed());Ui.ghost(back);back.setContentDescription("Voltar à música");heading.addView(back,new LinearLayout.LayoutParams(Ui.dp(this,48),Ui.dp(this,48)));TextView name=Ui.text(this,"Onda Vídeos",25,Ui.TEXT);Ui.bold(name);heading.addView(name,new LinearLayout.LayoutParams(0,-2,1));Button menu=Ui.menuButton(this,"Menu de vídeos",v->Ui.menu(this,v,new String[]{"Abrir arquivo","Legendas","Gestos e posição","Acesso aos vídeos","Recarregar vídeos","Formatos e licenças"},new String[]{"Abrir arquivo de vídeo","Legendas do vídeo","Gestos e posição","Acesso aos vídeos","Recarregar vídeos","Formatos e licenças de vídeo"},new Runnable[]{this::pickFile,this::subtitles,this::gestureHelp,()->permission(true),()->permission(false),this::about}));heading.addView(menu,new LinearLayout.LayoutParams(Ui.dp(this,48),Ui.dp(this,48)));root.addView(heading);
        now=Ui.text(this,"Escolha um vídeo para assistir",14,Ui.CYAN);now.setMaxLines(1);now.setEllipsize(TextUtils.TruncateAt.END);now.setPadding(0,Ui.dp(this,8),0,Ui.dp(this,8));root.addView(now);
        surfaceBox=new FrameLayout(this);surfaceBox.setBackgroundColor(Color.BLACK);surface=new VLCVideoLayout(this);surfaceBox.addView(surface,new FrameLayout.LayoutParams(-1,-1));
        gestureLayer=new View(this);gestureLayer.setContentDescription("Área de gestos do vídeo");surfaceBox.addView(gestureLayer,new FrameLayout.LayoutParams(-1,-1));
        gestureFeedback=Ui.text(this,"",17,Color.WHITE);gestureFeedback.setGravity(Gravity.CENTER);gestureFeedback.setBackgroundColor(0xBB111A2B);gestureFeedback.setPadding(Ui.dp(this,12),Ui.dp(this,8),Ui.dp(this,12),Ui.dp(this,8));gestureFeedback.setVisibility(View.GONE);FrameLayout.LayoutParams feedbackParams=new FrameLayout.LayoutParams(-2,-2,Gravity.TOP|Gravity.CENTER_HORIZONTAL);feedbackParams.topMargin=Ui.dp(this,12);surfaceBox.addView(gestureFeedback,feedbackParams);setupGestures();root.addView(surfaceBox,new LinearLayout.LayoutParams(-1,Ui.dp(this,205)));
        transport=new LinearLayout(this);transport.setOrientation(LinearLayout.VERTICAL);Ui.playerCard(transport);transport.setPadding(Ui.dp(this,8),0,Ui.dp(this,8),0);root.addView(transport);
        seek=new SeekBar(this);seek.setContentDescription("Posição no vídeo");transport.addView(seek,new LinearLayout.LayoutParams(-1,Ui.dp(this,24)));
        seek.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener(){public void onProgressChanged(SeekBar b,int progress,boolean user){}public void onStartTrackingTouch(SeekBar b){seeking=true;}public void onStopTrackingTouch(SeekBar b){if(video!=null&&video.isSeekable()){long target=(long)(video.getLength()*(b.getProgress()/1000d));video.setTime(target);if(current!=null)VideoProgressStore.save(VideoActivity.this,current.uri,target,video.getLength());}seeking=false;update();}});seek.setMax(1000);
        LinearLayout controls=new LinearLayout(this);controls.setGravity(Gravity.CENTER_VERTICAL);play=Ui.button(this,"Reproduzir",v->{if(video==null||current==null)return;if(video.isPlaying())pauseVideo();else resumeVideo();});Ui.primary(play);play.setContentDescription("Reproduzir vídeo");controls.addView(play,new LinearLayout.LayoutParams(Ui.dp(this,92),Ui.dp(this,48)));
        position=Ui.text(this,"0:00 / 0:00",11,Ui.MUTED);position.setGravity(Gravity.CENTER);controls.addView(position,new LinearLayout.LayoutParams(0,-2,1));full=Ui.button(this,"Tela cheia",v->setFullscreen(!fullscreen));Ui.ghost(full);full.setContentDescription("Tela cheia do vídeo");controls.addView(full,new LinearLayout.LayoutParams(Ui.dp(this,88),Ui.dp(this,48)));Button captions=Ui.button(this,"CC",v->subtitles());captions.setContentDescription("Legendas do vídeo");Ui.ghost(captions);controls.addView(captions,new LinearLayout.LayoutParams(Ui.dp(this,44),Ui.dp(this,48)));transport.addView(controls);
        browser=new LinearLayout(this);browser.setOrientation(LinearLayout.VERTICAL);root.addView(browser,new LinearLayout.LayoutParams(-1,0,1));
        search=new EditText(this);Ui.input(search);search.setHint("Buscar vídeo no celular");search.setContentDescription("Buscar vídeos por nome");browser.addView(search,new LinearLayout.LayoutParams(-1,Ui.dp(this,48)));search.addTextChangedListener(new TextWatcher(){public void beforeTextChanged(CharSequence s,int a,int c,int f){}public void afterTextChanged(Editable e){}public void onTextChanged(CharSequence s,int st,int before,int count){render();}});
        status=Ui.text(this,"Seus vídeos ficam no celular.",12,Ui.MUTED);status.setPadding(0,Ui.dp(this,8),0,Ui.dp(this,8));browser.addView(status);
        ListView list=new ListView(this);list.setDivider(null);list.setDividerHeight(Ui.dp(this,6));list.setCacheColorHint(Color.TRANSPARENT);browser.addView(list,new LinearLayout.LayoutParams(-1,0,1));
        adapter=new BaseAdapter(){public int getCount(){return visible.size();}public Object getItem(int i){return visible.get(i);}public long getItemId(int i){return i;}public View getView(int i,View reusable,android.view.ViewGroup parent){LinearLayout row;TextView title,detail;if(reusable==null){row=new LinearLayout(VideoActivity.this);row.setGravity(Gravity.CENTER_VERTICAL);row.setPadding(Ui.dp(VideoActivity.this,12),Ui.dp(VideoActivity.this,12),Ui.dp(VideoActivity.this,12),Ui.dp(VideoActivity.this,12));TextView icon=Ui.text(VideoActivity.this,"▶",23,Ui.CYAN);row.addView(icon,new LinearLayout.LayoutParams(Ui.dp(VideoActivity.this,40),-2));LinearLayout copy=new LinearLayout(VideoActivity.this);copy.setOrientation(LinearLayout.VERTICAL);title=Ui.text(VideoActivity.this,"",15,Ui.TEXT);title.setMaxLines(1);title.setEllipsize(TextUtils.TruncateAt.END);Ui.bold(title);detail=Ui.text(VideoActivity.this,"",12,Ui.MUTED);detail.setPadding(0,Ui.dp(VideoActivity.this,5),0,0);copy.addView(title);copy.addView(detail);row.addView(copy,new LinearLayout.LayoutParams(0,-2,1));row.setTag(new TextView[]{title,detail});}else{row=(LinearLayout)reusable;TextView[] holder=(TextView[])row.getTag();title=holder[0];detail=holder[1];}VideoStore.Item item=visible.get(i);title.setText(item.title);long saved=VideoProgressStore.read(VideoActivity.this,item.uri,item.duration);detail.setText((saved>0?"Continuar de "+VideoText.duration(saved)+"  •  ":"")+VideoText.format(item.file)+"  •  "+VideoText.duration(item.duration)+"  •  "+android.text.format.Formatter.formatShortFileSize(VideoActivity.this,item.size));Ui.card(row,current!=null&&current.uri.equals(item.uri));row.setContentDescription("Assistir "+item.file);return row;}};
        list.setAdapter(adapter);list.setOnItemClickListener((a,v,i,id)->{queue=new ArrayList<>(visible);queueIndex=i;choose(queue.get(i));});
        navigation=Ui.navigation(this,1);root.addView(navigation);
    }
    private boolean allowed(){if(Build.VERSION.SDK_INT>=33)return checkSelfPermission(Manifest.permission.READ_MEDIA_VIDEO)==PackageManager.PERMISSION_GRANTED||(Build.VERSION.SDK_INT>=34&&checkSelfPermission(Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED)==PackageManager.PERMISSION_GRANTED);return checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE)==PackageManager.PERMISSION_GRANTED;}
    private void permission(boolean request){if(allowed()&&!request){scan();return;}if(!request){status.setText("Abra o menu ☰ para permitir vídeos ou escolher um arquivo.");return;}if(Build.VERSION.SDK_INT>=34)requestPermissions(new String[]{Manifest.permission.READ_MEDIA_VIDEO,Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED},PERMISSION);else requestPermissions(new String[]{Build.VERSION.SDK_INT>=33?Manifest.permission.READ_MEDIA_VIDEO:Manifest.permission.READ_EXTERNAL_STORAGE},PERMISSION);}
    @Override public void onRequestPermissionsResult(int request,String[] permissions,int[] results){super.onRequestPermissionsResult(request,permissions,results);if(request==PERMISSION){if(allowed())scan();else{videos.clear();render();status.setText("Acesso não concedido. Use Menu → Abrir arquivo.");}}}
    private void scan(){final int generation=++scanGeneration;status.setText("Buscando vídeos…");scanner.execute(()->{try{List<VideoStore.Item> found=VideoStore.scan(this);runOnUiThread(()->{if(isDestroyed()||generation!=scanGeneration)return;videos.clear();videos.addAll(found);render();});}catch(Exception e){runOnUiThread(()->{if(!isDestroyed()&&generation==scanGeneration){videos.clear();render();status.setText("Não foi possível listar os vídeos. Use o menu para permitir acesso ou abrir um arquivo.");}});}});}
    private void render(){if(adapter==null)return;visible.clear();for(VideoStore.Item item:videos)if(VideoText.matches(item.title,item.file,search.getText().toString()))visible.add(item);adapter.notifyDataSetChanged();status.setText(visible.size()+" de "+videos.size()+" vídeos"+(videos.isEmpty()?" • Menu → Abrir arquivo":""));}
    private void pickFile(){Intent intent=new Intent(Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType("*/*").putExtra(android.provider.DocumentsContract.EXTRA_INITIAL_URI,android.provider.DocumentsContract.buildDocumentUri("com.android.externalstorage.documents","primary:Movies"));try{startActivityForResult(intent,OPEN);}catch(ActivityNotFoundException e){Toast.makeText(this,"Nenhum seletor de arquivos disponível.",Toast.LENGTH_LONG).show();}}
    private VideoStore.Item selected(Uri uri){String title="Vídeo selecionado";try(Cursor c=getContentResolver().query(uri,new String[]{OpenableColumns.DISPLAY_NAME},null,null,null)){if(c!=null&&c.moveToFirst()&&c.getString(0)!=null)title=c.getString(0);}catch(Exception ignored){}return new VideoStore.Item(uri,title,title,0,0);}
    private void selectedFile(Uri uri){VideoStore.Item item=selected(uri);queue=new ArrayList<>(Collections.singletonList(item));queueIndex=0;pending=item;openPending();}
    private void openPending(){if(pending!=null&&started&&music!=null){VideoStore.Item item=pending;pending=null;choose(item);}}
    private void receiveView(Intent intent){Uri uri=intent.getData();if(Intent.ACTION_VIEW.equals(intent.getAction())&&uri!=null&&"content".equalsIgnoreCase(uri.getScheme()))selectedFile(uri);}
    @Override protected void onNewIntent(Intent intent){super.onNewIntent(intent);setIntent(intent);receiveView(intent);}
    @Override protected void onActivityResult(int request,int result,Intent data){super.onActivityResult(request,result,data);if(result!=RESULT_OK||data==null||data.getData()==null)return;if(request==OPEN)selectedFile(data.getData());else if(request==SUBTITLE)loadSubtitle(data.getData());}
    private void open(VideoStore.Item item,boolean useSoftware){open(item,useSoftware,0);}
    private void open(VideoStore.Item item,boolean useSoftware,long startPosition){
        if(video==null||!started)return;if(music==null){pending=item;status.setText("Preparando áudio…");return;}
        music.pause();if(!requestFocus())return;remember();
        if(current==null||!current.uri.equals(item.uri)){subtitleGeneration++;clearSubtitle();}subtitleAttached=false;video.stop();
        // A document picker destroys the old Surface. Bind a fresh window after stopping,
        // so software decoders wait for the new Surface instead of producing audio only.
        video.detachViews();video.attachViews(surface,null,false,false);pendingSeek=Math.max(0,startPosition);
        closeDescriptor();current=item;software=useSoftware;now.setText(item.title);adapter.notifyDataSetChanged();
        try{
            descriptor=getContentResolver().openFileDescriptor(item.uri,"r");if(descriptor==null)throw new java.io.IOException("Arquivo indisponível");
            Media media=new Media(engine,descriptor.getFileDescriptor());try{media.setHWDecoderEnabled(!useSoftware,false);video.setMedia(media);}finally{media.release();}
            video.play();status.setText(useSoftware?"Reproduzindo com decoder de software":"Abrindo vídeo…");
        }catch(Exception e){abandonFocus();status.setText("Não foi possível abrir o vídeo. O arquivo pode ter sido removido ou o acesso expirou.");Toast.makeText(this,"Tente selecionar o arquivo novamente.",Toast.LENGTH_LONG).show();closeDescriptor();}
    }
    private void choose(VideoStore.Item item){
        if(video!=null&&video.isPlaying())pauseVideo();long saved=VideoProgressStore.read(this,item.uri,item.duration);
        if(saved<=0){open(item,false);return;}if(resumeDialog!=null)resumeDialog.dismiss();
        resumeDialog=new AlertDialog.Builder(this).setTitle("Continuar vídeo?").setMessage(item.title+"\nContinuar de "+VideoText.duration(saved)+"?")
            .setPositiveButton("Continuar",(d,w)->open(item,false,saved)).setNeutralButton("Recomeçar",(d,w)->{open(item,false);VideoProgressStore.clear(this,item.uri);}).setNegativeButton("Cancelar",null).show();
    }
    private void remember(){if(video!=null&&current!=null&&video.getLength()>0)VideoProgressStore.save(this,current.uri,Math.max(0,video.getTime()),video.getLength());}
    private void applyPendingSeek(){if(pendingSeek>0&&video!=null&&video.isSeekable()&&video.getLength()>0){long target=Math.min(pendingSeek,Math.max(0,video.getLength()-500));pendingSeek=0;if(target>0){video.setTime(target);android.util.Log.d("OndaVideo","resumed "+target);}}}
    private void applyVideoVolume(){if(video!=null)video.setVolume(ducked?Math.round(videoVolume*.25f):videoVolume);}
    private void clearSubtitle(){captionsOff=false;subtitleEnabled=false;subtitleAttached=false;subtitleName="";if(subtitleFile!=null){subtitleFile.delete();subtitleFile=null;}}
    private void attachSubtitle(){if(video!=null&&captionsOff){video.setSpuTrack(-1);return;}if(video==null||!subtitleEnabled||subtitleAttached||subtitleFile==null)return;
        subtitleAttached=video.addSlave(Media.Slave.Type.Subtitle,subtitleFile.toURI().toString(),true);
        android.util.Log.d("OndaVideo","subtitle "+(subtitleAttached?"attached ":"failed ")+subtitleName);
        if(!subtitleAttached)Toast.makeText(this,"Não foi possível ativar a legenda. Tente outro arquivo.",Toast.LENGTH_LONG).show();
    }
    private void subtitles(){if(current==null){Toast.makeText(this,"Abra um vídeo primeiro.",Toast.LENGTH_SHORT).show();return;}
        new AlertDialog.Builder(this).setTitle("Legendas do vídeo").setMessage((subtitleEnabled?"Arquivo: "+subtitleName:"Nenhuma legenda externa ativa")+"\nSRT, VTT, ASS e SSA, até 2 MB. A legenda fica disponível nesta sessão do vídeo.")
            .setPositiveButton("Abrir legenda",(d,w)->{subtitleWasPlaying=video!=null&&video.isPlaying();Intent intent=new Intent(Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType("*/*").putExtra(android.provider.DocumentsContract.EXTRA_INITIAL_URI,android.provider.DocumentsContract.buildDocumentUri("com.android.externalstorage.documents","primary:Download"));try{startActivityForResult(intent,SUBTITLE);}catch(ActivityNotFoundException e){Toast.makeText(this,"Seletor de arquivos indisponível.",Toast.LENGTH_LONG).show();}})
            .setNeutralButton("Desativar",(d,w)->{if(video!=null)video.setSpuTrack(-1);captionsOff=true;subtitleEnabled=false;Toast.makeText(this,"Legenda desativada",Toast.LENGTH_SHORT).show();}).setNegativeButton("Fechar",null).show();
    }
    private void loadSubtitle(Uri uri){if(current==null)return;Uri owner=current.uri;String name=selected(uri).file;String lower=name.toLowerCase(Locale.ROOT);String suffix=null;for(String ext:new String[]{".srt",".vtt",".ass",".ssa"})if(lower.endsWith(ext)){suffix=ext;break;}
        if(suffix==null){Toast.makeText(this,"Escolha uma legenda SRT, VTT, ASS ou SSA.",Toast.LENGTH_LONG).show();return;}
        int request=++subtitleGeneration;String extension=suffix;status.setText("Carregando legenda…");
        scanner.execute(()->{java.io.File copy=null;try{copy=java.io.File.createTempFile("onda-sub-",extension,getCacheDir());try(java.io.InputStream in=getContentResolver().openInputStream(uri);java.io.OutputStream out=new java.io.FileOutputStream(copy)){if(in==null)throw new java.io.IOException();byte[] bytes=new byte[8192];int n,total=0;while((n=in.read(bytes))!=-1){if(Thread.currentThread().isInterrupted()||(total+=n)>2*1024*1024)throw new java.io.IOException();out.write(bytes,0,n);}}java.io.File ready=copy;
            runOnUiThread(()->{if(isDestroyed()||request!=subtitleGeneration||current==null||!owner.equals(current.uri)){ready.delete();return;}clearSubtitle();subtitleFile=ready;subtitleName=name;subtitleEnabled=true;if(video.isPlaying())attachSubtitle();else if(subtitleWasPlaying&&started)resumeVideo();Toast.makeText(this,"Legenda carregada",Toast.LENGTH_SHORT).show();});
        }catch(Exception e){if(copy!=null)copy.delete();runOnUiThread(()->{if(!isDestroyed()&&request==subtitleGeneration)Toast.makeText(this,"Não foi possível ler a legenda. Verifique o arquivo e o limite de 2 MB.",Toast.LENGTH_LONG).show();});}});
    }
    private void gestureHelp(){new AlertDialog.Builder(this).setTitle("Gestos e posição").setMessage("Na área do vídeo, deslize para cima ou para baixo:\n\nEsquerda: brilho apenas desta tela.\nDireita: volume apenas do vídeo no Onda.\n\nA posição é salva ao pausar, trocar de vídeo ou sair. Ao abrir novamente, escolha Continuar ou Recomeçar. Vídeos terminados voltam ao início. O botão CC abre legendas externas.").setPositiveButton("Entendi",null).setNeutralButton("Restaurar ajustes",(d,w)->{WindowManager.LayoutParams a=getWindow().getAttributes();a.screenBrightness=-1;getWindow().setAttributes(a);videoVolume=100;applyVideoVolume();getSharedPreferences("video_controls",0).edit().putInt("volume",100).apply();}).show();}
    private void setupGestures(){gestureLayer.setOnClickListener(v->{if(current!=null)showGesture("Esquerda: brilho • Direita: volume");});gestureLayer.setOnTouchListener(new View.OnTouchListener(){float x,y,startBrightness;int startVolume;boolean changed,left;
        public boolean onTouch(View v,MotionEvent e){if(current==null||video==null)return false;switch(e.getActionMasked()){
            case MotionEvent.ACTION_DOWN:x=e.getX();y=e.getY();changed=false;left=x<v.getWidth()/2f;startVolume=videoVolume;startBrightness=getWindow().getAttributes().screenBrightness;if(startBrightness<0)try{startBrightness=android.provider.Settings.System.getInt(getContentResolver(),android.provider.Settings.System.SCREEN_BRIGHTNESS)/255f;}catch(Exception ex){startBrightness=.5f;}return true;
            case MotionEvent.ACTION_MOVE:float delta=y-e.getY();if(!changed&&(Math.abs(delta)<Ui.dp(VideoActivity.this,12)||Math.abs(delta)<Math.abs(x-e.getX())))return true;changed=true;float fraction=delta/Math.max(1,v.getHeight());if(left){WindowManager.LayoutParams attributes=getWindow().getAttributes();attributes.screenBrightness=VideoProgress.brightness(startBrightness,fraction);getWindow().setAttributes(attributes);showGesture("Brilho "+Math.round(attributes.screenBrightness*100)+"%");}else{videoVolume=VideoProgress.volume(startVolume,fraction);applyVideoVolume();showGesture("Volume "+videoVolume+"%");}return true;
            case MotionEvent.ACTION_UP:case MotionEvent.ACTION_CANCEL:if(changed){getSharedPreferences("video_controls",0).edit().putInt("volume",videoVolume).apply();android.util.Log.d("OndaVideo","gesture "+(left?"brightness "+getWindow().getAttributes().screenBrightness:"volume "+videoVolume));}else if(e.getActionMasked()==MotionEvent.ACTION_UP)v.performClick();return true;
            default:return true;
        }} });}
    private void showGesture(String text){gestureFeedback.setText(text);gestureFeedback.setVisibility(View.VISIBLE);handler.removeCallbacks(hideGesture);handler.postDelayed(hideGesture,1200);}
    private boolean requestFocus(){if(audio==null||focus==null)return false;hasFocus=audio.requestAudioFocus(focus)==AudioManager.AUDIOFOCUS_REQUEST_GRANTED;if(hasFocus){ducked=false;applyVideoVolume();}if(!hasFocus)Toast.makeText(this,"Áudio ocupado. Tente novamente.",Toast.LENGTH_SHORT).show();return hasFocus;}
    private void abandonFocus(){if(audio!=null&&focus!=null)audio.abandonAudioFocusRequest(focus);hasFocus=false;}
    private void resumeVideo(){if(video==null||current==null||!started||music==null)return;long at=Math.max(0,video.getTime()),length=video.getLength();open(current,software,length>0&&at>=length-500?0:at);}
    private void pauseVideo(){remember();if(video!=null){video.pause();android.util.Log.d("OndaVideo","paused at "+Math.max(0,video.getTime()));}handler.removeCallbacks(tick);getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);abandonFocus();update();if(adapter!=null)adapter.notifyDataSetChanged();}
    private void update(){if(video==null)return;boolean playing=video.isPlaying();play.setText(playing?"Pausar":"Reproduzir");play.setContentDescription(playing?"Pausar vídeo":"Reproduzir vídeo");long length=Math.max(0,video.getLength()),time=Math.max(0,video.getTime());if(!seeking)seek.setProgress(length>0?(int)Math.min(1000,time*1000/length):0);seek.setEnabled(video.isSeekable());position.setText(VideoText.duration(time)+" / "+VideoText.duration(length));if(started&&playing)getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);else getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);}
    private void restartTick(){handler.removeCallbacks(tick);if(started)handler.post(tick);}
    private void setFullscreen(boolean value){fullscreen=value;heading.setVisibility(value?View.GONE:View.VISIBLE);now.setVisibility(value?View.GONE:View.VISIBLE);browser.setVisibility(value?View.GONE:View.VISIBLE);navigation.setVisibility(value?View.GONE:View.VISIBLE);surfaceBox.setLayoutParams(value?new LinearLayout.LayoutParams(-1,0,1):new LinearLayout.LayoutParams(-1,Ui.dp(this,205)));full.setText(value?"Sair da tela":"Tela cheia");full.setContentDescription(value?"Sair da tela cheia":"Tela cheia do vídeo");getWindow().getDecorView().setSystemUiVisibility(value?View.SYSTEM_UI_FLAG_FULLSCREEN|View.SYSTEM_UI_FLAG_HIDE_NAVIGATION|View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY|View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN|View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION|View.SYSTEM_UI_FLAG_LAYOUT_STABLE:View.SYSTEM_UI_FLAG_LAYOUT_STABLE);setRequestedOrientation(value?ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE:ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED);root.requestApplyInsets();}
    @Override public void onBackPressed(){if(fullscreen)setFullscreen(false);else super.onBackPressed();}
    private void about(){new AlertDialog.Builder(this).setTitle("Motor de vídeo LibVLC").setMessage("Suporte amplo a MP4, MKV, AVI, MOV, WebM, FLV, WMV, MPEG, TS e outros contêineres. A compatibilidade depende dos codecs, do aparelho e do arquivo. Conteúdo com DRM não é suportado.\n\nLibVLC 3.7.7 © VideoLAN e colaboradores, LGPL 2.1 ou posterior. Bibliotecas nativas sem modificações; fonte e instruções de compilação em code.videolan.org/videolan/libvlcjni. O APK inclui a licença em assets/libvlc-license.txt.\n\nO vídeo pausa ao sair da tela para economizar bateria.").setPositiveButton("OK",null).setNeutralButton("Licença",(d,w)->showLicense()).show();}
    private void showLicense(){try(java.io.InputStream input=getAssets().open("libvlc-license.txt")){java.io.ByteArrayOutputStream out=new java.io.ByteArrayOutputStream();byte[] buf=new byte[4096];int n;while((n=input.read(buf))!=-1)out.write(buf,0,n);TextView text=Ui.text(this,out.toString("UTF-8"),12,Ui.TEXT);text.setPadding(24,24,24,24);ScrollView scroll=new ScrollView(this);scroll.addView(text);new AlertDialog.Builder(this).setTitle("LibVLC • LGPL 2.1").setView(scroll).setPositiveButton("Fechar",null).show();}catch(Exception e){Toast.makeText(this,"Licença indisponível.",Toast.LENGTH_SHORT).show();}}
    private void closeDescriptor(){if(descriptor!=null){try{descriptor.close();}catch(java.io.IOException ignored){}descriptor=null;}}
    @Override protected void onStart(){super.onStart();started=true;update();openPending();}
    @Override protected void onResume(){super.onResume();if(search!=null&&allowed())scan();}
    @Override protected void onStop(){started=false;pending=null;pauseVideo();super.onStop();}
    @Override public void onDestroy(){subtitleGeneration++;if(resumeDialog!=null)resumeDialog.dismiss();clearSubtitle();handler.removeCallbacksAndMessages(null);scanner.shutdownNow();if(receiverRegistered)unregisterReceiver(noisy);abandonFocus();if(video!=null){video.setEventListener(null);video.stop();video.detachViews();video.release();}closeDescriptor();if(engine!=null)engine.release();if(connection!=null)MediaController.releaseFuture(connection);super.onDestroy();}
}
