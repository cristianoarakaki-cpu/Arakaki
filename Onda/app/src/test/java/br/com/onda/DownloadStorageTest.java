package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
public class DownloadStorageTest {
 @Test public void capacityUsesLongAndPreservesSystemReserve(){long large=8L*1024*1024*1024;assertTrue(DownloadStorage.fits(large+DownloadStorage.RESERVE,large));assertFalse(DownloadStorage.fits(large+DownloadStorage.RESERVE-1,large));assertFalse(DownloadStorage.fits(DownloadStorage.RESERVE-1,0));assertFalse(DownloadStorage.fits(Long.MAX_VALUE,Long.MAX_VALUE));assertTrue(DownloadStorage.fits(Long.MAX_VALUE,Long.MAX_VALUE-DownloadStorage.RESERVE));}
}
