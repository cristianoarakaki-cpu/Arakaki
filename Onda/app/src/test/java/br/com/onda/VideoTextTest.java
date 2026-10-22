package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
public class VideoTextTest {
 @Test public void findsAccentsAndUnindexedFileExtensions(){assertTrue(VideoText.matches("Férias","Ferias-2026.mkv","ferias 2026"));assertTrue(VideoText.matches("Vídeo antigo","festa.avi","AVI"));assertFalse(VideoText.matches("Passeio","passeio.mp4","aniversario"));}
 @Test public void formatsHoursAndUnknownMetadata(){assertEquals("1:02:03",VideoText.duration(3723000));assertEquals("1:05",VideoText.duration(65000));assertEquals("--:--",VideoText.duration(-1));assertEquals("MKV",VideoText.format("familia.Ferias.mkv"));assertEquals("VÍDEO",VideoText.format("sem_extensao"));}
}
