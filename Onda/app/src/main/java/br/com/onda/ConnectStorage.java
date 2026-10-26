package br.com.onda;
import android.content.Context;
import android.net.Uri;
import android.provider.DocumentsContract;
import java.io.*;
@androidx.media3.common.util.UnstableApi
final class ConnectStorage {
 static final class StoredTarget implements ConnectSession.Target {
  final Context context;final Uri uri;final ConnectProtocol.FileInfo info;final OutputStream output;
  StoredTarget(Context context,Uri uri,ConnectProtocol.FileInfo info,OutputStream output){this.context=context;this.uri=uri;this.info=info;this.output=output;}
  public OutputStream stream(){return output;}
  public void abort(){try{DocumentsContract.deleteDocument(context.getContentResolver(),uri);}catch(Exception ignored){}}
  public void commit(){String type=info.mime.startsWith("audio/")?"audio":info.mime.startsWith("video/")?"video":"pdf";if(type.equals("audio"))DownloadedAudio.remember(context,uri.toString(),info.name,info.mime);ShelfStore.remember(context,type,uri.toString(),info.name,0,0);}
 }
 static StoredTarget create(Context context,Uri tree,ConnectProtocol.FileInfo info)throws Exception{Uri parent=DocumentsContract.buildDocumentUriUsingTree(tree,DocumentsContract.getTreeDocumentId(tree));Uri uri=DocumentsContract.createDocument(context.getContentResolver(),parent,info.mime,info.name);if(uri==null)throw new IOException();try{OutputStream output=context.getContentResolver().openOutputStream(uri,"w");if(output==null)throw new IOException();return new StoredTarget(context,uri,info,output);}catch(Exception e){try{DocumentsContract.deleteDocument(context.getContentResolver(),uri);}catch(Exception ignored){}throw e;}}
}
