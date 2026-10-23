package br.com.onda;

import android.app.Activity;
import android.content.*;
import android.speech.RecognizerIntent;
import android.widget.Toast;
import java.util.ArrayList;

/** Uses the phone's speech dialog; this app never records or listens in background. */
final class VoiceSearch {
    static final int REQUEST=7301;
    static void start(Activity activity,boolean local){
        Intent intent=new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
            .putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL,RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            .putExtra(RecognizerIntent.EXTRA_LANGUAGE,"pt-BR")
            .putExtra(RecognizerIntent.EXTRA_MAX_RESULTS,3)
            .putExtra(RecognizerIntent.EXTRA_PROMPT,"Diga: toque as favoritas, próxima música ou ajuda")
            .putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE,local);
        try{activity.startActivityForResult(intent,REQUEST);}
        catch(ActivityNotFoundException|SecurityException e){Toast.makeText(activity,"Reconhecimento de voz indisponível neste celular. Você pode digitar a busca ou usar o microfone do teclado.",Toast.LENGTH_LONG).show();}
    }
    static void help(Activity activity){
        new android.app.AlertDialog.Builder(activity).setTitle("Comandos de voz")
            .setMessage("Toque no microfone e diga:\n\n• Toque minha playlist Viagem\n• Toque minhas músicas favoritas\n• Toque Chitãozinho e Xororó\n• Pesquise por nome ou artista\n• Pause / continue / próxima música / música anterior\n• Adicione aos favoritos / remova dos favoritos\n• Ative ou desative o modo aleatório\n• Repita a música / repita todas / não repetir\n• Pare em 30 minutos / cancele o temporizador\n\nFavoritas e reprodução por nome usam os arquivos do celular. Em Explorar, nomes pesquisam o catálogo online. O microfone só é usado quando você o aciona. Para pedidos livres, configure o Assistente com IA no menu.")
            .setPositiveButton("Entendi",null).setNeutralButton("Minhas frases",(d,w)->activity.startActivity(new Intent(activity,VoicePhrasesActivity.class))).show();
    }
    static String result(int code,Intent data){
        if(code!=Activity.RESULT_OK||data==null)return "";
        ArrayList<String> values=data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS);
        if(values!=null)for(String value:values){String clean=value==null?"":value.trim();if(!clean.isEmpty())return clean;}
        return "";
    }
}
