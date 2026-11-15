package br.com.arakaki.codigolivre;
import java.sql.*;
import java.nio.file.*;
import java.security.*;
import java.util.*;
import java.io.*;
public class SqliteSummaryTest {
 static int passed;
 static void check(boolean ok,String label){if(!ok)throw new AssertionError(label);System.out.println("OK "+(++passed)+" "+label);}
 interface Task{void run()throws Exception;}
 static void rejects(Task task,String label)throws Exception{boolean failed=false;try{task.run();}catch(Exception e){failed=true;}check(failed,label);}
 static byte[] hash(Path p)throws Exception{return MessageDigest.getInstance("SHA-256").digest(Files.readAllBytes(p));}
 static SqliteSummary.Reader reader(Connection connection){return (sql,max)->{List<List<String>> rows=new ArrayList<>();try(Statement st=connection.createStatement();ResultSet r=st.executeQuery(sql)){while(r.next()&&rows.size()<max){List<String> row=new ArrayList<>();for(int i=1;i<=r.getMetaData().getColumnCount();i++){String v=r.getString(i);row.add(v==null?"[NULL]":v);}rows.add(row);}}return rows;};}
 public static void main(String[]args)throws Exception{
  Class.forName("org.sqlite.JDBC");Path file=Files.createTempFile("codigolivre-",".sqlite");
  try{
   try(Connection c=DriverManager.getConnection("jdbc:sqlite:"+file);Statement s=c.createStatement()){
    s.execute("PRAGMA journal_mode=DELETE");
    s.execute("CREATE TABLE servidores(id INTEGER PRIMARY KEY, nome TEXT NOT NULL, valor REAL, anexo BLOB)");
    s.execute("INSERT INTO servidores VALUES(2,'Ana Paula',15.5,x'123456'),(1,'Cristiano',NULL,NULL),(10,'Décimo',0,NULL),(3,'Texto longo '||printf('%0300d',1),0,NULL)");
    s.execute("CREATE TABLE \"ser\"\"vidores\"(nome TEXT PRIMARY KEY) WITHOUT ROWID");s.execute("INSERT INTO \"ser\"\"vidores\" VALUES('nome seguro')");
    s.execute("CREATE TABLE composta(a INT, b INT, valor TEXT,PRIMARY KEY(a,b)) WITHOUT ROWID");s.execute("INSERT INTO composta VALUES(2,1,'segundo'),(1,3,'primeiro')");
    s.execute("CREATE TABLE vazia(id INTEGER)");s.execute("CREATE VIEW vista AS SELECT * FROM servidores");
   }
   byte[] before=hash(file);SqliteSummary.checkHeader(Arrays.copyOf(Files.readAllBytes(file),100));check(true,"Cabeçalho SQLite independente aceito");
   try(Connection c=DriverManager.getConnection("jdbc:sqlite:file:"+file+"?mode=ro")){
    SqliteSummary.Reader r=reader(c);String text=SqliteSummary.summarize(r,new DataFiles.Options("servidores",1,2));
    check(text.contains("TABELA: servidores | registros: 4 | colunas: 4"),"Contagem real e esquema de tabela");
    check(text.contains("Registro 1: id=1 | nome=Cristiano")&&text.contains("Registro 2: id=2 | nome=Ana Paula"),"Amostra ordenada pela chave primária");
    check(text.contains("valor=[NULL]")&&text.contains("[BLOB omitido]"),"NULL e BLOB explícitos");
    check(text.contains("quick_check(1)=ok"),"Verificação estrutural SQLite executada");
    check(text.contains("NOT NULL=1")&&text.contains("DDL"),"Restrições e DDL na prévia");
    String page=SqliteSummary.summarize(r,new DataFiles.Options("servidores",3,1));check(!page.contains("nome=Ana Paula")&&page.contains("Registro 3:")&&page.contains("célula abreviada"),"Paginação e limite por célula");
    String fourth=SqliteSummary.summarize(r,new DataFiles.Options("servidores",4,1));check(fourth.contains("id=10"),"Ordenação numérica da PK preservada apesar de prévia textual");
    String escaped=SqliteSummary.summarize(r,new DataFiles.Options("ser\"vidores",1,1));check(escaped.contains("nome seguro"),"Nome com aspas citado corretamente");
    String composite=SqliteSummary.summarize(r,new DataFiles.Options("composta",1,1));check(composite.contains("valor=primeiro"),"WITHOUT ROWID e PK composta");
    String all=SqliteSummary.summarize(r,new DataFiles.Options("",1,1));check(all.contains("Tabelas de usuário: 4")&&all.contains("Tabelas incluídas: 3 de 4")&&!all.contains("TABELA: vista"),"Limite de 3 tabelas, views fora da análise");
    String empty=SqliteSummary.summarize(r,new DataFiles.Options("vazia",1,8));check(empty.contains("registros: 0")&&empty.contains("Registros incluídos da tabela: 0"),"Tabela vazia");
    rejects(()->SqliteSummary.summarize(r,new DataFiles.Options("ausente",1,1)),"Tabela inexistente recusada");
    rejects(()->SqliteSummary.summarize(r,new DataFiles.Options("servidores\"; DROP TABLE servidores; --",1,1)),"Texto de filtro não vira SQL executável");
    rejects(()->{try(Statement s=c.createStatement()){s.execute("INSERT INTO servidores(id,nome) VALUES(99,'não permitido')");}},"Driver de teste realmente aberto somente leitura");
   }
   check(Arrays.equals(before,hash(file)),"Hash do banco original preservado após todas as consultas");
   byte[] header=Arrays.copyOf(Files.readAllBytes(file),100);header[18]=2;header[19]=2;rejects(()->SqliteSummary.checkHeader(header),"Banco WAL sem auxiliares recusado");
   rejects(()->SqliteSummary.checkHeader(new byte[100]),"Arquivo não SQLite recusado");
   rejects(()->SqliteSummary.checkHeader(new byte[10]),"Cabeçalho truncado recusado");
   SqliteSummary.Reader tooMany=(sql,max)->{if(sql.startsWith("PRAGMA quick_check"))return Arrays.asList(Arrays.asList("ok"));List<List<String>> rows=new ArrayList<>();for(int i=0;i<201;i++)rows.add(Arrays.asList("t"+i,"CREATE TABLE t(x)"));return rows;};rejects(()->SqliteSummary.summarize(tooMany,new DataFiles.Options("",1,1)),"Bancos com mais de 200 tabelas recusados");
   System.out.println(passed+" testes SQLite passaram (JDBC Linux; adaptador Android requer teste no aparelho).");
  }finally{Files.deleteIfExists(file);}
 }
}
