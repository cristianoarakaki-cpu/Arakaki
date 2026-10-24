package br.com.onda;
import android.app.*;
import android.os.*;
import android.widget.Toast;
import androidx.media3.session.*;
import com.google.common.util.concurrent.ListenableFuture;

@androidx.media3.common.util.UnstableApi
final class DjControls {
    static void show(Activity a,MediaController player){
        String[] labels={"Mais variedade nas próximas","Mais desse artista nas próximas","Não repetir artista nas próximas","Por que esta música?","Monte minha viagem","Favoritas sem repetir artista","Downloads e redescobertas","Evitar esta música no DJ","Reautorizar músicas evitadas"};
        String[] actions={"variety","artist","unique","explain","travel","favorites_unique","downloads","avoid","reset_avoid"};
        new AlertDialog.Builder(a).setTitle("DJ Pessoal • ajustar sessão").setItems(labels,(d,i)->{if(actions[i].equals("reset_avoid"))new AlertDialog.Builder(a).setTitle("Reautorizar músicas?").setMessage("As músicas evitadas poderão entrar novamente nas novas sessões do DJ. A fila atual será mantida.").setPositiveButton("Reautorizar",(x,w)->send(a,player,"reset_avoid",null)).setNegativeButton("Cancelar",null).show();else send(a,player,actions[i],null);}).setNegativeButton("Fechar",null).show();
    }
    static void send(Activity a,MediaController player,String action,java.util.function.Consumer<String> done){
        if(player==null){VoiceControl.say(a,"O tocador está iniciando. Tente novamente.");return;}
        if(!player.isSessionCommandAvailable(new SessionCommand(DjSession.COMMAND,Bundle.EMPTY))){VoiceControl.say(a,"Reconecte o tocador para usar o DJ Pessoal.");return;}
        Bundle args=new Bundle();args.putString("action",action);ListenableFuture<SessionResult> future=player.sendCustomCommand(new SessionCommand(DjSession.COMMAND,Bundle.EMPTY),args);
        if(!action.equals("explain")&&!action.equals("avoid")&&!action.equals("reset_avoid"))Toast.makeText(a,"Montando seleção no celular…",Toast.LENGTH_SHORT).show();
        Handler handler=new Handler(Looper.getMainLooper());future.addListener(()->{if(a.isDestroyed()||a.isFinishing())return;try{String message=future.get().extras.getString("message","Pedido concluído.");if(done!=null)done.accept(message);if(action.equals("explain"))new AlertDialog.Builder(a).setTitle("Por que esta música?").setMessage(message).setPositiveButton("Entendi",null).show();else VoiceControl.say(a,message);}catch(Exception e){VoiceControl.say(a,"Não foi possível ajustar a sessão. Tente novamente.");}},handler::post);
    }
}
