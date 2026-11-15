package br.com.arakaki.codigolivre;

import java.io.*;
import java.util.*;

/** Consultas fixas, sem SQL fornecido pelo usuário; adaptador Android separado. */
final class SqliteSummary {
    interface Reader { List<List<String>> query(String sql,int maxRows)throws Exception; }
    static String quote(String s){return "\""+s.replace("\"","\"\"")+"\"";}
    static String summarize(Reader db,DataFiles.Options o)throws Exception {
        List<List<String>> health=db.query("PRAGMA quick_check(1)",1);
        if(health.isEmpty()||!health.get(0).get(0).equalsIgnoreCase("ok"))throw new IOException("SQLite: a verificação estrutural rápida falhou. Gere uma cópia íntegra antes da análise.");
        List<List<String>> tables=db.query("SELECT name, sql FROM sqlite_master WHERE type='table' AND substr(name,1,7)<>'sqlite_' ORDER BY name LIMIT 201",201);
        if(tables.size()>200)throw new IOException("Banco com mais de 200 tabelas. Exporte as tabelas de interesse em CSV.");
        DataFiles.Report report=new DataFiles.Report();report.add("BANCO SQLITE — leitura de cópia privada, somente leitura.");
        report.add("Tabelas de usuário: "+tables.size()+". Até 3 tabelas por importação; selecione um nome exato para examinar outra.");
        report.add("Nomes: "+DataFiles.cell(String.join(", ",tables.stream().map(t->t.get(0)).toArray(String[]::new))));
        report.add("Amostra: registros "+o.start+" a "+(o.start+o.rows-1)+", até 12 colunas e 160 caracteres por valor. Blobs não incluídos. quick_check(1)=ok (verificação estrutural rápida). Chaves estrangeiras, regras de negócio e integridade lógica não foram verificadas.");
        int selected=0;
        for(List<String> table:tables){String name=table.get(0);if(!o.section.isEmpty()&&!name.equalsIgnoreCase(o.section))continue;if(selected>=3)break;selected++;
            String id=quote(name);
            List<List<String>> columns=db.query("PRAGMA table_info("+id+")",2001);
            if(columns.isEmpty())throw new IOException("Tabela sem colunas acessíveis: "+name);
            String count=db.query("SELECT count(*) FROM "+id,1).get(0).get(0);
            report.add("TABELA: "+name+" | registros: "+count+" | colunas: "+columns.size());
            report.add("DDL (abreviado a 1000 caracteres): "+clip(table.get(1),1000));
            StringBuilder fields=new StringBuilder(),order=new StringBuilder();
            TreeMap<Integer,String> primary=new TreeMap<>();
            for(int i=0;i<columns.size();i++){
                List<String> col=columns.get(i);String key=quote(col.get(1));int pk=Integer.parseInt(col.get(5));if(pk>0)primary.put(pk,id+"."+key);
                if(i>=12)continue;
                if(fields.length()>0)fields.append(',');
                fields.append("CASE WHEN typeof(").append(key).append(")='blob' THEN '[BLOB omitido]' ELSE substr(CAST(").append(key).append(" AS TEXT),1,161) END AS ").append(key);
                report.add("Coluna: "+col.get(1)+" | tipo="+col.get(2)+" | NOT NULL="+col.get(3)+" | PK="+col.get(5));
            }
            // Ordenação estável pela PK; tabelas sem PK usam todas as colunas visíveis.
            for(String pk:primary.values()){if(order.length()>0)order.append(',');order.append(pk);}
            if(order.length()==0)for(int i=0;i<Math.min(12,columns.size());i++){if(order.length()>0)order.append(',');order.append(id).append('.').append(quote(columns.get(i).get(1)));}
            List<List<String>> rows=db.query("SELECT "+fields+" FROM "+id+" ORDER BY "+order+" LIMIT "+o.rows+" OFFSET "+(o.start-1),o.rows);
            for(int i=0;i<rows.size();i++){StringBuilder row=new StringBuilder("Registro "+(o.start+i)+": ");List<String> vals=rows.get(i);for(int c=0;c<vals.size();c++)row.append(c==0?"":" | ").append(columns.get(c).get(1)).append('=').append(DataFiles.cell(vals.get(c)));report.add(row.toString());}
            report.add("Registros incluídos da tabela: "+rows.size()+". Ordenação: "+order+". Outras linhas e colunas não foram enviadas à IA.");
        }
        if(selected==0&&!o.section.isEmpty())throw new IOException("Tabela não encontrada: "+o.section);
        report.add("Tabelas incluídas: "+selected+" de "+tables.size()+". Views, gatilhos, índices e tabelas não selecionadas não foram analisados.");return report.toString();
    }
    static String clip(String s,int n){return s.length()>n?s.substring(0,n)+"[DDL abreviado]":s;}
    static void checkHeader(byte[] header)throws IOException {
        byte[] signature="SQLite format 3\0".getBytes(java.nio.charset.StandardCharsets.US_ASCII);
        if(header.length<100||!Arrays.equals(signature,Arrays.copyOf(header,16)))throw new IOException("Não é um SQLite 3 comum. Bancos criptografados e Access não são suportados.");
        if(header[18]!=1||header[19]!=1)throw new IOException("Banco em modo WAL ou formato não suportado. Gere uma exportação independente com a ferramenta de origem, encerre as conexões e use journal_mode=DELETE na cópia. Não envie apenas o .db de um banco em uso.");
    }
}
