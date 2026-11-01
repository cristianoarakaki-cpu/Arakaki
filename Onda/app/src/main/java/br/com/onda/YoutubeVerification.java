package br.com.onda;
import java.util.Locale;
/** Identifies an external verification demand without pretending it can be removed locally. */
final class YoutubeVerification {
 static boolean required(String text){if(text==null)return false;String s=text.toLowerCase(Locale.ROOT);return s.contains("youtube")&&(s.contains("robô")||s.contains("robo")||s.contains("not a bot")||s.contains("confirmnotbot"));}
 static String link(String input){try{return YouTubeFavoritesData.canonical(DownloadLinks.resolve(input));}catch(Exception invalid){return "";}}
}
