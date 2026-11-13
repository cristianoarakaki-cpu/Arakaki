package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
public class TrackIdentityTest {
 @Test public void radioSeparatesArtistAndTitleWithoutGuessingComposer(){TrackIdentity info=TrackIdentity.radio("Rádio Brasil","Chitãozinho e Xororó - Evidências",null);assertEquals("Evidências",info.title);assertEquals("Chitãozinho e Xororó",info.artist);assertEquals("",info.composer);assertTrue(info.details().contains("Compositor: Não informado"));}
 @Test public void stationNameIsNotIdentifiedAsSong(){TrackIdentity info=TrackIdentity.radio("Rádio Brasil","Rádio Brasil","Rádio online • Brasil");assertEquals("",info.title);assertEquals("",info.artist);assertTrue(info.summary().contains("não informou"));}
 @Test public void separateRadioArtistWinsAndUnknownValuesAreAbsent(){TrackIdentity info=TrackIdentity.radio("Radio","Love - Live","Singer");assertEquals("Love - Live",info.title);assertEquals("Singer",info.artist);assertEquals("",TrackIdentity.clean("<unknown>"));assertEquals("Cantor",TrackIdentity.choose("Artista desconhecido","Cantor"));assertEquals("",TrackIdentity.clean(null));}
 @Test public void accentsLongTitlesAndControlsAreHandled(){assertEquals("Canção – Ao vivo",TrackIdentity.radio("Rádio","Cantor – Canção – Ao vivo",null).title);assertEquals("",TrackIdentity.radio("Rádio",null,null).title);assertEquals(500,TrackIdentity.clean("x".repeat(1000)).length());assertEquals("A B",TrackIdentity.clean("A\nB"));}
}
