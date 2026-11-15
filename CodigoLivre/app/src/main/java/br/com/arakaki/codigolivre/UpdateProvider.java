package br.com.arakaki.codigolivre;
import android.content.*;
import android.database.*;
import android.net.Uri;
import android.os.*;
import android.provider.OpenableColumns;
import java.io.*;

/** Compartilha somente o APK validado e somente para leitura. */
public final class UpdateProvider extends ContentProvider {
    static final String AUTHORITY="br.com.arakaki.codigolivre.updates";
    static final Uri URI=Uri.parse("content://"+AUTHORITY+"/update.apk");
    static File apk(Context c){return new File(c.getFilesDir(),"updates/update.apk");}
    private void validate(Uri uri){if(!URI.equals(uri))throw new SecurityException("Documento não permitido.");}
    @Override public boolean onCreate(){return true;}
    @Override public String getType(Uri uri){validate(uri);return "application/vnd.android.package-archive";}
    @Override public ParcelFileDescriptor openFile(Uri uri,String mode)throws FileNotFoundException{validate(uri);if(!"r".equals(mode))throw new SecurityException("Apenas leitura.");return ParcelFileDescriptor.open(apk(getContext()),ParcelFileDescriptor.MODE_READ_ONLY);}
    @Override public Cursor query(Uri uri,String[] projection,String selection,String[] args,String order){validate(uri);String[] cols=projection==null?new String[]{OpenableColumns.DISPLAY_NAME,OpenableColumns.SIZE}:projection;MatrixCursor c=new MatrixCursor(cols);Object[] row=new Object[cols.length];for(int i=0;i<cols.length;i++)row[i]=OpenableColumns.DISPLAY_NAME.equals(cols[i])?"CodigoLivre-atualizacao.apk":OpenableColumns.SIZE.equals(cols[i])?apk(getContext()).length():null;c.addRow(row);return c;}
    @Override public Uri insert(Uri u,ContentValues v){throw new UnsupportedOperationException();}
    @Override public int update(Uri u,ContentValues v,String s,String[] a){throw new UnsupportedOperationException();}
    @Override public int delete(Uri u,String s,String[] a){throw new UnsupportedOperationException();}
}
