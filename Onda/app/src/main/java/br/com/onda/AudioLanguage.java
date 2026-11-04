package br.com.onda;
import java.util.Locale;
/** Preferences only. Never claims translation or infers language from a video's title. */
final class AudioLanguage {
 private static final Locale BRAZIL=Locale.forLanguageTag("pt-BR");
 static int rank(Locale locale,boolean original){if(locale!=null&&"pt".equalsIgnoreCase(locale.getLanguage()))return "BR".equalsIgnoreCase(locale.getCountry())?0:locale.getCountry().isEmpty()?1:2;return original?3:4;}
 static String notice(Locale locale,boolean original){
  if(locale==null||locale.getLanguage().isEmpty())return "Idioma não informado pelo YouTube"+(original?" • áudio original":"");
  if("pt".equalsIgnoreCase(locale.getLanguage())){if("BR".equalsIgnoreCase(locale.getCountry()))return "Português (Brasil)";if(locale.getCountry().isEmpty())return "Português • região não informada";return locale.getDisplayName(BRAZIL)+" • faixa pt-BR indisponível";}
  return (original?"Áudio original • ":"")+locale.getDisplayName(BRAZIL)+" • português indisponível";
 }
}
