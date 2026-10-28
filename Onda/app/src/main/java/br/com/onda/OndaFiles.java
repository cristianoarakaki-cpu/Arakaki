package br.com.onda;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.provider.DocumentsContract;
import java.util.*;
final class OndaFiles {
 static final class Item {final Uri uri;final String name,mime;final long size,date;final boolean folder;Item(Uri u,String n,String m,long s,long d){uri=u;name=n==null?"Arquivo":n;mime=m==null?"application/octet-stream":m;size=s;date=d;folder=DocumentsContract.Document.MIME_TYPE_DIR.equals(mime);}}
 static List<Item> list(Context c,Uri directory)throws java.io.IOException{List<Item> out=new ArrayList<>();Uri children=DocumentsContract.buildChildDocumentsUriUsingTree(directory,DocumentsContract.getDocumentId(directory));try(Cursor cursor=c.getContentResolver().query(children,new String[]{DocumentsContract.Document.COLUMN_DOCUMENT_ID,DocumentsContract.Document.COLUMN_DISPLAY_NAME,DocumentsContract.Document.COLUMN_MIME_TYPE,DocumentsContract.Document.COLUMN_SIZE,DocumentsContract.Document.COLUMN_LAST_MODIFIED},null,null,null)){while(cursor!=null&&cursor.moveToNext()&&out.size()<1000)out.add(new Item(DocumentsContract.buildDocumentUriUsingTree(directory,cursor.getString(0)),cursor.getString(1),cursor.getString(2),cursor.isNull(3)?-1:cursor.getLong(3),cursor.isNull(4)?0:cursor.getLong(4)));}catch(RuntimeException e){throw new java.io.IOException("Sem acesso à pasta. Configure a pasta do Onda na Central novamente.",e);}return out;}
 static Comparator<Item> order(int sort){Comparator<Item> names=Comparator.comparing((Item i)->SearchText.normalize(i.name)).thenComparing(i->i.uri.toString());Comparator<Item> files=sort==1?Comparator.comparingLong((Item i)->-i.date).thenComparing(names):sort==2?Comparator.comparingLong((Item i)->i.size<0?Long.MAX_VALUE:-i.size).thenComparing(names):names;return Comparator.comparing((Item i)->!i.folder).thenComparing(files);}
}
