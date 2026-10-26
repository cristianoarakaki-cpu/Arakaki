package com.folha.pd2;
import android.content.*;import android.database.*;import android.net.Uri;import android.os.ParcelFileDescriptor;import android.provider.OpenableColumns;import java.io.*;
public class LocalFileProvider extends ContentProvider {
 public boolean onCreate(){return true;}
 private File resolve(Uri u)throws FileNotFoundException{String n=u.getLastPathSegment();if(!(getContext().getPackageName()+".files").equals(u.getAuthority())||n==null||!n.matches("[A-Za-z0-9_.-]{1,120}"))throw new FileNotFoundException();File f=new File(new File(getContext().getCacheDir(),"exports"),n);if(!f.isFile())throw new FileNotFoundException();return f;}
 public ParcelFileDescriptor openFile(Uri u,String mode)throws FileNotFoundException{if(!"r".equals(mode))throw new FileNotFoundException();return ParcelFileDescriptor.open(resolve(u),ParcelFileDescriptor.MODE_READ_ONLY);}
 public String getType(Uri u){String p=u.getLastPathSegment();if(p!=null&&p.endsWith(".apk"))return "application/vnd.android.package-archive";if(p!=null&&p.endsWith(".pdf"))return "application/pdf";if(p!=null&&p.endsWith(".jpg"))return "image/jpeg";return "text/plain";}
 public Cursor query(Uri u,String[] projection,String s,String[] args,String order){try{File f=resolve(u);String[] cols=projection==null?new String[]{OpenableColumns.DISPLAY_NAME,OpenableColumns.SIZE}:projection;MatrixCursor c=new MatrixCursor(cols);Object[] row=new Object[cols.length];for(int i=0;i<cols.length;i++)row[i]=OpenableColumns.DISPLAY_NAME.equals(cols[i])?f.getName():OpenableColumns.SIZE.equals(cols[i])?f.length():null;c.addRow(row);return c;}catch(Exception e){return null;}}
 public Uri insert(Uri u,ContentValues v){throw new UnsupportedOperationException();}public int update(Uri u,ContentValues v,String s,String[] a){throw new UnsupportedOperationException();}public int delete(Uri u,String s,String[] a){throw new UnsupportedOperationException();}
}
