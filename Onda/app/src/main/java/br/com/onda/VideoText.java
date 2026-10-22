package br.com.onda;
import java.util.Locale;
final class VideoText {
    static boolean matches(String title,String file,String query){return SearchText.matches(title+" "+file,query);}
    static String duration(long ms){if(ms<=0)return "--:--";long s=ms/1000;return s>=3600?String.format(Locale.ROOT,"%d:%02d:%02d",s/3600,s/60%60,s%60):String.format(Locale.ROOT,"%d:%02d",s/60,s%60);}
    static String format(String name){int dot=name==null?-1:name.lastIndexOf('.');if(dot<0||dot==name.length()-1)return "VÍDEO";return name.substring(dot+1).toUpperCase(Locale.ROOT);}
}
