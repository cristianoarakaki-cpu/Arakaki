package br.com.onda;

import android.content.Context;

/** Reuses the existing single-player DSP and timed fades. No scanner or extra player. */
final class ListeningModes {
    static final String[] LABELS={"Sem equilíbrio ou transição","Equilibrado","Transições suaves"};
    static final String[] FADES={"Desligada","1 segundo","2 segundos","3 segundos"};
    static int fade(Context c){return Math.max(0,Math.min(3000,c.getSharedPreferences("audio",0).getInt("fade_ms",2000)));}
    static void fade(Context c,int ms){c.getSharedPreferences("audio",0).edit().putInt("fade_ms",Math.max(0,Math.min(3000,ms))).apply();}
    static void apply(Context c,int mode){
        if(mode<0||mode>=LABELS.length)throw new IllegalArgumentException("Modo inválido");
        SpeechSettings.leveling(c,mode!=0);fade(c,mode==0?0:mode==1?1000:3000);
    }
    static int current(Context c){boolean level=SpeechSettings.leveling(c);int fade=fade(c);
        return !level&&fade==0?0:level&&fade==1000?1:level&&fade==3000?2:-1;
    }
    static String summary(Context c){int mode=current(c);return "Modo de escuta: "+(mode<0?"Personalizado":LABELS[mode]);}
    private ListeningModes(){}
}
