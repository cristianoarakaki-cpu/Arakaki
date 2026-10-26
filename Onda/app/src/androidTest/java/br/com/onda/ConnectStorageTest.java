package br.com.onda;
import android.content.Context;
import org.junit.Test;
import static org.junit.Assert.*;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
import java.io.*;
import java.util.UUID;
@androidx.media3.common.util.UnstableApi
public class ConnectStorageTest {
 @Test public void selectedAndroidFolderStoresAndIndexesCompletedPdf()throws Exception{Context c=getInstrumentation().getTargetContext();android.net.Uri tree=null;for(android.content.UriPermission permission:c.getContentResolver().getPersistedUriPermissions())if(permission.isWritePermission()&&android.provider.DocumentsContract.isTreeUri(permission.getUri())){tree=permission.getUri();break;}assertNotNull("UI must select a writable Android folder first",tree);android.content.SharedPreferences prefs=c.getSharedPreferences("media_shelf",0);String old=prefs.getString("data",null);ConnectStorage.StoredTarget target=null;try{byte[] bytes="%PDF-Conecta-native".getBytes(java.nio.charset.StandardCharsets.UTF_8);target=ConnectStorage.create(c,tree,new ConnectProtocol.FileInfo("Onda-Conecta-Test-"+UUID.randomUUID()+".pdf","application/pdf",bytes.length));target.stream().write(bytes);target.stream().close();target.commit();try(InputStream input=c.getContentResolver().openInputStream(target.uri)){ByteArrayOutputStream output=new ByteArrayOutputStream();byte[] buffer=new byte[1024];int n;while((n=input.read(buffer))!=-1)output.write(buffer,0,n);assertArrayEquals(bytes,output.toByteArray());}String uri=target.uri.toString();assertTrue(ShelfStore.read(c).items.values().stream().anyMatch(i->i.type.equals("pdf")&&i.uri.equals(uri)));}finally{if(target!=null){try{target.stream().close();}catch(Exception ignored){}target.abort();}android.content.SharedPreferences.Editor edit=prefs.edit();if(old==null)edit.remove("data");else edit.putString("data",old);edit.commit();}}

}
