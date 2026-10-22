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
            .putExtra(RecognizerIntent.EXTRA_PROMPT,"Diga música, artista, próxima música ou pare em 30 minutos")
            .putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE,local);
        try{activity.startActivityForResult(intent,REQUEST);}
        catch(ActivityNotFoundException|SecurityException e){Toast.makeText(activity,"Reconhecimento de voz indisponível neste celular. Você pode digitar a busca ou usar o microfone do teclado.",Toast.LENGTH_LONG).show();}
    }
    static String result(int code,Intent data){
        if(code!=Activity.RESULT_OK||data==null)return "";
        ArrayList<String> values=data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS);
        if(values!=null)for(String value:values){String clean=SearchText.spokenQuery(value);if(!clean.isEmpty())return clean;}
        return "";
    }
}
