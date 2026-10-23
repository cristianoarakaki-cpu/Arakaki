package br.com.onda;
import android.content.Context;

final class VoicePhrases {
    static VoicePhraseBook read(Context c){return new VoicePhraseBook(c.getSharedPreferences("voice_phrases",0).getString("entries","[]"));}
    static boolean save(Context c,VoicePhraseBook book){return c.getSharedPreferences("voice_phrases",0).edit().putString("entries",book.json()).commit();}
}
