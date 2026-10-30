package br.com.onda;
import android.content.Context;
/** Bit rate in kbps, independent of sample rate in Hz. */
final class Mp3Quality {
 static final int[] VALUES={128,192,256,320};
 static boolean valid(int value){for(int v:VALUES)if(v==value)return true;return false;}
 static int get(Context c){int v=c.getSharedPreferences("conversion",0).getInt("mp3_kbps",192);return valid(v)?v:192;}
 static void show(Context c,Runnable changed){int index=1;for(int i=0;i<VALUES.length;i++)if(VALUES[i]==get(c))index=i;new android.app.AlertDialog.Builder(c).setTitle("Qualidade das novas conversões MP3").setSingleChoiceItems(new String[]{"128 kbps • menor arquivo","192 kbps • equilibrado","256 kbps • alta qualidade","320 kbps • maior taxa"},index,(d,i)->{save(c,VALUES[i]);changed.run();d.dismiss();}).setNegativeButton("Cancelar",null).show();}
 static void save(Context c,int v){if(valid(v))c.getSharedPreferences("conversion",0).edit().putInt("mp3_kbps",v).apply();}
}
