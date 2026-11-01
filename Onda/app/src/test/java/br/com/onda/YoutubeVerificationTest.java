package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
public class YoutubeVerificationTest {
 @Test public void recognizesOnlyYoutubeRobotDemands(){assertTrue(YoutubeVerification.required("Análise do vídeo: O YouTube exigiu confirmação de que você não é um robô."));assertTrue(YoutubeVerification.required("YouTube: Sign in to confirm you're not a bot"));assertFalse(YoutubeVerification.required("TikTok HTTP 403"));assertFalse(YoutubeVerification.required("YouTube: formato indisponível"));}
 @Test public void recoveryUsesOfficialResourceLinks(){assertEquals("https://m.youtube.com/watch?v=aqz-KE-bpKQ",YoutubeVerification.link("https://youtu.be/aqz-KE-bpKQ"));assertEquals("",YoutubeVerification.link("https://youtube.com.evil.org/watch?v=aqz-KE-bpKQ"));assertEquals("",YoutubeVerification.link("javascript:alert(1)"));}
}
