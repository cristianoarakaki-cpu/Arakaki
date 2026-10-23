package br.com.onda;
import android.app.*;
import android.content.*;
import androidx.media3.common.*;
import androidx.media3.session.MediaController;
import java.util.*;
@androidx.media3.common.util.UnstableApi
final class PlaylistVoice {
 private static int generation;
 static void cancel(){generation++;}
 static void play(Activity activity,MediaController player,String query){
  if(player==null){VoiceControl.say(activity,"O tocador está iniciando. Tente novamente.");return;}
  List<PlaylistStore.Entry> matches=PlaylistStore.matching(PlaylistStore.read(activity),query);
  if(matches.isEmpty()){VoiceControl.say(activity,"Nenhuma playlist com esse nome. Crie uma em Menu → Playlists.");return;}
  int request=++generation;
  new Thread(()->{try{List<MediaItem> found=LibraryStore.scan(activity.getApplicationContext());Map<String,MediaItem> items=new HashMap<>();for(MediaItem item:found)items.put(item.mediaId,item);
   activity.runOnUiThread(()->{if(activity.isDestroyed()||activity.isFinishing()||request!=generation||!player.isConnected())return;
    if(matches.size()==1)start(activity,player,matches.get(0),items);else{String[] names=new String[matches.size()];for(int i=0;i<names.length;i++)names[i]=matches.get(i).name;new AlertDialog.Builder(activity).setTitle("Qual playlist você quer ouvir?").setItems(names,(d,i)->{if(request==generation&&player.isConnected())start(activity,player,matches.get(i),items);}).setNegativeButton("Cancelar",null).show();}
   });
  }catch(Exception e){activity.runOnUiThread(()->{if(!activity.isDestroyed()&&request==generation)VoiceControl.say(activity,"Permita acesso às músicas na biblioteca e tente novamente.");});}},"onda-playlist-voice").start();
 }
 private static void start(Activity activity,MediaController player,PlaylistStore.Entry entry,Map<String,MediaItem> items){List<MediaItem> queue=new ArrayList<>();for(String id:entry.songs){MediaItem item=items.get(id);if(item!=null)queue.add(item);}if(queue.isEmpty()){VoiceControl.say(activity,"Essa playlist não tem músicas disponíveis no celular.");return;}player.setShuffleModeEnabled(false);player.setRepeatMode(Player.REPEAT_MODE_OFF);player.setMediaItems(queue);player.prepare();player.play();VoiceControl.say(activity,"Tocando playlist "+entry.name);if(!(activity instanceof MainActivity))activity.startActivity(new Intent(activity,MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP|Intent.FLAG_ACTIVITY_SINGLE_TOP));}
}
