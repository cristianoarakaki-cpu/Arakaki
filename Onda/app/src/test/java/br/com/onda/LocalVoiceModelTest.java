package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;

public class LocalVoiceModelTest {
 @Test public void interpretsParaphrasesOfPlayerRequests(){
  assertEquals(VoiceCommand.Action.FAVORITES,LocalVoiceModel.interpret("coloca aquelas músicas que eu mais gosto").action);
  assertEquals(VoiceCommand.Action.FAVORITES,LocalVoiceModel.interpret("quero escutar minhas preferidas").action);
  assertEquals(VoiceCommand.Action.FAVORITE_ADD,LocalVoiceModel.interpret("guarda essa música nos meus favoritos").action);
  assertEquals(VoiceCommand.Action.FAVORITE_REMOVE,LocalVoiceModel.interpret("tira essa faixa dos meus favoritos").action);
  assertEquals(VoiceCommand.Action.SHUFFLE_ON,LocalVoiceModel.interpret("mistura a ordem das minhas músicas").action);
  assertEquals(VoiceCommand.Action.NEXT,LocalVoiceModel.interpret("passa para a próxima faixa").action);
  assertEquals(VoiceCommand.Action.PREVIOUS,LocalVoiceModel.interpret("volta para a música de antes").action);
 }
 @Test public void keepsTitlesSearchesAndNegationsFromTriggeringActions(){
  for(String phrase:new String[]{"Chitãozinho e Xororó","João Gomes","música para dormir","não quero ouvir minhas favoritas","não toca as favoritas","não quero pausar a música","pesquise favoritas","Onda, pesquise minhas favoritas, por favor"})assertEquals(phrase,VoiceCommand.Action.SEARCH,LocalVoiceModel.interpret(phrase).action);
  assertEquals("Chitãozinho e Xororó",LocalVoiceModel.interpret("toque Chitãozinho e Xororó").query);
  assertEquals(30,LocalVoiceModel.interpret("pare em 30 minutos").minutes);
 }
}
