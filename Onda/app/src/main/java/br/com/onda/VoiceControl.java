package br.com.onda;

import android.app.Activity;
import android.os.Bundle;
import android.widget.Toast;
import androidx.media3.common.Player;
import androidx.media3.session.*;

@androidx.media3.common.util.UnstableApi
final class VoiceControl {
    static boolean execute(Activity activity,MediaController player,VoiceCommand command){
        PlaylistVoice.cancel();
        if(command.action==VoiceCommand.Action.ADD_PLAYLIST){PlaylistVoice.addCurrent(activity,player,command.query);return true;}
        if(command.action==VoiceCommand.Action.PLAY_PLAYLIST){PlaylistVoice.play(activity,player,command.query);return true;}
        if(command.action==VoiceCommand.Action.SEARCH||command.action==VoiceCommand.Action.PLAY_QUERY||command.action==VoiceCommand.Action.FAVORITES||command.action==VoiceCommand.Action.FAVORITE_ADD||command.action==VoiceCommand.Action.FAVORITE_REMOVE)return false;
        if(command.action==VoiceCommand.Action.HELP){VoiceSearch.help(activity);return true;}
        if(player==null){say(activity,"O tocador está iniciando. Tente novamente.");return true;}
        switch(command.action){
            case DJ_PERSONAL:case DJ_TRAVEL:case DJ_DOWNLOADS:case DJ_VARIETY:case DJ_ARTIST:case DJ_UNIQUE:case DJ_FAVORITES_UNIQUE:case DJ_EXPLAIN:
                String action=command.action==VoiceCommand.Action.DJ_TRAVEL?"travel":command.action==VoiceCommand.Action.DJ_DOWNLOADS?"downloads":command.action==VoiceCommand.Action.DJ_VARIETY?"variety":command.action==VoiceCommand.Action.DJ_ARTIST?"artist":command.action==VoiceCommand.Action.DJ_UNIQUE?"unique":command.action==VoiceCommand.Action.DJ_FAVORITES_UNIQUE?"favorites_unique":command.action==VoiceCommand.Action.DJ_EXPLAIN?"explain":"start";
                DjControls.send(activity,player,action,null);break;
            case PLAY:
                if(player.getMediaItemCount()==0){say(activity,"Escolha uma música primeiro.");break;}
                if(player.getPlaybackState()==Player.STATE_ENDED)player.seekToDefaultPosition();player.prepare();player.play();say(activity,"Reproduzindo");break;
            case PAUSE:player.pause();say(activity,"Reprodução pausada");break;
            case NEXT:if(player.hasNextMediaItem())player.seekToNextMediaItem();else say(activity,"Não há próxima música nesta fila.");break;
            case PREVIOUS:player.seekToPrevious();break;
            case SHUFFLE_ON:case SHUFFLE_OFF:
                boolean shuffle=command.action==VoiceCommand.Action.SHUFFLE_ON;player.setShuffleModeEnabled(shuffle);say(activity,shuffle?"Modo aleatório ativado":"Modo aleatório desativado");break;
            case REPEAT_ONE:case REPEAT_ALL:case REPEAT_OFF:
                int mode=command.action==VoiceCommand.Action.REPEAT_ONE?Player.REPEAT_MODE_ONE:command.action==VoiceCommand.Action.REPEAT_ALL?Player.REPEAT_MODE_ALL:Player.REPEAT_MODE_OFF;
                player.setRepeatMode(mode);say(activity,mode==Player.REPEAT_MODE_ONE?"Repetindo a música atual":mode==Player.REPEAT_MODE_ALL?"Repetindo a fila":"Repetição desativada");break;
            case SLEEP:Bundle args=new Bundle();args.putInt("minutes",command.minutes);player.sendCustomCommand(new SessionCommand("sleep",Bundle.EMPTY),args);say(activity,command.minutes==0?"Temporizador desativado":"A música vai pausar em "+command.minutes+" minutos");break;
            case INVALID:say(activity,"Diga, por exemplo: pare em 30 minutos. O limite é de 120 minutos.");break;
            default:break;
        }
        return true;
    }
    static void say(Activity a,String text){Toast.makeText(a,text,Toast.LENGTH_LONG).show();}
}
