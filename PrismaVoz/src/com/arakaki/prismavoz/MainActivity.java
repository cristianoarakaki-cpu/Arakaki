package com.arakaki.prismavoz;

import android.app.*;
import android.content.*;
import android.database.Cursor;
import android.graphics.*;
import android.graphics.drawable.GradientDrawable;
import android.net.*;
import android.os.*;
import android.provider.OpenableColumns;
import android.view.*;
import android.widget.*;
import org.json.*;
import java.io.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

/** Android views, system PDF rendering and native OCR. No WebView or browser. */
public final class MainActivity extends Activity {
    static final int OPEN_ID=1001,PLAY_ID=1002,VOICE_ID=1003,STATUS_ID=1005,PREVIEW_ID=1006,STOP_ID=1007;
    private final ExecutorService worker=Executors.newSingleThreadExecutor();
    private final Handler main=new Handler(Looper.getMainLooper());
    private final AtomicInteger generation=new AtomicInteger();
    private NativePdf document;
    private SpeechCatalog catalog;
    private UpdateManager updater;
    private TextView status,title,counter;
    private Spinner voice,rate,pitch;
    private EditText from,to,jump;
    private CheckBox sensitive,force,network;
    private Button play,pause,stop,previous,next;
    private ImageView preview;
    private Bitmap shownBitmap;
    private final List<JSONObject> voices=new ArrayList<>();
    private boolean busy,paused,foreground=true;
    private String session="",name="documento.pdf",lastCatalog="";
    private int page;
    private static final int INK=0xff172554,BLUE=0xff284bd5;
    private int dp(int value){return Math.round(value*getResources().getDisplayMetrics().density);}
    private LinearLayout column(){LinearLayout layout=new LinearLayout(this);layout.setOrientation(LinearLayout.VERTICAL);return layout;}
    private TextView text(String value,int size){TextView t=new TextView(this);t.setText(value);t.setTextSize(size);t.setTextColor(INK);t.setPadding(0,dp(5),0,dp(5));return t;}
    private Button button(String value,Runnable action){Button b=new Button(this);b.setText(value);b.setAllCaps(false);b.setMinHeight(dp(48));b.setOnClickListener(v->action.run());return b;}
    private void row(LinearLayout parent,View...children){LinearLayout row=new LinearLayout(this);row.setOrientation(LinearLayout.HORIZONTAL);for(View child:children){LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(0,-2,1);p.setMargins(dp(3),dp(3),dp(3),dp(3));row.addView(child,p);}parent.addView(row);}
    private Spinner spinner(LinearLayout parent,String label,String[] values){parent.addView(text(label,14));Spinner s=new Spinner(this);s.setMinimumHeight(dp(48));s.setAdapter(new ArrayAdapter<>(this,android.R.layout.simple_spinner_dropdown_item,values));parent.addView(s,new LinearLayout.LayoutParams(-1,-2));return s;}
    private EditText number(LinearLayout parent,String label){parent.addView(text(label,14));EditText e=new EditText(this);e.setInputType(android.text.InputType.TYPE_CLASS_NUMBER);e.setText("1");e.setSingleLine(true);e.setMinHeight(dp(48));parent.addView(e);return e;}
    @Override public void onCreate(Bundle saved){
        super.onCreate(saved);getWindow().setStatusBarColor(INK);getWindow().setNavigationBarColor(0xfff4f6fb);
        ScrollView scroll=new ScrollView(this);scroll.setFillViewport(true);LinearLayout root=column();root.setPadding(dp(18),dp(20),dp(18),dp(24));root.setBackgroundColor(0xfff4f6fb);scroll.addView(root);setContentView(scroll);
        if(Build.VERSION.SDK_INT>=35)scroll.setOnApplyWindowInsetsListener((v,i)->{android.graphics.Insets x=i.getInsets(WindowInsets.Type.systemBars()|WindowInsets.Type.displayCutout());v.setPadding(x.left,x.top,x.right,x.bottom);return i;});
        TextView heading=text("Prisma Voz",28);heading.setTypeface(null,Typeface.BOLD);root.addView(heading);root.addView(text("Leitor Android nativo · PDF em voz alta",14));
        Button open=button("Abrir PDF",this::choosePdf);open.setId(OPEN_ID);root.addView(open);
        title=text("Escolha um PDF de até 25 MB.",18);root.addView(title);
        voice=spinner(root,"Voz do Android",new String[]{"Carregando vozes…"});voice.setId(VOICE_ID);
        root.addView(button("Configurar vozes",()->{try{startActivity(new Intent("com.android.settings.TTS_SETTINGS"));}catch(Exception e){notice("Abra as configurações de texto para fala do Android.");}}));
        network=new CheckBox(this);network.setText("Mostrar vozes online (podem enviar texto ao serviço de voz)");root.addView(network);network.setOnCheckedChangeListener((b,v)->refreshVoices());
        rate=spinner(root,"Velocidade",new String[]{"0,5×","0,75×","1× · Normal","1,25×","1,5×","2×"});rate.setSelection(Math.min(5,Math.max(0,getPreferences(0).getInt("nativeRate",2))));
        pitch=spinner(root,"Tom",new String[]{"Mais grave","Natural","Mais agudo"});pitch.setSelection(Math.min(2,Math.max(0,getPreferences(0).getInt("nativePitch",1))));
        LinearLayout a=column(),b=column();from=number(a,"Da página");to=number(b,"Até a página");row(root,a,b);
        sensitive=new CheckBox(this);sensitive.setText("OCR mais sensível (mais lento)");sensitive.setChecked(true);root.addView(sensitive);
        force=new CheckBox(this);force.setText("Refazer texto com OCR em todas as páginas");root.addView(force);
        root.addView(text("O OCR é feito no aparelho. Em versões antigas do Android, ele também é usado para obter o texto de PDFs comuns.",12));
        play=button("Ler em voz alta",this::read);play.setId(PLAY_ID);root.addView(play);
        pause=button("Pausar",this::pauseOrResume);stop=button("Parar",this::stopReading);stop.setId(STOP_ID);row(root,pause,stop);
        status=text("Abra um documento para começar.",14);status.setId(STATUS_ID);status.setAccessibilityLiveRegion(View.ACCESSIBILITY_LIVE_REGION_POLITE);root.addView(status);
        previous=button("← Anterior",()->showPage(page-1));next=button("Próxima →",()->showPage(page+1));row(root,previous,next);counter=text("Nenhum PDF aberto",14);counter.setGravity(Gravity.CENTER);root.addView(counter);
        jump=number(root,"Ir para página");root.addView(button("Ir",()->{try{showPage(Integer.parseInt(jump.getText().toString())-1);}catch(Exception e){notice("Informe uma página válida.");}}));
        preview=new ImageView(this);preview.setId(PREVIEW_ID);preview.setAdjustViewBounds(true);preview.setScaleType(ImageView.ScaleType.FIT_CENTER);preview.setContentDescription("Prévia da página do PDF");root.addView(preview,new LinearLayout.LayoutParams(-1,-2));
        root.addView(button("Conexão e atualizações",this::settings));root.addView(text("Prisma Voz "+appVersion()+" · Sem navegador\nLeitura com a tela apagada depende da voz e das regras de bateria do aparelho.",12));
        worker.execute(()->{File directory=new File(getCacheDir(),"native-reading");File[] old=directory.listFiles();if(old!=null)for(File file:old)if(file.isFile()&&file.getName().startsWith("reading-"))file.delete();});
        updater=new UpdateManager(this);catalog=new SpeechCatalog(this);main.post(tick);updateButtons();receive(getIntent());
    }
    private void choosePdf(){try{startActivityForResult(new Intent(Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType("application/pdf"),10);}catch(Exception e){notice("Nenhum seletor de documentos disponível.");}}
    void openPdf(Uri uri){
        if(uri==null||!"content".equals(uri.getScheme())){notice("Use o seletor do Android para abrir o PDF.");return;}
        stopReading();int token=generation.incrementAndGet();busy=true;updateButtons();status.setText("Abrindo documento…");
        worker.execute(()->{try{
            NativePdf nextDoc=NativePdf.open(this,uri);String display="documento.pdf";
            try(Cursor c=getContentResolver().query(uri,new String[]{OpenableColumns.DISPLAY_NAME},null,null,null)){if(c!=null&&c.moveToFirst()&&!c.isNull(0))display=c.getString(0);}
            if(token!=generation.get()){nextDoc.close();return;}final String fileName=display;
            main.post(()->{if(token!=generation.get()||isDestroyed()){nextDoc.close();return;}NativePdf old=document;document=nextDoc;if(old!=null)worker.execute(old::close);name=fileName;title.setText(name);page=0;from.setText("1");to.setText(String.valueOf(nextDoc.pages));busy=false;status.setText("Documento aberto. Escolha uma voz e toque em Ler.");showPage(0);updateButtons();});
        }catch(Exception e){main.post(()->{if(token==generation.get()&&!isDestroyed()){busy=false;notice(e.getMessage());updateButtons();}});}});
    }
    private void showPage(int number){
        NativePdf doc=document;if(doc==null)return;if(number<0||number>=doc.pages){notice("Informe uma página entre 1 e "+doc.pages+".");return;}if(busy)return;
        page=number;int token=generation.get();counter.setText("Página "+(number+1)+" / "+doc.pages);jump.setText(String.valueOf(number+1));updateButtons();
        worker.execute(()->{try{Bitmap image=doc.preview(number);main.post(()->{if(isDestroyed()||token!=generation.get()||page!=number){image.recycle();return;}Bitmap old=shownBitmap;shownBitmap=image;preview.setImageBitmap(image);if(old!=null&&!old.isRecycled())old.recycle();});}catch(Exception e){main.post(()->{if(token==generation.get())notice(e.getMessage());});}});
    }
    private void read(){
        NativePdf doc=document;if(doc==null||busy)return;if(voice.getSelectedItemPosition()<0||voice.getSelectedItemPosition()>=voices.size()){notice("Escolha uma voz instalada no Android.");return;}
        JSONObject choice=voices.get(voice.getSelectedItemPosition());boolean onlineVoice=choice.optBoolean("network");
        if(onlineVoice&&(!network.isChecked()||!online())){notice("Esta voz exige autorização de ações online. Você também pode escolher uma voz offline.");return;}
        int first,last;try{first=Integer.parseInt(from.getText().toString());last=Integer.parseInt(to.getText().toString());if(first<1||last<first||last>doc.pages)throw new IllegalArgumentException();}catch(Exception e){notice("Informe um intervalo válido entre 1 e "+doc.pages+".");return;}
        stopReading();final int token=generation.incrementAndGet(),start=first,end=last;final boolean high=sensitive.isChecked(),always=force.isChecked();final String selected=choice.optString("id");final float speed=new float[]{.5f,.75f,1,1.25f,1.5f,2}[rate.getSelectedItemPosition()],tone=new float[]{.75f,1,1.25f}[pitch.getSelectedItemPosition()];
        getPreferences(0).edit().putString("nativeVoice",selected).putInt("nativeRate",rate.getSelectedItemPosition()).putInt("nativePitch",pitch.getSelectedItemPosition()).apply();busy=true;updateButtons();
        worker.execute(()->{try{JSONArray parts=new JSONArray();int count=0,empty=0;
            for(int n=start;n<=end;n++){if(token!=generation.get())return;final int reading=n;main.post(()->{if(token==generation.get())status.setText("Preparando página "+reading+" de "+end+"…");});String text=doc.text(n-1,always,high,()->token==generation.get());count+=text.length();if(count>500000)throw new IOException("Há muito texto neste intervalo. Selecione menos páginas.");if(text.isEmpty())empty++;for(String part:NativeSpeechText.chunks(text))parts.put(new JSONObject().put("page",n).put("text",part));}
            if(parts.length()==0)throw new IOException("Não foi possível reconhecer texto. Tente OCR mais sensível e confira a qualidade do PDF.");if(token!=generation.get())return;
            String id=System.currentTimeMillis()+"-"+token;JSONObject data=new JSONObject().put("session",id).put("name",name).put("voice",selected).put("allowNetwork",onlineVoice).put("rate",speed).put("pitch",tone).put("segments",parts);
            File input=new File(getCacheDir(),"speech-input.json");try(OutputStream output=new FileOutputStream(input)){output.write(data.toString().getBytes("UTF-8"));}
            final int skipped=empty;main.post(()->{if(token!=generation.get()||isDestroyed()){input.delete();return;}busy=false;session=id;if(Build.VERSION.SDK_INT>=33&&checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS)!=android.content.pm.PackageManager.PERMISSION_GRANTED)requestPermissions(new String[]{android.Manifest.permission.POST_NOTIFICATIONS},41);try{startForegroundService(new Intent(this,SpeechService.class).setAction(SpeechService.START));status.setText("Iniciando leitura."+(skipped>0?" "+skipped+" página(s) sem texto foram ignoradas.":""));}catch(Exception e){input.delete();session="";notice("Não foi possível iniciar a voz. Mantenha o app aberto e tente novamente.");}updateButtons();});
        }catch(Exception e){main.post(()->{if(token==generation.get()&&!isDestroyed()){busy=false;notice(e instanceof TimeoutException?"O OCR demorou demais. Selecione menos páginas e tente novamente.":e.getMessage());updateButtons();}});}});
    }
    private void pauseOrResume(){if(session.isEmpty())return;try{startService(new Intent(this,SpeechService.class).setAction(paused?SpeechService.RESUME:SpeechService.PAUSE));}catch(Exception e){notice("Não foi possível controlar a leitura.");}}
    private void stopReading(){generation.incrementAndGet();busy=false;session="";paused=false;stopService(new Intent(this,SpeechService.class));if(status!=null)status.setText("Leitura parada.");if(play!=null)updateButtons();}
    private void updateButtons(){boolean active=!session.isEmpty(),locked=busy||active;play.setEnabled(document!=null&&!locked&&!voices.isEmpty());pause.setEnabled(active&&!busy);pause.setText(paused?"Continuar":"Pausar");stop.setEnabled(busy||active);for(View v:new View[]{voice,network,rate,pitch,from,to,sensitive,force})v.setEnabled(!locked);previous.setEnabled(document!=null&&page>0&&!busy);next.setEnabled(document!=null&&page<document.pages-1&&!busy);}
    private void refreshVoices(){
        if(catalog==null)return;try{JSONObject state=new JSONObject(catalog.state());if(!state.optBoolean("ready"))return;String keep=getPreferences(0).getString("nativeVoice","");if(voice.getSelectedItemPosition()>=0&&voice.getSelectedItemPosition()<voices.size())keep=voices.get(voice.getSelectedItemPosition()).optString("id");voices.clear();JSONArray data=state.optJSONArray("voices");if(data!=null)for(int i=0;i<data.length();i++){JSONObject v=data.getJSONObject(i);if(!v.optBoolean("network")||network.isChecked())voices.add(v);}Collections.sort(voices,(a,b)->{boolean pa=a.optString("language").startsWith("pt"),pb=b.optString("language").startsWith("pt");return pa==pb?a.optString("label").compareTo(b.optString("label")):pa?-1:1;});List<String> labels=new ArrayList<>();int selected=0;for(int i=0;i<voices.size();i++){JSONObject v=voices.get(i);labels.add(v.optString("label")+(v.optBoolean("network")?" · Online":" · Offline"));if(keep.equals(v.optString("id")))selected=i;}if(labels.isEmpty())labels.add("Nenhuma voz instalada. Use Configurar vozes.");voice.setAdapter(new ArrayAdapter<>(this,android.R.layout.simple_spinner_dropdown_item,labels));voice.setSelection(selected);updateButtons();}catch(Exception e){notice("Não foi possível listar as vozes do Android.");}
    }
    private final Runnable tick=new Runnable(){public void run(){if(isDestroyed())return;if(foreground){if(catalog!=null&&!catalog.state().equals(lastCatalog)){lastCatalog=catalog.state();refreshVoices();}if(!session.isEmpty())try{JSONObject s=new JSONObject(SpeechService.state());if(session.equals(s.optString("session"))){String value=s.optString("status");paused="paused".equals(value);if("playing".equals(value))status.setText("Lendo a página "+s.optInt("page")+".");else if(paused)status.setText("Leitura pausada. Toque em Continuar.");else if(Arrays.asList("error","completed","stopped").contains(value)){session="";status.setText("completed".equals(value)?"Leitura concluída.":s.optString("message","").isEmpty()?"Leitura parada.":s.optString("message"));}updateButtons();}}catch(Exception ignored){}}main.postDelayed(this,700);}};
    private String appVersion(){try{return getPackageManager().getPackageInfo(getPackageName(),0).versionName;}catch(Exception e){return "";}}
    boolean online(){return getPreferences(0).getBoolean("online",false);}
    boolean connected(){ConnectivityManager c=(ConnectivityManager)getSystemService(CONNECTIVITY_SERVICE);Network n=c.getActiveNetwork();NetworkCapabilities caps=c.getNetworkCapabilities(n);return caps!=null&&caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET);}
    void notice(String message){if(message==null)message="Não foi possível concluir a operação.";final String value=message;runOnUiThread(()->{if(!isDestroyed()){if(status!=null)status.setText(value);Toast.makeText(this,value,Toast.LENGTH_LONG).show();}});}
    private void settings(){LinearLayout panel=column();panel.setPadding(dp(18),dp(8),dp(18),dp(8));CheckBox allowed=new CheckBox(this);allowed.setText("Permitir atualizações e vozes online");allowed.setChecked(online());panel.addView(allowed);allowed.setOnCheckedChangeListener((b,value)->{getPreferences(0).edit().putBoolean("online",value).apply();if(!value)SpeechService.stopIfNetwork(this);});panel.addView(text("A verificação automática ocorre uma vez ao dia ao abrir. Download e instalação pedem confirmação do Android.",13));panel.addView(button("Verificar atualização",()->updater.check()));panel.addView(text("Os documentos são lidos no aparelho. O OCR inclui o modelo latino ML Kit; bibliotecas de terceiros podem coletar dados técnicos de diagnóstico. Vozes online podem enviar o texto ao fornecedor da voz. A cópia temporária do PDF fica no cache privado e é removida ao fechar o documento.",12));new AlertDialog.Builder(this).setTitle("Conexão e atualizações").setView(panel).setPositiveButton("Fechar",null).show();}
    private void receive(Intent intent){Uri source=intent!=null&&Intent.ACTION_VIEW.equals(intent.getAction())?intent.getData():intent!=null&&Intent.ACTION_SEND.equals(intent.getAction())?intent.getParcelableExtra(Intent.EXTRA_STREAM):null;if(source!=null)openPdf(source);}
    static byte[] readLimited(InputStream input,int max)throws IOException{try(InputStream in=input;ByteArrayOutputStream out=new ByteArrayOutputStream()){if(in==null)throw new IOException("Arquivo indisponível.");byte[] buffer=new byte[32768];int n;while((n=in.read(buffer))!=-1){if(out.size()+n>max)throw new IOException("Arquivo maior que o limite.");out.write(buffer,0,n);}return out.toByteArray();}}
    @Override protected void onResume(){super.onResume();foreground=true;if(catalog!=null){catalog.close();catalog=new SpeechCatalog(this);lastCatalog="";}if(updater!=null)updater.checkAutomatic();if(session.isEmpty()&&!busy)try{JSONObject state=new JSONObject(SpeechService.state());if(Arrays.asList("playing","paused","preparing").contains(state.optString("status"))){session=state.optString("session");paused="paused".equals(state.optString("status"));updateButtons();}}catch(Exception ignored){}}
    @Override protected void onPause(){foreground=false;super.onPause();}
    @Override protected void onNewIntent(Intent intent){super.onNewIntent(intent);if(Intent.ACTION_VIEW.equals(intent.getAction())||Intent.ACTION_SEND.equals(intent.getAction()))new AlertDialog.Builder(this).setTitle("Abrir outro PDF?").setMessage("A leitura atual será interrompida.").setPositiveButton("Abrir",(d,w)->receive(intent)).setNegativeButton("Cancelar",null).show();}
    @Override protected void onActivityResult(int request,int result,Intent data){super.onActivityResult(request,result,data);if(request==10&&result==RESULT_OK&&data!=null)openPdf(data.getData());if(request==12)updater.install();}
    @Override public void onBackPressed(){new AlertDialog.Builder(this).setTitle("Sair do Prisma Voz?").setMessage("A leitura iniciada pode continuar pela notificação.").setPositiveButton("Sair",(d,w)->finish()).setNegativeButton("Ficar",null).show();}
    @Override protected void onDestroy(){generation.incrementAndGet();main.removeCallbacks(tick);if(catalog!=null)catalog.close();preview.setImageDrawable(null);if(shownBitmap!=null)shownBitmap.recycle();worker.execute(()->{if(document!=null){document.close();document=null;}});worker.shutdown();super.onDestroy();}
}
