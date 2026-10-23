package br.com.onda;
import android.app.*;
import android.content.Context;
import android.widget.Toast;

final class VoiceAiSettings {
    static boolean enabled(Context c){return c.getSharedPreferences("voice_ai",0).getBoolean("local_enabled",true);}
    static void show(Activity activity){
        new AlertDialog.Builder(activity).setTitle("Assistente local gratuito")
            .setMessage("Interpreta intenções de voz no próprio celular, sem API, assinatura ou cobrança adicional.\n\nExperimente: ‘coloca aquelas músicas que eu mais gosto’, ‘guarda essa música nos favoritos’ ou ‘mistura a ordem das músicas’.\n\nÉ um classificador de intenções treinado para os controles do Onda. Quando não identifica uma ação com confiança, mantém o pedido como busca. Não é um assistente de conversa geral.\n\nNão envia pedidos a um serviço de IA, não baixa modelos e só trabalha quando você faz um pedido. O reconhecimento da fala continua dependendo do serviço do celular e pode precisar de internet.\n\nEstado: "+(enabled(activity)?"ativado":"desativado"))
            .setPositiveButton("Ativar",(d,w)->set(activity,true)).setNeutralButton("Desativar",(d,w)->set(activity,false)).setNegativeButton("Fechar",null).show();
    }
    private static void set(Activity a,boolean value){a.getSharedPreferences("voice_ai",0).edit().putBoolean("local_enabled",value).apply();Toast.makeText(a,value?"Interpretação local ativada":"Apenas comandos diretos ativados",Toast.LENGTH_SHORT).show();}
}
