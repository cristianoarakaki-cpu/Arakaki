package br.com.onda;
import android.app.Activity;
import android.os.*;
import android.widget.Toast;
import androidx.media3.common.*;
import androidx.media3.session.*;
import com.google.common.util.concurrent.ListenableFuture;
import java.util.*;
@androidx.media3.common.util.UnstableApi
final class QueueEdit {
 static final String COMMAND="queue_edit";
 static List<MediaItem> snapshot(Player player){List<MediaItem> items=new ArrayList<>();for(int i=0;i<player.getMediaItemCount();i++)items.add(player.getMediaItemAt(i));return items;}
 static Bundle request(List<MediaItem> before,int current,int index,String action){Bundle b=new Bundle();ArrayList<String> ids=new ArrayList<>();for(MediaItem item:before)ids.add(item.mediaId);b.putStringArrayList("ids",ids);b.putInt("current",current);b.putInt("index",index);b.putString("action",action);return b;}
 static void send(Activity activity,MediaController player,Bundle args){ListenableFuture<SessionResult> result=player.sendCustomCommand(new SessionCommand(COMMAND,Bundle.EMPTY),args);result.addListener(()->{if(activity.isDestroyed()||activity.isFinishing())return;try{SessionResult value=result.get();Toast.makeText(activity,value.resultCode==SessionResult.RESULT_SUCCESS?"Fila atualizada":"A fila mudou ou esse movimento não está disponível. Abra as opções novamente.",Toast.LENGTH_SHORT).show();}catch(Exception e){Toast.makeText(activity,"Não foi possível atualizar a fila.",Toast.LENGTH_SHORT).show();}},new Handler(Looper.getMainLooper())::post);}
 static void change(Activity activity,MediaController player,List<MediaItem> before,int current,int index,String action){send(activity,player,request(before,current,index,action));}
 static void add(Activity activity,MediaController player,MediaItem item,boolean next){Bundle b=new Bundle();b.putString("action",next?"add_next":"add_end");b.putBundle("item",item.toBundleIncludeLocalConfiguration());send(activity,player,b);}
 // Runs on the service player looper: validate the expected queue immediately before editing.
 static SessionResult handle(Player player,Bundle args){boolean ok=false;try{ok=apply(player,args);}catch(RuntimeException ignored){}return new SessionResult(ok?SessionResult.RESULT_SUCCESS:SessionError.ERROR_BAD_VALUE);}
 private static boolean apply(Player player,Bundle args){String action=args.getString("action","");if(action.equals("add_next")||action.equals("add_end")){Bundle data=args.getBundle("item");if(data==null||player.getMediaItemCount()>=MusicResume.LIMIT)return false;MediaItem item=MediaItem.fromBundle(data);if(!DjSession.deviceAudio(item)||item.localConfiguration==null)return false;String scheme=item.localConfiguration.uri.getScheme();if(!"content".equals(scheme)&&!"file".equals(scheme))return false;if(player.getMediaItemCount()==0||player.getPlaybackState()==Player.STATE_ENDED)player.pause();player.setShuffleModeEnabled(false);int at=action.equals("add_next")&&player.getMediaItemCount()>0?player.getCurrentMediaItemIndex()+1:player.getMediaItemCount();player.addMediaItem(at,item);return true;}
  ArrayList<String> ids=args.getStringArrayList("ids");int current=args.getInt("current",-1),index=args.getInt("index",-1);if(ids==null||ids.size()!=player.getMediaItemCount()||current!=player.getCurrentMediaItemIndex())return false;for(int i=0;i<ids.size();i++)if(!ids.get(i).equals(player.getMediaItemAt(i).mediaId))return false;
  if(action.equals("clear")){if(current<0||current>=ids.size())return false;player.setShuffleModeEnabled(false);player.setRepeatMode(Player.REPEAT_MODE_OFF);player.removeMediaItems(current+1,ids.size());return true;}
  if(index<0||index>=ids.size())return false;if(action.equals("play")){player.seekToDefaultPosition(index);player.prepare();player.play();return true;}
  if(index<=current)return false;int target;switch(action){case "next":target=current+1;break;case "up":target=index-1;break;case "down":target=index+1;break;case "remove":target=index;break;default:return false;}if(target<=current||target>=ids.size())return false;player.setShuffleModeEnabled(false);if(action.equals("remove"))player.removeMediaItem(index);else player.moveMediaItem(index,target);return true;
 }
}
