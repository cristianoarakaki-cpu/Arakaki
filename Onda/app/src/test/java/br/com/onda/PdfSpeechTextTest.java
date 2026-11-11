package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
public class PdfSpeechTextTest {
 @Test public void preservesLongPortugueseTextAndUnicodeWithoutExceedingEngineLimit(){String text=("Olá, ação e coração! 😊\nUma leitura completa, sem perder palavras. ").repeat(1800);StringBuilder read=new StringBuilder();for(int at=0;at<text.length();){int end=PdfSpeechText.end(text,at,1000);assertTrue(end>at);assertTrue(end-at<=1000);assertFalse(end<text.length()&&Character.isLowSurrogate(text.charAt(end)));read.append(text,at,end);at=end;}assertEquals(text,read.toString());}
 @Test public void unbrokenTextAndSurrogateBoundaryMakeProgress(){String text="a".repeat(999)+"😊"+"b".repeat(4000);assertEquals(999,PdfSpeechText.end(text,0,1000));assertEquals(1999,PdfSpeechText.end(text,999,1000));assertEquals(0,PdfSpeechText.end("",0,1000));}
 @Test public void prefersSentenceOrWhitespaceNearTheEnd(){String text="a".repeat(700)+". "+"b".repeat(600);assertEquals(702,PdfSpeechText.end(text,0,1000));}
}
