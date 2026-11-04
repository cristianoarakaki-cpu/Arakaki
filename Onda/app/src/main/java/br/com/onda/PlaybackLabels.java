package br.com.onda;

import androidx.media3.common.MediaItem;
import androidx.media3.common.Player;

/** Labels follow player events; no timer or new playback state. */
@androidx.media3.common.util.UnstableApi
final class PlaybackLabels {
    static String repetition(Player player){
        if(player==null)return "Repetição desligada";
        MediaItem item=player.getCurrentMediaItem();
        if(RadioMedia.is(item))return "Rádio ao vivo • repetição indisponível";
        int mode=player.getRepeatMode();
        if(mode==Player.REPEAT_MODE_OFF)return "Repetição desligada";
        if(YouTubeAudio.is(item))return "Repetindo este áudio do YouTube";
        if(mode==Player.REPEAT_MODE_ALL)return "Repetindo a fila";
        return AudioChapterPlayback.selected(item)?"Repetindo faixa: "+AudioChapterPlayback.label(item):"Repetindo esta música";
    }
    static String chapterRange(Player player){
        MediaItem item=player==null?null:player.getCurrentMediaItem();
        if(player==null||player.getRepeatMode()!=Player.REPEAT_MODE_ONE||!AudioChapterPlayback.selected(item))return "";
        return "Início: "+AudioChaptersActivity.time(AudioChapterPlayback.start(item))+" • Fim: "+AudioChaptersActivity.time(AudioChapterPlayback.end(item));
    }
    static String compactRange(Player player){if(chapterRange(player).isEmpty())return "";MediaItem item=player.getCurrentMediaItem();return AudioChaptersActivity.time(AudioChapterPlayback.start(item))+" → "+AudioChaptersActivity.time(AudioChapterPlayback.end(item));}
    static String announcement(Player player){String range=chapterRange(player);return repetition(player)+(range.isEmpty()?"":"\n"+range);}
}
