package br.com.onda;
import android.content.Context;
final class YouTubeFavorites {
 static final String PREF="youtube_favorites",KEY="data",EXTRA="youtube_favorite_url";
 static YouTubeFavoritesData read(Context c){return YouTubeFavoritesData.decode(c.getSharedPreferences(PREF,0).getString(KEY,""));}
 static synchronized boolean save(Context c,String url,String name){YouTubeFavoritesData data=read(c);if(!data.save(url,name,System.currentTimeMillis()))return false;c.getSharedPreferences(PREF,0).edit().putString(KEY,data.encode()).apply();return true;}
 static synchronized boolean remove(Context c,String url){YouTubeFavoritesData data=read(c);if(!data.remove(url))return false;c.getSharedPreferences(PREF,0).edit().putString(KEY,data.encode()).apply();return true;}
}
