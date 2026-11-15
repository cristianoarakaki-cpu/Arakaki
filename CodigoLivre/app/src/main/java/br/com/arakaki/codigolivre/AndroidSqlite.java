package br.com.arakaki.codigolivre;

import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import java.io.*;
import java.util.*;

final class AndroidSqlite {
    static String read(InputStream in,File cache,DataFiles.Options options)throws Exception {
        File copy=File.createTempFile("analise-", ".sqlite",cache);
        try {
            try(FileOutputStream out=new FileOutputStream(copy)){
                byte[] header=new byte[100];new DataInputStream(in).readFully(header);SqliteSummary.checkHeader(header);out.write(header);
                byte[] buffer=new byte[32768];long total=100;int n;
                while((n=in.read(buffer))!=-1){total+=n;if(total>32L*1024*1024)throw new IOException("SQLite maior que 32 MiB. Exporte as tabelas de interesse em CSV.");out.write(buffer,0,n);}
            }
            try(SQLiteDatabase db=SQLiteDatabase.openDatabase(copy.getAbsolutePath(),null,SQLiteDatabase.OPEN_READONLY|SQLiteDatabase.NO_LOCALIZED_COLLATORS)){
                return SqliteSummary.summarize((sql,max)->{
                    List<List<String>> rows=new ArrayList<>();
                    try(Cursor c=db.rawQuery(sql,null)){
                        while(c.moveToNext()&&rows.size()<max){List<String> row=new ArrayList<>();for(int i=0;i<c.getColumnCount();i++)row.add(c.isNull(i)?"[NULL]":c.getType(i)==Cursor.FIELD_TYPE_BLOB?"[BLOB omitido]":c.getString(i));rows.add(row);}
                    }return rows;
                },options);
            }
        } finally {
            // Os nomes são gerados pelo app; o arquivo de origem nunca é aberto para escrita.
            copy.delete();new File(copy+"-journal").delete();new File(copy+"-wal").delete();new File(copy+"-shm").delete();
        }
    }
}
