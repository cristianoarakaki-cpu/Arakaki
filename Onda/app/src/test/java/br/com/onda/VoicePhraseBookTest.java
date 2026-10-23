package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;

public class VoicePhraseBookTest {
 @Test public void customPhrasesRoundTripAndIgnoreAccentsCaseAndPoliteness(){
  VoicePhraseBook b=new VoicePhraseBook("[]");b.put(null,"Minha sessão",VoiceCommand.Action.FAVORITES,"",0);
  VoicePhraseBook restored=new VoicePhraseBook(b.json());
  assertEquals(VoiceCommand.Action.FAVORITES,restored.find("Onda, minha SESSAO, por favor").action);
  assertNull(restored.find("minha sessão de ontem"));
  assertNull(restored.find("pesquise minha sessão"));
 }
 @Test public void editingReplacesOldPhraseAndActionAndDeletionRestoresFallback(){
  VoicePhraseBook b=new VoicePhraseBook("[]");VoicePhraseBook.Entry e=b.put(null,"hora de relaxar",VoiceCommand.Action.FAVORITES,"",0);
  b.put(e.id,"meu momento",VoiceCommand.Action.PAUSE,"",0);
  assertEquals(1,b.entries.size());assertNull(b.find("hora de relaxar"));assertEquals(VoiceCommand.Action.PAUSE,b.find("meu momento").action);
  b.remove(e.id);assertNull(b.find("meu momento"));
 }
 @Test public void queriesAndTimersKeepTheirArguments(){
  VoicePhraseBook b=new VoicePhraseBook("[]");b.put(null,"meu sertanejo",VoiceCommand.Action.PLAY_QUERY,"Chitãozinho e Xororó",0);b.put(null,"hora de dormir",VoiceCommand.Action.SLEEP,"",30);b.put(null,"sem prazo",VoiceCommand.Action.SLEEP,"",0);
  VoicePhraseBook restored=new VoicePhraseBook(b.json());assertEquals("Chitãozinho e Xororó",restored.find("meu sertanejo").query);assertEquals(30,restored.find("hora de dormir").minutes);assertEquals(0,restored.find("sem prazo").minutes);
 }
 @Test public void rejectsDuplicatesInvalidArgumentsAndReservedSearchPrefixes(){
  VoicePhraseBook b=new VoicePhraseBook("[]");b.put(null,"Minha sessão",VoiceCommand.Action.FAVORITES,"",0);
  invalid(()->b.put(null,"minha sessao!",VoiceCommand.Action.PAUSE,"",0));invalid(()->b.put(null,"ab",VoiceCommand.Action.PAUSE,"",0));invalid(()->b.put(null,"pesquise favoritas",VoiceCommand.Action.FAVORITES,"",0));
  invalid(()->b.put(null,"pause",VoiceCommand.Action.PLAY,"",0));
  invalid(()->b.put(null,"teste de busca",VoiceCommand.Action.SEARCH,"",0));invalid(()->b.put(null,"teste de tempo",VoiceCommand.Action.SLEEP,"",121));invalid(()->b.put(null,"teste de tempo",VoiceCommand.Action.SLEEP,"",-1));invalid(()->b.put(null,"teste de pausa",VoiceCommand.Action.PAUSE,"",5));
 }
 @Test public void limitAndMalformedStorageAreHandled(){
  VoicePhraseBook b=new VoicePhraseBook("bad json");assertTrue(b.entries.isEmpty());
  for(int i=0;i<100;i++)b.put(null,"frase numero "+i,VoiceCommand.Action.PAUSE,"",0);
  invalid(()->b.put(null,"frase adicional",VoiceCommand.Action.PAUSE,"",0));
  VoicePhraseBook.Entry e=b.entries.get(0);b.put(e.id,"frase alterada",VoiceCommand.Action.PLAY,"",0);assertEquals(100,b.entries.size());
 }
 private void invalid(Runnable r){try{r.run();fail("Invalid phrase accepted");}catch(IllegalArgumentException expected){}}
}
