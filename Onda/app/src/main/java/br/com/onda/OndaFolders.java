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
 static boolean enabled(Context c){return c.getSharedPreferences(PREF,0).getBoolean("enabled",true)&&!c.getSharedPreferences(PREF,0).getString("tree","").isEmpty();}
 static Uri child(Context c,Uri parent,String name)throws IOException {
  String parentId=DocumentsContract.getDocumentId(parent);Uri children=DocumentsContract.buildChildDocumentsUriUsingTree(parent,parentId);
  try(Cursor cursor=c.getContentResolver().query(children,new String[]{DocumentsContract.Document.COLUMN_DOCUMENT_ID,DocumentsContract.Document.COLUMN_DISPLAY_NAME,DocumentsContract.Document.COLUMN_MIME_TYPE},null,null,null)){int n=0;while(cursor!=null&&cursor.moveToNext()&&n++<10000)if(name.equals(cursor.getString(1))&&DocumentsContract.Document.MIME_TYPE_DIR.equals(cursor.getString(2)))return DocumentsContract.buildDocumentUriUsingTree(parent,cursor.getString(0));}
  catch(RuntimeException e){throw new IOException("Não foi possível consultar a pasta. Escolha a pasta do Onda novamente.",e);}
  try{Uri result=DocumentsContract.createDocument(c.getContentResolver(),parent,DocumentsContract.Document.MIME_TYPE_DIR,name);if(result==null)throw new IOException("Não foi possível criar a pasta "+name);return result;}catch(java.io.FileNotFoundException|RuntimeException e){throw new IOException("Não foi possível criar a pasta "+name,e);}
 }
 static Uri root(Context c,Uri tree)throws IOException{if(!"content".equals(tree.getScheme())||!DocumentsContract.isTreeUri(tree))throw new IOException("Selecione uma pasta pelo Android.");return child(c,DocumentsContract.buildDocumentUriUsingTree(tree,DocumentsContract.getTreeDocumentId(tree)),"Onda");}
 static void configure(Context c,Uri tree)throws IOException{Uri onda=root(c,tree);child(c,onda,"Áudios");child(c,onda,"Vídeos");c.getSharedPreferences(PREF,0).edit().putString("tree",tree.toString()).putBoolean("enabled",true).commit();}
 static Uri directory(Context c,String format)throws IOException{String tree=c.getSharedPreferences(PREF,0).getString("tree","");if(tree.isEmpty())throw new IOException("Escolha a pasta do Onda primeiro.");return child(c,root(c,Uri.parse(tree)),"mp4".equals(format)?"Vídeos":"Áudios");}
 static Uri create(Context c,String format,String title)throws IOException{if(!java.util.Arrays.asList("mp4","mp3","m4a").contains(format))throw new IOException("Formato inválido");try{Uri file=DocumentsContract.createDocument(c.getContentResolver(),directory(c,format),MediaDownloadService.mime(format),DownloadLinks.filename(title)+"."+format);if(file==null)throw new IOException("Não foi possível criar o arquivo na pasta do Onda.");return file;}catch(java.io.FileNotFoundException|RuntimeException e){throw new IOException("Sem acesso à pasta do Onda. Escolha a pasta novamente ou salve em outro local.",e);}}
}
