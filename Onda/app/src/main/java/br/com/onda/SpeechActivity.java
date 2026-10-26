package br.com.onda;
import android.app.*;
import android.content.*;
import android.os.*;
import android.view.*;
import android.widget.*;
import androidx.media3.common.Player;
import androidx.media3.session.*;
import androidx.media3.session.MediaController;
import com.google.common.util.concurrent.ListenableFuture;

@androidx.media3.common.util.UnstableApi
public class SpeechActivity extends Activity {
 private Switch voice,silence;private TextView status;private boolean rendering,started;private int generation;
 private MediaController player;private ListenableFuture<MediaController> connection;private final Handler handler=new Handler(Looper.getMainLooper());
 private final Runnable verify=()->request(false);
 @Override public void onCreate(Bundle saved){super.onCreate(saved);LinearLayout root=column();Ui.background(root);root.setOnApplyWindowInsetsListener((v,i)->{root.setPadding(Ui.dp(this,16),Ui.dp(this,12)+i.getSystemWindowInsetTop(),Ui.dp(this,16),Ui.dp(this,12)+i.getSystemWindowInsetBottom());return i;});setContentView(root);
  LinearLayout header=new LinearLayout(this);header.setGravity(Gravity.CENTER_VERTICAL);Button back=Ui.button(this,"‹",v->finish());Ui.ghost(back);back.setContentDescription("Voltar de Aulas e podcasts");header.addView(back,new LinearLayout.LayoutParams(Ui.dp(this,48),Ui.dp(this,48)));TextView title=Ui.text(this,"Aulas e podcasts",22,Ui.TEXT);Ui.bold(title);header.addView(title,new LinearLayout.LayoutParams(0,-2,1));root.addView(header);
  ScrollView scroll=new ScrollView(this);LinearLayout body=column();scroll.addView(body);root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
  TextView intro=Ui.text(this,"Mais conforto para ouvir conteúdo falado. Recursos locais, sem serviço pago. Valem para músicas e áudio online do Onda; vídeos usam outro tocador.",14,Ui.MUTED);intro.setPadding(0,Ui.dp(this,16),0,Ui.dp(this,16));body.addView(intro);
  voice=toggle("Equilibrar e realçar a fala","Ativar equilíbrio de fala");body.addView(voice,new LinearLayout.LayoutParams(-1,-2));body.addView(description("Reduz a diferença entre trechos baixos e altos e dá presença à voz. Use em aulas, podcasts e audiolivros. O resultado depende da gravação."));
  silence=toggle("Pular silêncios","Ativar redução de silêncios");body.addView(silence,new LinearLayout.LayoutParams(-1,-2));body.addView(description("Encurta pausas silenciosas durante a reprodução. Use para fala: pausas intencionais de músicas também podem ser reduzidas. Os pontos de retomada continuam seguindo o tempo do arquivo original."));
  status=Ui.text(this,"Conectando ao tocador…",14,Ui.CYAN);status.setPadding(0,Ui.dp(this,16),0,Ui.dp(this,16));status.setContentDescription("Estado dos recursos de fala");body.addView(status);
  body.addView(Ui.button(this,"Verificar na reprodução",v->request(false)),new LinearLayout.LayoutParams(-1,-2));Button reset=Ui.button(this,"Desligar recursos de fala",v->{SpeechSettings.save(this,false,false);render();request(true);});reset.setContentDescription("Desligar recursos de fala");LinearLayout.LayoutParams params=new LinearLayout.LayoutParams(-1,-2);params.topMargin=Ui.dp(this,12);body.addView(reset,params);
  body.addView(description("As duas opções começam desligadas. Alterar um ajuste mantém a faixa e a posição e não inicia a reprodução. O processamento acompanha o áudio decodificado; compatibilidade depende do formato e da saída. A equalização do Estúdio de som continua disponível separadamente."));
  voice.setOnCheckedChangeListener((b,v)->save());silence.setOnCheckedChangeListener((b,v)->save());render();
  connection=new MediaController.Builder(this,new SessionToken(this,new ComponentName(this,PlaybackService.class))).buildAsync();connection.addListener(()->{if(isDestroyed())return;try{player=connection.get();player.addListener(new Player.Listener(){@Override public void onIsPlayingChanged(boolean value){request(false);schedule();}@Override public void onPlaybackStateChanged(int state){request(false);schedule();}});request(true);schedule();}catch(Exception e){status.setText("Configuração salva. Reabra esta tela para conectar ao tocador.");}},handler::post);
 }
 private LinearLayout column(){LinearLayout c=new LinearLayout(this);c.setOrientation(LinearLayout.VERTICAL);return c;}
 private Switch toggle(String label,String desc){Switch s=new Switch(this);s.setText(label);s.setTextColor(Ui.TEXT);s.setTextSize(17);s.setMinHeight(Ui.dp(this,56));s.setContentDescription(desc);return s;}
 private TextView description(String text){TextView t=Ui.text(this,text,13,Ui.MUTED);t.setPadding(0,Ui.dp(this,8),0,Ui.dp(this,20));return t;}
 private void render(){rendering=true;voice.setChecked(SpeechSettings.voice(this));silence.setChecked(SpeechSettings.silence(this));rendering=false;}
 private void save(){if(rendering)return;SpeechSettings.save(this,voice.isChecked(),silence.isChecked());request(true);schedule();}
 private void schedule(){handler.removeCallbacks(verify);if(started&&player!=null&&player.isPlaying())handler.postDelayed(verify,700);}
 private void request(boolean apply){if(!started&&!apply)return;if(player==null){status.setText("Configuração salva. Conectando ao tocador…");return;}int token=++generation;ListenableFuture<SessionResult> future=player.sendCustomCommand(new SessionCommand(apply?SpeechSettings.COMMAND:SpeechSettings.STATUS,Bundle.EMPTY),Bundle.EMPTY);future.addListener(()->{if(isDestroyed()||!started||token!=generation)return;try{SessionResult result=future.get();if(result.resultCode!=SessionResult.RESULT_SUCCESS){status.setText("Não foi possível consultar os recursos nesta sessão.");return;}Bundle b=result.extras;boolean active=b.getBoolean("voice"),skip=b.getBoolean("silence");String settings="Fala: "+(active?"ligada":"desligada")+" • silêncios: "+(skip?"reduzidos":"preservados");if(!active&&!skip)status.setText("Recursos de fala desligados");else if(!b.getBoolean("playing"))status.setText(settings+"\nConfiguração salva. Toque um áudio para aplicar.");else if(!b.getBoolean("compatible"))status.setText(settings+"\nAguardando áudio compatível no tocador.");else status.setText(settings+"\n"+(active&&b.getLong("frames")==0?"Preparando o processamento da fala…":"Aplicado à reprodução de áudio"));}catch(Exception e){status.setText("Configuração salva. Não foi possível verificar a aplicação agora.");}},handler::post);}
 @Override protected void onStart(){super.onStart();started=true;render();request(true);schedule();}
 @Override protected void onStop(){started=false;generation++;handler.removeCallbacks(verify);super.onStop();}
 @Override protected void onDestroy(){generation++;handler.removeCallbacksAndMessages(null);if(connection!=null)MediaController.releaseFuture(connection);super.onDestroy();}
}
