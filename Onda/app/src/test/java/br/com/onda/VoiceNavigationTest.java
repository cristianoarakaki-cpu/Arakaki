package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;

public class VoiceNavigationTest {
    @Test public void explicitBrazilianScreenRequestsHaveDeterministicDestinations(){
        assertEquals(VoiceCommand.Action.OPEN_YOUTUBE,VoiceCommand.parse("Onda, abrir o YouTube, por favor").action);
        assertEquals(VoiceCommand.Action.OPEN_IMAGES,VoiceCommand.parse("abra a aba de imagens").action);
        assertEquals(VoiceCommand.Action.OPEN_UPDATES,VoiceCommand.parse("ir para as atualizações").action);
        assertEquals(VoiceCommand.Action.OPEN_RADIOS,VoiceCommand.parse("entrar nas rádios online").action);
        assertEquals(VoiceCommand.Action.OPEN_SOUND,VoiceCommand.parse("quero abrir o estúdio de som").action);
        assertEquals(VoiceCommand.Action.OPEN_PDF,VoiceCommand.parse("acesse o leitor de PDF").action);
        assertEquals(VoiceCommand.Action.OPEN_FILES,VoiceCommand.parse("abrir pastas do Onda").action);
        assertEquals(VoiceCommand.Action.OPEN_CHAPTERS,VoiceCommand.parse("mostrar faixas da coletânea").action);
        assertEquals(VoiceCommand.Action.OPEN_CONVERTER,VoiceCommand.parse("abra conversor").action);
        assertEquals(VoiceCommand.Action.OPEN_QUEUE,VoiceCommand.parse("abrir fila de reprodução").action);
        assertEquals(VoiceCommand.Action.OPEN_PLAYLISTS,VoiceCommand.parse("abrir playlists").action);
        assertEquals(VoiceCommand.Action.OPEN_APPEARANCE,VoiceCommand.parse("abrir aparências").action);
        assertEquals(VoiceCommand.Action.OPEN_VIDEOS,VoiceCommand.parse("abrir vídeos").action);
        assertEquals(VoiceCommand.Action.OPEN_MUSIC,VoiceCommand.parse("abrir músicas").action);
        assertEquals(VoiceCommand.Action.OPEN_DOWNLOADS,VoiceCommand.parse("abrir downloads").action);
        assertEquals(VoiceCommand.Action.OPEN_VOICE_PHRASES,VoiceCommand.parse("abrir minhas frases").action);
    }
    @Test public void searchesTitlesAndDocumentRequestsKeepExistingMeaning(){
        for(String phrase:new String[]{"pesquise abrir YouTube","busque imagens","YouTube","atualizações","não abrir imagens"})
            assertEquals(phrase,VoiceCommand.Action.SEARCH,VoiceCommand.parse(phrase).action);
        assertEquals(VoiceCommand.Action.PLAY_QUERY,VoiceCommand.parse("toque Atualizações").action);
        assertEquals(VoiceCommand.Action.SEARCH,VoiceCommand.parse("abra o PDF contrato").action);
        assertEquals(VoiceCommand.Action.OPEN_IMAGES,LocalVoiceModel.interpret("abra imagens").action);
    }
    @Test public void repeatSelectedChapterPhrasesKeepAllAndOffCommands(){
        for(String phrase:new String[]{"repita esta faixa","repetir só a faixa selecionada","repita a música","repetir a mesma faixa"})
            assertEquals(phrase,VoiceCommand.Action.REPEAT_ONE,VoiceCommand.parse(phrase).action);
        assertEquals(VoiceCommand.Action.REPEAT_ALL,VoiceCommand.parse("repita todas").action);
        assertEquals(VoiceCommand.Action.REPEAT_OFF,VoiceCommand.parse("não repetir").action);
    }
    @Test public void newDestinationAliasesRoundTripAndOlderUserAliasesRetainPriority(){
        VoicePhraseBook book=new VoicePhraseBook("[]");book.put(null,"minhas mensagens bonitas",VoiceCommand.Action.OPEN_IMAGES,"",0);
        assertEquals(VoiceCommand.Action.OPEN_IMAGES,new VoicePhraseBook(book.json()).find("minhas mensagens bonitas").action);
        VoicePhraseBook legacy=new VoicePhraseBook("[{\"id\":\"legacy\",\"phrase\":\"abrir YouTube\",\"action\":\"FAVORITES\",\"query\":\"\",\"minutes\":0}]");
        assertEquals(VoiceCommand.Action.FAVORITES,legacy.find("abrir YouTube").action);
        try{book.put(null,"abrir imagens",VoiceCommand.Action.PAUSE,"",0);fail("New reserved alias should be rejected");}
        catch(IllegalArgumentException expected){}
    }
}
