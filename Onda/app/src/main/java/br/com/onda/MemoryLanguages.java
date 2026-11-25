package br.com.onda;
import android.content.Context;
/** Explicit languages supported by the existing native recognizer. */
final class MemoryLanguages {
 static final String[] LABELS={"Português (Brasil)","Inglês","Espanhol","Francês","Italiano","Alemão"};
 static final String[] CODES={"pt","en","es","fr","it","de"};
 static int selected(Context c){String value=c.getSharedPreferences("memory_options",0).getString("language","pt");for(int i=0;i<CODES.length;i++)if(CODES[i].equals(value))return i;return 0;}
 static String get(Context c){return CODES[selected(c)];}
 static void save(Context c,int index){if(index>=0&&index<CODES.length)c.getSharedPreferences("memory_options",0).edit().putString("language",CODES[index]).apply();}
}
