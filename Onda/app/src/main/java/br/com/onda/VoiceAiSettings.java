package br.com.onda;
import android.app.*;
import android.content.Context;
import android.widget.Toast;

final class VoiceAiSettings {
    static boolean enabled(Context c){return c.getSharedPreferences("voice_ai",0).getBoolean("local_enabled",true);}
    static void show(Activity activity){activity.startActivity(new android.content.Intent(activity,AutomationActivity.class));}
    private static void set(Activity a,boolean value){a.getSharedPreferences("voice_ai",0).edit().putBoolean("local_enabled",value).apply();Toast.makeText(a,value?"Interpretação local ativada":"Apenas comandos diretos ativados",Toast.LENGTH_SHORT).show();}
}
