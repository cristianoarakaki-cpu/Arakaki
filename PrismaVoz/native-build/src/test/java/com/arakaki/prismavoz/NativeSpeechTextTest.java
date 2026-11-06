package com.arakaki.prismavoz;
import org.junit.Test;
import static org.junit.Assert.*;
import java.util.*;
public class NativeSpeechTextTest {
 @Test public void normalizePreservesMeaning(){
  assertEquals("Uma linha continua aqui.",NativeSpeechText.normalize(" Uma linha\ncontinua aqui. "));
  assertEquals("conectado e bem-vindo.",NativeSpeechText.normalize("co\u00ad\nnectado e bem-\nvindo."));
  assertEquals("R$ 1.234,56 em 06/11/2026.",NativeSpeechText.normalize("R$\u00a01.234,56 em 06/11/2026."));
  assertEquals("Primeiro parágrafo.\n\nOutro parágrafo.",NativeSpeechText.normalize("Primeiro parágrafo.\n\nOutro parágrafo."));
  assertEquals("fi fl ff",NativeSpeechText.normalize("\ufb01 \ufb02 \ufb00"));
 }
 @Test public void chunksKeepUnicodeAndAllWords(){
  for(String text:Arrays.asList("palavra ".repeat(1500),"a".repeat(8000),"😀".repeat(1500),"Frase com fim. ".repeat(250))){
   List<String> chunks=NativeSpeechText.chunks(text);assertTrue(chunks.size()>1);
   assertEquals(text.replaceAll("\\s", ""),String.join("",chunks).replaceAll("\\s", ""));
   for(String part:chunks){assertTrue(part.length()<=700);assertFalse(Character.isHighSurrogate(part.charAt(part.length()-1)));assertFalse(Character.isLowSurrogate(part.charAt(0)));}
  }
 }
 @Test public void emptyAndShortText(){assertTrue(NativeSpeechText.chunks("  ").isEmpty());assertEquals(Collections.singletonList("Texto."),NativeSpeechText.chunks("Texto."));assertEquals(6,NativeSpeechText.letters("Aç 123 字"));}
}
