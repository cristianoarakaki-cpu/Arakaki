package br.com.onda;
import android.content.*;
import android.database.Cursor;
import android.net.Uri;
import android.provider.DocumentsContract;
import java.io.IOException;

/** User grants a parent once. All new files are created, never opened over an existing name. */
@androidx.media3.common.util.UnstableApi
final class OndaFolders {
 static final String PREF="onda_folders";
 static boolean automatic(Context c){return c.getSharedPreferences(PREF,0).getBoolean("enabled",true);}
 static boolean enabled(Context c){return automatic(c)&&!c.getSharedPreferences(PREF,0).getString("tree","").isEmpty();}
 static Uri child(Context c,Uri parent,String name)throws IOException {
  String parentId=DocumentsContract.getDocumentId(parent);Uri children=DocumentsContract.buildChildDocumentsUriUsingTree(parent,parentId);
  try(Cursor cursor=c.getContentResolver().query(children,new String[]{DocumentsContract.Document.COLUMN_DOCUMENT_ID,DocumentsContract.Document.COLUMN_DISPLAY_NAME,DocumentsContract.Document.COLUMN_MIME_TYPE},null,null,null)){int n=0;while(cursor!=null&&cursor.moveToNext()&&n++<10000)if(name.equals(cursor.getString(1))&&DocumentsContract.Document.MIME_TYPE_DIR.equals(cursor.getString(2)))return DocumentsContract.buildDocumentUriUsingTree(parent,cursor.getString(0));}
  catch(RuntimeException e){throw new IOException("Não foi possível consultar a pasta. Escolha a pasta do Onda novamente.",e);}
  try{Uri result=DocumentsContract.createDocument(c.getContentResolver(),parent,DocumentsContract.Document.MIME_TYPE_DIR,name);if(result==null)throw new IOException("Não foi possível criar a pasta "+name);return result;}catch(java.io.FileNotFoundException|RuntimeException e){throw new IOException("Não foi possível criar a pasta "+name,e);}
 }
 static Uri root(Context c,Uri tree)throws IOException{if(!"content".equals(tree.getScheme())||!DocumentsContract.isTreeUri(tree))throw new IOException("Selecione uma pasta pelo Android.");Uri parent=DocumentsContract.buildDocumentUriUsingTree(tree,DocumentsContract.getTreeDocumentId(tree));try(Cursor cursor=c.getContentResolver().query(parent,new String[]{DocumentsContract.Document.COLUMN_DISPLAY_NAME,DocumentsContract.Document.COLUMN_MIME_TYPE},null,null,null)){if(cursor!=null&&cursor.moveToFirst()&&"Onda".equalsIgnoreCase(cursor.getString(0))&&DocumentsContract.Document.MIME_TYPE_DIR.equals(cursor.getString(1)))return parent;}catch(RuntimeException e){throw new IOException("O acesso à pasta expirou. Autorize a pasta do Onda novamente.",e);}return child(c,parent,"Onda");}
 /** Restore only a tree tied to the last completed download, never guess from other grants. Worker only. */
 static boolean restoreDownloadRoot(Context c){if(!c.getSharedPreferences(PREF,0).getString("tree","").isEmpty())return true;try{String last=c.getSharedPreferences("downloads",0).getString("last_uri","");if(last.isEmpty())return false;Uri file=Uri.parse(last);String id=DocumentsContract.getTreeDocumentId(file);for(UriPermission grant:c.getContentResolver().getPersistedUriPermissions()){Uri tree=grant.getUri();if(grant.isReadPermission()&&grant.isWritePermission()&&DocumentsContract.isTreeUri(tree)&&java.util.Objects.equals(file.getAuthority(),tree.getAuthority())&&id.equals(DocumentsContract.getTreeDocumentId(tree))){configure(c,tree);return true;}}}catch(Exception ignored){}return false;}
 static void configure(Context c,Uri tree)throws IOException{Uri onda=root(c,tree);child(c,onda,"Áudios");child(c,onda,"Vídeos");c.getSharedPreferences(PREF,0).edit().putString("tree",tree.toString()).putBoolean("enabled",true).commit();}
 static Uri directory(Context c,String format)throws IOException{String tree=c.getSharedPreferences(PREF,0).getString("tree","");if(tree.isEmpty())throw new IOException("Escolha a pasta do Onda primeiro.");return child(c,root(c,Uri.parse(tree)),"mp4".equals(format)?"Vídeos":"Áudios");}
 static Uri create(Context c,String format,String title)throws IOException{if(!java.util.Arrays.asList("mp4","mp3","m4a","aac").contains(format))throw new IOException("Formato inválido");try{Uri file=DocumentsContract.createDocument(c.getContentResolver(),directory(c,format),MediaDownloadService.mime(format),DownloadLinks.filename(title)+"."+format);if(file==null)throw new IOException("Não foi possível criar o arquivo na pasta do Onda.");return file;}catch(java.io.FileNotFoundException|RuntimeException e){throw new IOException("Sem acesso à pasta do Onda. Escolha a pasta novamente ou salve em outro local.",e);}}
 static Uri createAudioCopy(Context c,String name,String mime)throws IOException{if(mime==null||!mime.startsWith("audio/"))throw new IOException("Tipo de áudio inválido");try{Uri file=DocumentsContract.createDocument(c.getContentResolver(),directory(c,"mp3"),mime,name);if(file==null)throw new IOException("Não foi possível criar a cópia");return file;}catch(java.io.FileNotFoundException|RuntimeException e){throw new IOException("Sem acesso à pasta de áudios do Onda",e);}}
}
