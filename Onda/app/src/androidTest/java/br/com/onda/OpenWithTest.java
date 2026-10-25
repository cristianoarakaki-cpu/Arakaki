package br.com.onda;
import android.content.*;
import android.content.pm.ResolveInfo;
import android.net.Uri;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
public class OpenWithTest {
 private void resolves(String mime,String target){Context c=getInstrumentation().getTargetContext();for(String scheme:new String[]{"content","file"}){Intent intent=new Intent(Intent.ACTION_VIEW).addCategory(Intent.CATEGORY_DEFAULT).setDataAndType(Uri.parse(scheme.equals("content")?"content://fixture/document/123":"file:///sdcard/Download/example"),mime).setPackage(c.getPackageName());java.util.List<ResolveInfo> found=c.getPackageManager().queryIntentActivities(intent,0);assertEquals(mime+" "+scheme,1,found.size());assertEquals("br.com.onda."+target,found.get(0).activityInfo.name);}}
 @Test public void audioFileAssociations(){for(String mime:new String[]{"audio/mpeg","audio/mp4","audio/flac","audio/ogg","application/ogg"})resolves(mime,"MainActivity");}
 @Test public void videoFileAssociations(){for(String mime:new String[]{"video/mp4","video/x-matroska","application/x-matroska"})resolves(mime,"VideoActivity");}
 @Test public void pdfAssociationDoesNotCaptureOtherDocuments(){resolves("application/pdf","PdfActivity");resolves("application/x-pdf","PdfActivity");Context c=getInstrumentation().getTargetContext();for(String mime:new String[]{"image/jpeg","application/zip","application/octet-stream"})assertTrue(c.getPackageManager().queryIntentActivities(new Intent(Intent.ACTION_VIEW).setDataAndType(Uri.parse("content://fixture/document/123"),mime).setPackage(c.getPackageName()),0).isEmpty());}
}
