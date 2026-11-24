package br.com.onda;
import android.app.AlertDialog;import android.content.Context;
/** Explicit settings affect future scans only, without new decoding passes. */
final class ChapterDetection {
 static final String[] NAMES={"Conservadora","Equilibrada","Sensível"};
 static int get(Context c){int mode=c.getSharedPreferences("chapter-detection",0).getInt("mode",1);return valid(mode)?mode:1;}
 static boolean valid(int mode){return mode>=0&&mode<3;}
 static AlertDialog show(Context c,Runnable changed){return new AlertDialog.Builder(c).setTitle("Detecção de divisões").setSingleChoiceItems(new String[]{"Conservadora • pausas claras, faixas de 30 s+","Equilibrada • pausas discretas, faixas de 25 s+","Sensível • pausas mais curtas, faixas de 20 s+"},get(c),(dialog,which)->{c.getSharedPreferences("chapter-detection",0).edit().putInt("mode",which).apply();changed.run();dialog.dismiss();}).setNeutralButton("Sobre os modos",(d,w)->new AlertDialog.Builder(c).setTitle("Detecção de divisões").setMessage("A análise estima limites por pausas e volume, sem reconhecer nomes. Sensibilidade maior pode criar divisões extras em trechos suaves. Confira os horários; mixes contínuos podem não separar.").setPositiveButton("Entendi",null).show()).setNegativeButton("Fechar",null).show();}
}
