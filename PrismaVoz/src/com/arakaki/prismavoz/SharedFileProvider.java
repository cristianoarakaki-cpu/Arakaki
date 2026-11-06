package com.arakaki.prismavoz;

import android.content.*;
import android.database.*;
import android.net.Uri;
import android.os.ParcelFileDescriptor;
import android.provider.OpenableColumns;
import java.io.*;

/** Read-only grant for the verified updater APK; no arbitrary exports or writes. */
public final class SharedFileProvider extends ContentProvider {
    @Override public boolean onCreate(){return true;}
    private File resolve(Uri uri)throws IOException{
        if(!(getContext().getPackageName()+".files").equals(uri.getAuthority())||uri.getPathSegments().size()!=1||!"Prisma-update.apk".equals(uri.getLastPathSegment()))throw new FileNotFoundException();
        File root=new File(getContext().getCacheDir(),"exports").getCanonicalFile();
        File apk=new File(root,"Prisma-update.apk").getCanonicalFile();
        if(!root.equals(apk.getParentFile())||!apk.isFile())throw new FileNotFoundException();
        return apk;
    }
    @Override public ParcelFileDescriptor openFile(Uri uri,String mode)throws FileNotFoundException{
        if(!"r".equals(mode))throw new FileNotFoundException();
        try{return ParcelFileDescriptor.open(resolve(uri),ParcelFileDescriptor.MODE_READ_ONLY);}catch(IOException e){throw new FileNotFoundException();}
    }
    @Override public String getType(Uri uri){return "application/vnd.android.package-archive";}
    @Override public Cursor query(Uri uri,String[] projection,String selection,String[] args,String order){
        try{File file=resolve(uri);String[] columns=projection==null?new String[]{OpenableColumns.DISPLAY_NAME,OpenableColumns.SIZE}:projection;MatrixCursor cursor=new MatrixCursor(columns);Object[] values=new Object[columns.length];for(int i=0;i<columns.length;i++)values[i]=OpenableColumns.DISPLAY_NAME.equals(columns[i])?file.getName():OpenableColumns.SIZE.equals(columns[i])?file.length():null;cursor.addRow(values);return cursor;}catch(IOException e){return null;}
    }
    @Override public Uri insert(Uri uri,ContentValues values){throw new UnsupportedOperationException();}
    @Override public int update(Uri uri,ContentValues values,String selection,String[] args){throw new UnsupportedOperationException();}
    @Override public int delete(Uri uri,String selection,String[] args){throw new UnsupportedOperationException();}
}
