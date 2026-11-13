package br.com.onda;

import android.app.*;
import android.content.*;
import android.view.View;
import java.util.*;

/** User-chosen destinations only; opened on demand with the existing navigation. */
@androidx.annotation.OptIn(markerClass=androidx.media3.common.util.UnstableApi.class)
final class QuickAccess {
    static final String PREF="quick_access",KEY="screens";
    static final VoiceCommand.Action[] ACTIONS={VoiceCommand.Action.OPEN_YOUTUBE,VoiceCommand.Action.OPEN_IMAGES,VoiceCommand.Action.OPEN_RADIOS,VoiceCommand.Action.OPEN_DOWNLOADS,VoiceCommand.Action.OPEN_UPDATES,VoiceCommand.Action.OPEN_VIDEOS,VoiceCommand.Action.OPEN_PDF,VoiceCommand.Action.OPEN_SOUND,VoiceCommand.Action.OPEN_CONVERTER,VoiceCommand.Action.OPEN_PLAYLISTS,VoiceCommand.Action.OPEN_QUEUE,VoiceCommand.Action.OPEN_APPEARANCE,VoiceCommand.Action.OPEN_FILES,VoiceCommand.Action.OPEN_CHAPTERS,VoiceCommand.Action.OPEN_VOICE_PHRASES,VoiceCommand.Action.OPEN_MUSIC};
    static final String[] LABELS={"YouTube","Imagens e mensagens","Rádios online","Downloads","Atualizações","Vídeos","Leitor de PDF","Estúdio de som","Conversor local","Playlists","Fila de reprodução","Aparências","Arquivos do Onda","Faixas da coletânea","Minhas frases","Músicas"};
    static Set<String> read(Context context){
        Set<String> defaults=new HashSet<>(Arrays.asList("OPEN_YOUTUBE","OPEN_IMAGES","OPEN_RADIOS"));
        Set<String> saved=context.getSharedPreferences(PREF,0).getStringSet(KEY,defaults),known=new HashSet<>();
        for(VoiceCommand.Action action:ACTIONS)if(saved.contains(action.name()))known.add(action.name());
        return known;
    }
    static void menu(Activity activity,View anchor){
        Set<String> chosen=read(activity);List<String> labels=new ArrayList<>();List<Runnable> actions=new ArrayList<>();
        for(int i=0;i<ACTIONS.length;i++)if(chosen.contains(ACTIONS[i].name())){
            final VoiceCommand.Action action=ACTIONS[i];labels.add(LABELS[i]);actions.add(()->VoiceNavigation.execute(activity,VoiceCommand.of(action)));
        }
        labels.add("Central inteligente");actions.add(()->activity.startActivity(new Intent(activity,AutomationActivity.class)));
        labels.add("Ajuda rápida");actions.add(()->help(activity));
        labels.add("Escolher atalhos");actions.add(()->choose(activity));
        String[] names=labels.toArray(new String[0]);Ui.menu(activity,anchor,names,names,actions.toArray(new Runnable[0]));
    }
    static AlertDialog choose(Activity activity){
        Set<String> pending=new HashSet<>(read(activity));boolean[] checked=new boolean[ACTIONS.length];
        for(int i=0;i<checked.length;i++)checked[i]=pending.contains(ACTIONS[i].name());
        return new AlertDialog.Builder(activity).setTitle("Meus atalhos").setMultiChoiceItems(LABELS,checked,(dialog,index,on)->{
            if(on)pending.add(ACTIONS[index].name());else pending.remove(ACTIONS[index].name());
        }).setNegativeButton("Cancelar",null).setPositiveButton("Salvar",(dialog,which)->activity.getSharedPreferences(PREF,0).edit().putStringSet(KEY,new HashSet<>(pending)).apply()).show();
    }
    static AlertDialog help(Activity activity){
        return new AlertDialog.Builder(activity).setTitle("Ajuda rápida do Onda").setMessage(
                "REPETIÇÃO\nNo cartão Tocando agora, o último botão à direita, depois de Próxima, é o de repetição. O texto no cartão mostra se está desligada, repetindo uma música ou repetindo a fila. Toque para alternar; segure o botão para abrir esta ajuda.\n\n"+
                "FAIXAS DA COLETÂNEA\nEscolha a faixa em Faixas, volte ao tocador e ative ↻ 1. O nome e os horários de início e fim identificam o trecho. Desligar libera o restante do arquivo. As divisões detectadas por pausas são aproximadas; o original é preservado.\n\n"+
                "ATALHOS POR VOZ\nNa tela Músicas, toque no microfone ao lado de Buscar no celular. Diga: abrir YouTube, abrir imagens, abrir atualizações ou repita esta faixa. O microfone só funciona quando você o aciona.\n\n"+
                "MEUS ATALHOS\nToque em Atalhos → Escolher atalhos, marque as telas e salve. Cancelar mantém a escolha anterior. A seleção é separada dos favoritos de músicas e vídeos.\n\n"+
                "ATUALIZAR\nMenu → Atualizações abre a verificação da nova versão; a instalação é confirmada pelo Android.")
                .setPositiveButton("Entendi",null).show();
    }
}
