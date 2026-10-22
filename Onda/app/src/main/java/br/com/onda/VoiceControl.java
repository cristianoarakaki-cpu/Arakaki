package br.com.onda;

import android.app.Activity;
import android.os.Bundle;
import android.widget.Toast;
import androidx.media3.common.Player;
import androidx.media3.session.*;

@androidx.media3.common.util.UnstableApi
final class VoiceControl {
    static boolean execute(Activity activity,MediaController player,VoiceCommand command){
        if(command.action==VoiceCommand.Action.SEARCH||command.action==VoiceCommand.Action.PLAY_QUERY||command.action==VoiceCommand.Action.FAVORITES)return false;
        if(player==null){say(activity,"O tocador está iniciando. Tente novamente.");return true;}
        switch(command.action){
            case PLAY:
                if(player.getMediaItemCount()==0){say(activity,"Escolha uma música primeiro.");break;}
                if(player.getPlaybackState()==Player.STATE_ENDED)player.seekToDefaultPosition();player.prepare();player.play();say(activity,"Reproduzindo");break;
            case PAUSE:player.pause();say(activity,"Reprodução pausada");break;
            case NEXT:if(player.hasNextMediaItem())player.seekToNextMediaItem();else say(activity,"Não há próxima música nesta fila.");break;
            case PREVIOUS:player.seekToPrevious();break;
            case SLEEP:Bundle args=new Bundle();args.putInt("minutes",command.minutes);player.sendCustomCommand(new SessionCommand("sleep",Bundle.EMPTY),args);say(activity,command.minutes==0?"Temporizador desativado":"A música vai pausar em "+command.minutes+" minutos");break;
            case INVALID:say(activity,"Diga, por exemplo: pare em 30 minutos. O limite é de 120 minutos.");break;
            default:break;
        }
        return true;
    }
    static void say(Activity a,String text){Toast.makeText(a,text,Toast.LENGTH_LONG).show();}
}
