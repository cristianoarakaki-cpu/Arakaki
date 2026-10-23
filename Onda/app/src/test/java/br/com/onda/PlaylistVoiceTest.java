package br.com.onda;
import org.junit.Test;
import java.util.*;
import static org.junit.Assert.*;
public class PlaylistVoiceTest {
 @Test public void parsesNamedPlaylistWithoutChangingExplicitSearch(){VoiceCommand c=VoiceCommand.parse("Onda, toque minha playlist Viagem");assertEquals(VoiceCommand.Action.PLAY_PLAYLIST,c.action);assertEquals("Viagem",c.query);assertEquals(VoiceCommand.Action.SEARCH,VoiceCommand.parse("pesquise playlist Viagem").action);assertEquals(VoiceCommand.Action.PLAY_PLAYLIST,LocalVoiceModel.interpret("toque a minha lista Sertanejo").action);}
 @Test public void exactNameHasPriorityAndAccentsAreOptional(){PlaylistStore.Entry a=new PlaylistStore.Entry("a","Viagem"),b=new PlaylistStore.Entry("b","Viagem longa"),c=new PlaylistStore.Entry("c","Sertanejo e modão");List<PlaylistStore.Entry> lists=Arrays.asList(a,b,c);assertEquals(Arrays.asList(a),PlaylistStore.matching(lists,"viagem"));assertEquals(Arrays.asList(c),PlaylistStore.matching(lists,"modao"));assertTrue(PlaylistStore.matching(lists,"").isEmpty());assertTrue(PlaylistStore.matching(lists,"inexistente").isEmpty());}
 @Test public void customPlaylistCommandCarriesTheName(){assertEquals("Treino",VoiceCommand.custom(VoiceCommand.Action.PLAY_PLAYLIST,"Treino",0).query);}
}
