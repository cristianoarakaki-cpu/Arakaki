package br.com.onda;
import org.junit.Test;import static org.junit.Assert.*;
public class MessageCardsTest {
 @Test public void greetingsSearchWithoutAccents(){assertEquals(3,MessageCards.search("BOA NOITE").size());assertEquals("Feliz aniversário",MessageCards.search("aniversario").get(0).title);assertTrue(MessageCards.search("nao-existe-aqui").isEmpty());}
 @Test public void voiceSearchKeepsSubject(){assertEquals("boa noite",MessageCards.voiceQuery("procure imagens de boa noite"));assertEquals("flores",MessageCards.voiceQuery("Onda, pesquise por flores"));assertEquals("bom dia",MessageCards.voiceQuery("bom dia"));assertEquals("",MessageCards.voiceQuery(null));}
 @Test public void allTemplatesHaveTextAndValidBackground(){assertEquals(16,MessageCards.ALL.size());for(MessageCards.Card card:MessageCards.ALL){assertFalse(card.text.isEmpty());assertTrue(card.style>=0&&card.style<MessageCards.STYLES.length);assertTrue(card.text.length()<=360);}}
}
