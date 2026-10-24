package br.com.onda;
import org.junit.Test;
import static org.junit.Assert.*;
import java.io.*;
import java.util.*;
public class BatchDownloadsTest {
 @Test public void preservesOrderAndSkipsFailedItem()throws Exception{List<Integer> files=new ArrayList<>();BatchDownloads.Summary s=BatchDownloads.run(4,i->{if(i==1)throw new IOException("private");files.add(i);},(i,ok)->{},()->{});assertEquals(Arrays.asList(0,2,3),files);assertEquals(3,s.success);assertEquals(1,s.failed);assertEquals(4,s.processed);assertFalse(s.stopped);}
 @Test public void stopsAfterRepeatedFailures()throws Exception{BatchDownloads.Summary s=BatchDownloads.run(100,i->{throw new IOException("blocked");},(i,ok)->{},()->{});assertEquals(3,s.failed);assertEquals(3,s.processed);assertTrue(s.stopped);}
 @Test public void cancellationKeepsCompletedFiles()throws Exception{List<Integer> files=new ArrayList<>();try{BatchDownloads.run(5,files::add,(i,ok)->{},()->{if(files.size()==2)throw new InterruptedIOException();});fail();}catch(InterruptedIOException expected){}assertEquals(Arrays.asList(0,1),files);}
 @Test public void transientTimeoutIsOneFailure()throws Exception{BatchDownloads.Summary s=BatchDownloads.run(2,i->{if(i==0)throw new java.net.SocketTimeoutException();},(i,ok)->{},()->{});assertEquals(1,s.failed);assertEquals(1,s.success);}
}
