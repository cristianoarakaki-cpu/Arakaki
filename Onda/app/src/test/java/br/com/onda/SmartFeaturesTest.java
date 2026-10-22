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
