package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
public class SearchTextPreparedTest {
 @Test public void preparedQueryRetainsAccentPunctuationAndOrderRules(){SearchText.Query q=SearchText.prepare("Xororó e CHITÃOZINHO");assertTrue(q.matches("Chitãozinho & Xororó — Ao Vivo"));assertFalse(q.matches("Chitãozinho solo"));assertTrue(SearchText.prepare("ao vivo").matches("Vivo: gravação AO ar livre"));assertTrue(SearchText.prepare("amor and paz").matches("PAZ, AMOR"));}
 @Test public void emptySearchDoesNotProcessLibraryText(){CharSequence expensive=new CharSequence(){public int length(){throw new AssertionError("Text processed for empty query");}public char charAt(int n){throw new AssertionError();}public CharSequence subSequence(int a,int b){throw new AssertionError();}public String toString(){throw new AssertionError("Text normalized for empty query");}};assertTrue(SearchText.prepare("").matches(expensive));assertTrue(SearchText.prepare("e and").matches(expensive));assertTrue(SearchText.matches(null,null));}
 @Test public void preparedQueryCanBeReusedWithoutChangingMatches(){SearchText.Query q=SearchText.prepare("Faixa 2999");for(int i=0;i<3000;i++)assertEquals(i==2999,q.matches("Artista: Faixa "+i));assertEquals("cancao de amor",SearchText.normalize(" CANÇÃO — de amor "));}
}
