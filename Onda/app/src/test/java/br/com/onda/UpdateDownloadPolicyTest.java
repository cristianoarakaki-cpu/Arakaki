package br.com.onda;
import java.io.IOException;import org.junit.Test;import static org.junit.Assert.*;
public class UpdateDownloadPolicyTest {
 @Test public void translationApkAboveLegacyLimitFitsNewUpdater()throws Exception{UpdateDownloadPolicy.checkSpace(81L*1024*1024,200L*1024*1024);UpdateDownloadPolicy.checkSize(256L*1024*1024);UpdateDownloadPolicy.checkSpace(-1,200L*1024*1024);}
 @Test public void oversizedStreamAndTooLittleSpaceRemainBlocked()throws Exception{try{UpdateDownloadPolicy.checkSize(256L*1024*1024+1);fail();}catch(IOException expected){}try{UpdateDownloadPolicy.checkSpace(81L*1024*1024,90L*1024*1024);fail();}catch(IOException expected){assertTrue(expected.getMessage().contains("Espaço"));}try{UpdateDownloadPolicy.checkSpace(Long.MAX_VALUE,Long.MAX_VALUE);fail();}catch(IOException expected){}}
}
