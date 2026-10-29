package br.com.onda;
import android.app.Activity;
final class AppearanceStyles {
 static void window(Activity a,AppearancePalette p){int style=p.id.equals("nebula")?R.style.AccentNebula:p.id.equals("circuit")?R.style.AccentCircuit:p.id.equals("solar")?R.style.AccentSolar:p.id.equals("graphite")?R.style.AccentGraphite:R.style.AccentOriginal;a.getTheme().applyStyle(style,true);a.getWindow().setStatusBarColor(p.bg);a.getWindow().setNavigationBarColor(p.bg);}
 static void choose(Activity a,AppearancePalette p){a.getSharedPreferences("appearance",0).edit().putString("theme",p.id).apply();Ui.install(p);if(a.getApplication() instanceof OndaApplication)((OndaApplication)a.getApplication()).refreshAll();}
}
