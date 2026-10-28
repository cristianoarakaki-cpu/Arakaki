package br.com.onda;
import android.app.AlertDialog;
import android.content.Context;
import android.widget.Toast;
import androidx.media3.common.*;
@androidx.media3.common.util.UnstableApi
final class AudioPlaybackOptions {
 static final float[] SPEEDS={.5f,.75f,1f,1.25f,1.5f,1.75f,2f};static final String[] LABELS={"0,5×","0,75×","1× • normal","1,25×","1,5×","1,75×","2×"};
 static int saved(Context c){return Math.max(0,Math.min(SPEEDS.length-1,c.getSharedPreferences("playback_tools",0).getInt("speed",2)));}
 static void apply(Context c,Player player,int index){int value=Math.max(0,Math.min(SPEEDS.length-1,index));player.setPlaybackParameters(new PlaybackParameters(SPEEDS[value],1f));c.getSharedPreferences("playback_tools",0).edit().putInt("speed",value).apply();}
 static void seek(Player player,long delta){if(player==null||player.getCurrentMediaItem()==null||!player.isCurrentMediaItemSeekable())return;long target=Math.max(0,player.getCurrentPosition()+delta),duration=player.getDuration();if(duration>0)target=Math.min(target,Math.max(0,duration-1));player.seekTo(target);}
 static void show(Context c,Player player){if(player==null){Toast.makeText(c,"O tocador ainda está iniciando",Toast.LENGTH_SHORT).show();return;}new AlertDialog.Builder(c).setTitle("Controles de áudio").setItems(new String[]{"Velocidade de áudio","Voltar 10 segundos","Avançar 30 segundos"},(d,n)->{if(n==0)new AlertDialog.Builder(c).setTitle("Velocidade de áudio").setSingleChoiceItems(LABELS,saved(c),(dialog,index)->{apply(c,player,index);dialog.dismiss();}).setNegativeButton("Fechar",null).show();else if(player.getCurrentMediaItem()==null)Toast.makeText(c,"Escolha um áudio primeiro",Toast.LENGTH_SHORT).show();else seek(player,n==1?-10000:30000);}).setNegativeButton("Fechar",null).show();}
}
