package br.com.onda;

import android.content.*;
import android.os.*;
import androidx.media3.common.*;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.session.*;
import com.google.common.util.concurrent.*;
import java.util.*;
import java.util.concurrent.*;

/** Finite, user-requested local calculations. Player mutations stay on its main looper. */
@androidx.media3.common.util.UnstableApi
final class DjSession {
    static final String COMMAND="personal_dj",REASON="dj_reason";
    private final Context context;private final ExoPlayer player;private final Handler main=new Handler(Looper.getMainLooper());
    private final ExecutorService worker=Executors.newSingleThreadExecutor();private Future<?> pending;private SettableFuture<SessionResult> reply;private int generation;private boolean closed;private DjPlanner.Mode activeMode=DjPlanner.Mode.PERSONAL;
    DjSession(Context context,ExoPlayer player){this.context=context;this.player=player;}
    static List<DjPlanner.Song> describe(Context c,List<MediaItem> library){
        Set<String> avoided=avoided(c);Set<String> favorites=c.getSharedPreferences("library",0).getStringSet("favorites",Collections.emptySet());Map<String,?> history=c.getSharedPreferences("listening",0).getAll();List<DjPlanner.Song> songs=new ArrayList<>();
        for(MediaItem item:library){if(avoided.contains(item.mediaId))continue;songs.add(new DjPlanner.Song(item.mediaId,String.valueOf(item.mediaMetadata.title),String.valueOf(item.mediaMetadata.artist),LibraryStore.number(item,"durationMs"),number(history,"count:"+item.mediaId).intValue(),number(history,"last:"+item.mediaId).longValue(),favorites.contains(item.mediaId),number(history,"complete:"+item.mediaId).intValue()));}
        return songs;
    }
    static Set<String> avoided(Context c){return new HashSet<>(c.getSharedPreferences("dj_preferences",0).getStringSet("avoided",Collections.emptySet()));}
    static String remember(List<MediaItem> queue){Map<String,DjMemory.Cue> cues=new HashMap<>();for(MediaItem item:queue){String why=reason(item);if(!why.isEmpty())cues.put(item.mediaId,new DjMemory.Cue(why,item.mediaMetadata.extras.getInt("dj_mode",0)));}return DjMemory.encode(cues);}
    static MediaItem restore(MediaItem item,Map<String,DjMemory.Cue> cues){DjMemory.Cue cue=cues.get(item.mediaId);return cue==null?item:explain(item,cue.reason,DjPlanner.Mode.values()[cue.mode]);}
    private static Number number(Map<String,?> data,String key){Object value=data.get(key);return value instanceof Number?(Number)value:0;}
    static MediaItem explain(MediaItem item,String reason){return explain(item,reason,DjPlanner.Mode.PERSONAL);}
    static MediaItem explain(MediaItem item,String reason,DjPlanner.Mode mode){Bundle extras=item.mediaMetadata.extras==null?new Bundle():new Bundle(item.mediaMetadata.extras);extras.putString(REASON,reason);extras.putInt("dj_mode",mode.ordinal());return item.buildUpon().setMediaMetadata(item.mediaMetadata.buildUpon().setExtras(extras).build()).build();}
    static String reason(MediaItem item){return item==null||item.mediaMetadata.extras==null?"":item.mediaMetadata.extras.getString(REASON,"");}
    private static SessionResult result(String text){Bundle b=new Bundle();b.putString("message",text);return new SessionResult(SessionResult.RESULT_SUCCESS,b);}
    private List<String> queueIds(){List<String> ids=new ArrayList<>();for(int i=0;i<player.getMediaItemCount();i++)ids.add(player.getMediaItemAt(i).mediaId);return ids;}
    ListenableFuture<SessionResult> request(Bundle args){
        String requested=args.getString("action","start");final String action=requested==null?"start":requested;
        if(action.equals("reset_avoid")){context.getSharedPreferences("dj_preferences",0).edit().remove("avoided").apply();return Futures.immediateFuture(result("As músicas evitadas voltaram a poder participar das novas sessões. A fila atual foi mantida."));}
        if(action.equals("avoid")){
            MediaItem current=player.getCurrentMediaItem();if(!deviceAudio(current))return Futures.immediateFuture(result("Escolha uma música do celular ou um download primeiro."));
            Set<String> avoided=avoided(context);if(avoided.size()>=1000&&!avoided.contains(current.mediaId))return Futures.immediateFuture(result("Limite de 1.000 músicas evitadas. Reautorize músicas pelo menu do DJ."));
            generation++;if(pending!=null)pending.cancel(true);if(reply!=null&&!reply.isDone())reply.set(result("Pedido anterior cancelado pela nova preferência."));
            avoided.add(current.mediaId);context.getSharedPreferences("dj_preferences",0).edit().putStringSet("avoided",avoided).apply();
            for(int i=player.getMediaItemCount()-1;i>player.getCurrentMediaItemIndex();i--)if(!reason(current).isEmpty()&&player.getMediaItemAt(i).mediaId.equals(current.mediaId))player.removeMediaItem(i);
            return Futures.immediateFuture(result("Esta música será evitada nas próximas sessões do DJ. A música atual continua e o arquivo fica na biblioteca."));
        }
        if(action.equals("explain")){String reason=reason(player.getCurrentMediaItem());return Futures.immediateFuture(result(reason.isEmpty()?"Não há uma escolha do DJ salva para esta faixa. Inicie uma sessão para ver os motivos.":reason));}
        if(!Arrays.asList("start","travel","favorites","downloads","variety","artist","unique","favorites_unique").contains(action))return Futures.immediateFuture(new SessionResult(SessionError.ERROR_BAD_VALUE));
        boolean adjust=action.equals("variety")||action.equals("artist")||action.equals("unique");MediaItem current=player.getCurrentMediaItem();
        if(adjust&&(current==null||!deviceAudio(current)))return Futures.immediateFuture(result("Toque uma música do celular ou uma sessão do DJ primeiro."));
        String artist=current==null?"":new DjPlanner.Song("", "",String.valueOf(current.mediaMetadata.artist),0,0,0,false).artistKey();
        if(action.equals("artist")&&(artist.isEmpty()||artist.equals("download local")))return Futures.immediateFuture(result("Este arquivo não informa o artista. Escolha uma faixa com artista identificado."));
        Set<String> priorArtists=new HashSet<>();
        int index=player.getCurrentMediaItemIndex();if(adjust)for(int i=0;i<=index;i++){String key=new DjPlanner.Song("","",String.valueOf(player.getMediaItemAt(i).mediaMetadata.artist),0,0,0,false).artistKey();if(!key.isEmpty())priorArtists.add(key);}List<String> before=queueIds();Set<String> excluded=new HashSet<>();if(adjust)for(int i=0;i<=index;i++)excluded.add(before.get(i));
        int limit=adjust?Math.max(0,60-index-1):30;
        if(limit==0)return Futures.immediateFuture(result("Esta sessão chegou ao limite de 60 músicas. Inicie uma nova sessão."));
        if(adjust)activeMode=DjPlanner.Mode.PERSONAL;
        if(adjust&&current.mediaMetadata.extras!=null){int m=current.mediaMetadata.extras.getInt("dj_mode",0);activeMode=DjPlanner.Mode.values()[Math.max(0,Math.min(DjPlanner.Mode.values().length-1,m))];}
        DjPlanner.Mode mode=action.equals("favorites")||action.equals("favorites_unique")?DjPlanner.Mode.FAVORITES:action.equals("travel")?DjPlanner.Mode.TRAVEL:action.equals("downloads")?DjPlanner.Mode.DOWNLOADS:adjust?activeMode:DjPlanner.Mode.PERSONAL;
        int ticket=++generation;if(pending!=null)pending.cancel(true);if(reply!=null&&!reply.isDone())reply.set(result("Substituído pelo pedido mais recente."));reply=SettableFuture.create();SettableFuture<SessionResult> response=reply;
        pending=worker.submit(()->{try{
            List<MediaItem> library=LibraryStore.scan(context);Map<String,MediaItem> items=new HashMap<>();for(MediaItem item:library)items.put(item.mediaId,item);
            List<DjPlanner.Song> source=describe(context,library);
            // In strict mode the artist of the playing track is already used.
            if(adjust&&action.equals("unique")&&!priorArtists.isEmpty())source.removeIf(s->priorArtists.contains(s.artistKey()));
            if(action.equals("artist")&&source.stream().noneMatch(song->!excluded.contains(song.id)&&song.artistKey().equals(artist))){main.post(()->{if(!closed&&ticket==generation)response.set(result("Não há outra música disponível desse artista na biblioteca. A fila foi mantida."));});return;}
            long now=System.currentTimeMillis();List<DjPlanner.Song> chosen=DjPlanner.build(source,mode,limit,SystemClock.elapsedRealtimeNanos(),now,excluded,action.equals("unique")||action.equals("favorites_unique"),action.equals("variety"),action.equals("artist")?artist:"");
            List<MediaItem> next=new ArrayList<>();for(DjPlanner.Song song:chosen){String why=action.equals("artist")&&song.artistKey().equals(artist)?"Artista priorizado por você":DjPlanner.explain(song,mode,now);next.add(explain(items.get(song.id),why,mode));}
            main.post(()->{if(closed||ticket!=generation)return;
                if(!before.equals(queueIds())||index!=player.getCurrentMediaItemIndex()){response.set(result("A fila mudou enquanto a seleção era montada. Faça o pedido novamente."));return;}
                if(next.isEmpty()&&adjust&&action.equals("unique")){player.setShuffleModeEnabled(false);player.setRepeatMode(Player.REPEAT_MODE_OFF);player.replaceMediaItems(index+1,player.getMediaItemCount(),Collections.emptyList());response.set(result("Não há outros artistas disponíveis. A sessão termina após a música atual."));return;}
                if(next.isEmpty()){response.set(result("Não há músicas disponíveis para esse pedido. A fila atual foi mantida."));return;}
                player.setShuffleModeEnabled(false);player.setRepeatMode(Player.REPEAT_MODE_OFF);
                if(adjust){player.replaceMediaItems(index+1,player.getMediaItemCount(),next);response.set(result(next.size()+" próximas músicas ajustadas. A música atual continua."));}
                else{activeMode=mode;player.setMediaItems(next);player.prepare();player.play();response.set(result("DJ Pessoal iniciado • "+next.size()+" músicas."));}
            });
        }catch(Exception e){main.post(()->{if(!closed&&ticket==generation)response.set(result("Não foi possível montar a sessão. Confira o acesso às músicas na biblioteca."));});}});
        return response;
    }
    static boolean deviceAudio(MediaItem item){return item!=null&&MusicResume.deviceId(item.mediaId);}
    void close(){closed=true;generation++;if(pending!=null)pending.cancel(true);worker.shutdownNow();if(reply!=null&&!reply.isDone())reply.set(result("Sessão encerrada."));main.removeCallbacksAndMessages(null);}
}
