package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
import java.io.*;
public class DownloadFailureTest {
 static class SignInConfirmNotBotException extends IOException {}
 @Test public void distinguishesDownloadFromConversion(){IOException e=new IOException("HTTP 403");assertTrue(DownloadFailure.describe("Download",e).startsWith("Download:"));assertTrue(DownloadFailure.describe("Conversão para MP3",e).startsWith("Conversão para MP3:"));}
 @Test public void preservesCauseWithoutPrivateUrls(){String text=DownloadFailure.describe("Gravação",new IOException("Falha",new SecurityException("Sem acesso content://provider/private/secret https://cdn.test/audio?signature=secret")));assertTrue(text.contains("Sem acesso"));assertFalse(text.contains("signature"));assertFalse(text.contains("provider"));}
 @Test public void explainsBotChallenge(){String text=DownloadFailure.describe("Análise",new IOException(new SignInConfirmNotBotException()));assertTrue(text.contains("não é um robô"));}
}
