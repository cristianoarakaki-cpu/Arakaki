package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
public class TrackSleepTest {
 @Test public void onlyRequestedNaturalEndsFinishTimer(){TrackSleep t=new TrackSleep();assertFalse(t.completed());t.arm(3);assertEquals(3,t.remaining());assertFalse(t.completed());assertFalse(t.completed());assertTrue(t.completed());assertFalse(t.completed());}
 @Test public void cancelAndReplaceDoNotKeepOldCounter(){TrackSleep t=new TrackSleep();t.arm(3);t.completed();t.arm(1);assertTrue(t.completed());t.arm(5);t.arm(0);assertFalse(t.completed());}
 @Test public void spokenRequestsRespectLimitsAndExplicitSearches(){assertEquals(VoiceCommand.Action.SLEEP_TRACKS,VoiceCommand.parse("pare ao terminar esta música").action);assertEquals(3,VoiceCommand.parse("pause após três músicas").minutes);assertEquals(VoiceCommand.Action.INVALID,VoiceCommand.parse("pare após 99 músicas").action);assertEquals(VoiceCommand.Action.SEARCH,VoiceCommand.parse("pesquise pare após três músicas").action);}
}
