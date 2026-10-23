package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
import java.util.*;
public class SmartFeaturesTest {
 @Test public void voiceCommandsPreserveSearchAndBoundTimers(){
  assertEquals(VoiceCommand.Action.FAVORITES,VoiceCommand.parse("Toque as minhas favoritas").action);
  assertEquals(VoiceCommand.Action.NEXT,VoiceCommand.parse("Próxima música").action);
  assertEquals(VoiceCommand.Action.PAUSE,VoiceCommand.parse("pause").action);
  assertEquals(30,VoiceCommand.parse("pare em trinta minutos").minutes);
  assertEquals(120,VoiceCommand.parse("pare daqui a duas horas").minutes);
  assertEquals(30,VoiceCommand.parse("pare em meia hora").minutes);
  assertEquals(VoiceCommand.Action.INVALID,VoiceCommand.parse("pare em 121 minutos").action);
  assertEquals(VoiceCommand.Action.INVALID,VoiceCommand.parse("pare em 99999999999999 horas").action);
  assertEquals(0,VoiceCommand.parse("cancele o temporizador").minutes);
  assertEquals("Chitãozinho e Xororó",VoiceCommand.parse("toque Chitãozinho e Xororó").query);
  assertEquals(VoiceCommand.Action.SEARCH,VoiceCommand.parse("Chitaozinho e xororo").action);
 }
 @Test public void naturalCommandsAndExplicitSearchesAreDistinct(){
  for(String phrase:Arrays.asList("toque as favoritas","Onda, toque minhas músicas favoritas, por favor","coloque as minhas favoritas","reproduza músicas favoritas"))assertEquals(phrase,VoiceCommand.Action.FAVORITES,VoiceCommand.parse(phrase).action);
  assertEquals(VoiceCommand.Action.FAVORITE_ADD,VoiceCommand.parse("adicione essa música aos favoritos").action);
  assertEquals(VoiceCommand.Action.FAVORITE_REMOVE,VoiceCommand.parse("remova dos favoritos").action);
  assertEquals(VoiceCommand.Action.SHUFFLE_ON,VoiceCommand.parse("ative o modo aleatório").action);
  assertEquals(VoiceCommand.Action.SHUFFLE_OFF,VoiceCommand.parse("desative o aleatório").action);
  assertEquals(VoiceCommand.Action.REPEAT_ONE,VoiceCommand.parse("repita a música").action);
  assertEquals(VoiceCommand.Action.REPEAT_ALL,VoiceCommand.parse("repita todas").action);
  assertEquals(VoiceCommand.Action.REPEAT_OFF,VoiceCommand.parse("não repetir").action);
  assertEquals(VoiceCommand.Action.HELP,VoiceCommand.parse("ajuda").action);
  assertEquals(VoiceCommand.Action.SEARCH,VoiceCommand.parse("pesquise favoritas").action);
  assertEquals("favoritas",VoiceCommand.parse("pesquise favoritas").query);
  assertEquals("Chitãozinho e Xororó",VoiceCommand.parse("Onda, coloque Chitãozinho e Xororó, por favor").query);
  assertEquals(VoiceCommand.Action.PLAY_QUERY,VoiceCommand.parse("toque Pause").action);
 }
 @Test public void fadeIsBoundedAndSkipsShortTracks(){
  assertEquals(0,FadeMath.gain(-1,2000,0,1),.0001);
  assertEquals(.5,FadeMath.gain(1000,2000,0,1),.0001);
  assertEquals(1,FadeMath.gain(3000,2000,0,1),.0001);
  assertEquals(48000,FadeMath.delay(60000,10000,1,2000));
  assertEquals(24000,FadeMath.delay(60000,10000,2,2000));
  assertEquals(-1,FadeMath.delay(-1,0,1,2000));
  assertEquals(-1,FadeMath.delay(3000,0,1,2000));
  assertEquals(-1,FadeMath.delay(60000,0,1,0));
 }
 @Test public void duplicateCandidatesRequireMetadataAndCloseDuration(){
  List<LibraryIntelligence.Song> songs=Arrays.asList(
   new LibraryIntelligence.Song("1","Canção","João",60000),
   new LibraryIntelligence.Song("2","Cancao","Joao",61000),
   new LibraryIntelligence.Song("3","Canção","João",62000),
   new LibraryIntelligence.Song("4","Canção","Outro",60000),
   new LibraryIntelligence.Song("5","Canção","Artista desconhecido",60000),
   new LibraryIntelligence.Song("1","Canção","João",60000));
  List<List<LibraryIntelligence.Song>> groups=LibraryIntelligence.duplicates(songs);
  assertEquals(1,groups.size());assertEquals(2,groups.get(0).size());
 }
}
