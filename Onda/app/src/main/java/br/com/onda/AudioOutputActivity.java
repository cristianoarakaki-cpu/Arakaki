package br.com.onda;

import android.app.*;
import android.content.*;
import android.media.*;
import android.os.*;
import android.provider.Settings;
import android.view.*;
import android.widget.*;
import java.util.*;

/** Uses Android's media routing and pairing UI; no Bluetooth scan or communication/SCO route. */
@androidx.media3.common.util.UnstableApi
public class AudioOutputActivity extends Activity {
 private AudioManager audio;private MediaRouter router;private TextView selected,devices;private boolean observing;
 private final AudioDeviceCallback deviceEvents=new AudioDeviceCallback(){@Override public void onAudioDevicesAdded(AudioDeviceInfo[] info){refresh();}@Override public void onAudioDevicesRemoved(AudioDeviceInfo[] info){refresh();}};
 private final MediaRouter.Callback routes=new MediaRouter.SimpleCallback(){@Override public void onRouteSelected(MediaRouter r,int type,MediaRouter.RouteInfo route){refresh();}@Override public void onRouteChanged(MediaRouter r,MediaRouter.RouteInfo route){refresh();}@Override public void onRouteAdded(MediaRouter r,MediaRouter.RouteInfo route){refresh();}@Override public void onRouteRemoved(MediaRouter r,MediaRouter.RouteInfo route){refresh();}};
 @Override public void onCreate(Bundle state){super.onCreate(state);audio=(AudioManager)getSystemService(AUDIO_SERVICE);router=(MediaRouter)getSystemService(MEDIA_ROUTER_SERVICE);
  LinearLayout root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);Ui.background(root);root.setOnApplyWindowInsetsListener((v,i)->{root.setPadding(Ui.dp(this,20),Ui.dp(this,12)+i.getSystemWindowInsetTop(),Ui.dp(this,20),Ui.dp(this,12)+i.getSystemWindowInsetBottom());return i;});setContentView(root);
  LinearLayout header=new LinearLayout(this);header.setGravity(Gravity.CENTER_VERTICAL);Button back=Ui.button(this,"‹",v->finish());back.setContentDescription("Voltar dos fones");Ui.ghost(back);header.addView(back,new LinearLayout.LayoutParams(Ui.dp(this,48),Ui.dp(this,48)));TextView title=Ui.text(this,"Fones e Bluetooth",23,Ui.TEXT);Ui.bold(title);header.addView(title);root.addView(header);
  ScrollView scroll=new ScrollView(this);LinearLayout content=new LinearLayout(this);content.setOrientation(LinearLayout.VERTICAL);scroll.addView(content);root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
  selected=Ui.text(this,"",15,Ui.CYAN);selected.setContentDescription("Saída de áudio do Android");selected.setPadding(0,Ui.dp(this,20),0,Ui.dp(this,16));content.addView(selected);
  content.addView(Ui.text(this,"Conecte seu fone nas configurações do Android. Depois, use o seletor abaixo quando o sistema oferecer outras saídas de mídia.",14,Ui.MUTED));
  Button pair=Ui.button(this,"Conectar fone Bluetooth",v->openBluetooth());pair.setContentDescription("Conectar fone Bluetooth");Ui.primary(pair);LinearLayout.LayoutParams button=new LinearLayout.LayoutParams(-1,Ui.dp(this,52));button.topMargin=Ui.dp(this,16);content.addView(pair,button);
  LinearLayout routeRow=new LinearLayout(this);routeRow.setGravity(Gravity.CENTER_VERTICAL);Ui.card(routeRow,false);TextView choose=Ui.text(this,"Escolher saída de áudio",15,Ui.TEXT);choose.setPadding(Ui.dp(this,12),0,0,0);routeRow.addView(choose,new LinearLayout.LayoutParams(0,Ui.dp(this,56),1));MediaRouteButton routeButton=new MediaRouteButton(this);routeButton.setRouteTypes(MediaRouter.ROUTE_TYPE_LIVE_AUDIO);routeButton.setContentDescription("Escolher saída de áudio");routeRow.addView(routeButton,new LinearLayout.LayoutParams(Ui.dp(this,56),Ui.dp(this,56)));LinearLayout.LayoutParams rowParams=new LinearLayout.LayoutParams(-1,-2);rowParams.topMargin=Ui.dp(this,12);content.addView(routeRow,rowParams);
  Button sound=Ui.button(this,"Ajustar som para fones",v->startActivity(new Intent(this,SoundActivity.class)));sound.setContentDescription("Ajustar som para fones");LinearLayout.LayoutParams soundParams=new LinearLayout.LayoutParams(-1,Ui.dp(this,52));soundParams.topMargin=Ui.dp(this,20);content.addView(sound,soundParams);
  TextView explanation=Ui.text(this,"O seletor depende das saídas que o Android disponibiliza e pode ficar desabilitado. Para trocar entre dispositivos Bluetooth, use também as configurações do sistema. A lista abaixo mostra saídas disponíveis, não confirma qual delas está tocando.",12,Ui.MUTED);explanation.setPadding(0,Ui.dp(this,10),0,Ui.dp(this,16));content.addView(explanation);
  devices=Ui.text(this,"",14,Ui.TEXT);devices.setContentDescription("Saídas disponíveis no aparelho");content.addView(devices);

  TextView note=Ui.text(this,"No Estúdio de som: Fones equilibrados, Fones voz nítida e Alto-falante claro. Os ajustes são manuais e valem para músicas e áudio online; vídeos usam outro tocador. O resultado depende do fone e dos efeitos disponíveis no aparelho. O codec Bluetooth é negociado pelo Android e pelo fone.",12,Ui.MUTED);note.setPadding(0,Ui.dp(this,12),0,0);content.addView(note);refresh();
 }
 private void openBluetooth(){try{startActivity(new Intent(Settings.ACTION_BLUETOOTH_SETTINGS));}catch(ActivityNotFoundException e){try{startActivity(new Intent(Settings.ACTION_SETTINGS));}catch(ActivityNotFoundException ignored){Toast.makeText(this,"Abra as configurações de Bluetooth do celular.",Toast.LENGTH_LONG).show();}}}
 private static String type(int value){switch(value){case AudioDeviceInfo.TYPE_BUILTIN_SPEAKER:return "Alto-falante do celular";case AudioDeviceInfo.TYPE_BUILTIN_EARPIECE:return "Auricular do celular";case AudioDeviceInfo.TYPE_WIRED_HEADSET:case AudioDeviceInfo.TYPE_WIRED_HEADPHONES:return "Fone com fio";case AudioDeviceInfo.TYPE_BLUETOOTH_A2DP:return "Bluetooth • áudio de mídia";case AudioDeviceInfo.TYPE_BLUETOOTH_SCO:return "Bluetooth • chamadas";case AudioDeviceInfo.TYPE_USB_HEADSET:case AudioDeviceInfo.TYPE_USB_DEVICE:return "Áudio USB";case AudioDeviceInfo.TYPE_HDMI:return "Áudio HDMI";case 26:case 27:case 30:return "Bluetooth LE";default:return "Saída de áudio";}}
 private void refresh(){if(selected==null)return;try{MediaRouter.RouteInfo route=router==null?null:router.getSelectedRoute(MediaRouter.ROUTE_TYPE_LIVE_AUDIO);selected.setText("Rota informada pelo Android\n"+(route==null?"Indisponível":route.getName()));Set<String> names=new LinkedHashSet<>();if(audio!=null)for(AudioDeviceInfo d:audio.getDevices(AudioManager.GET_DEVICES_OUTPUTS)){String label=type(d.getType());CharSequence product=d.getProductName();if(product!=null&&!product.toString().trim().isEmpty())label+=" — "+product;names.add(label);}devices.setText("Saídas disponíveis\n\n"+(names.isEmpty()?"Nenhuma saída informada pelo Android.":android.text.TextUtils.join("\n\n",names)));}catch(RuntimeException e){selected.setText("Saída controlada pelo Android");devices.setText("Conecte o fone pelas configurações Bluetooth do celular.");}}
 @Override protected void onStart(){super.onStart();if(audio!=null)audio.registerAudioDeviceCallback(deviceEvents,new Handler(Looper.getMainLooper()));if(router!=null)router.addCallback(MediaRouter.ROUTE_TYPE_LIVE_AUDIO,routes);observing=true;refresh();}
 @Override protected void onStop(){if(observing){if(audio!=null)audio.unregisterAudioDeviceCallback(deviceEvents);if(router!=null)router.removeCallback(routes);observing=false;}super.onStop();}
}
