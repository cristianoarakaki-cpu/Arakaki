package br.com.onda;
import java.util.Locale;
import org.junit.Test;
import static org.junit.Assert.*;
public class AudioLanguageTest {
 @Test public void brazilWinsOverGenericPortugueseAndPortugueseWinsOverForeignOriginal(){assertTrue(AudioLanguage.rank(Locale.forLanguageTag("pt-BR"),false)<AudioLanguage.rank(Locale.forLanguageTag("pt"),true));assertTrue(AudioLanguage.rank(Locale.forLanguageTag("pt"),false)<AudioLanguage.rank(Locale.forLanguageTag("pt-PT"),true));assertTrue(AudioLanguage.rank(Locale.forLanguageTag("pt-PT"),false)<AudioLanguage.rank(Locale.ENGLISH,true));}
 @Test public void originalWinsWhenPortugueseIsMissingAndUnknownLanguageIsNotMislabelled(){assertTrue(AudioLanguage.rank(Locale.ENGLISH,true)<AudioLanguage.rank(Locale.GERMAN,false));assertEquals("Português (Brasil)",AudioLanguage.notice(Locale.forLanguageTag("pt-BR"),false));assertTrue(AudioLanguage.notice(null,false).contains("não informado"));assertFalse(AudioLanguage.notice(Locale.ENGLISH,true).contains("Português (Brasil)"));assertTrue(AudioLanguage.notice(Locale.ENGLISH,true).contains("português indisponível"));}
}
