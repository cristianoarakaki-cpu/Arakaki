package br.com.arakaki.codigolivre;
import java.io.*;
import java.nio.charset.*;
import java.util.*;
import java.util.zip.*;
public class DataFilesTest {
 static int passed;
 static void check(boolean ok,String label){if(!ok)throw new AssertionError(label);System.out.println("OK "+(++passed)+" "+label);}
 interface Task {void run()throws Exception;}
 static void rejects(Task t,String label)throws Exception {boolean failed=false;try{t.run();}catch(Exception e){failed=true;}check(failed,label);}
 static DataFiles.Options o(String s,int start,int rows){return new DataFiles.Options(s,start,rows);}
 static byte[] zip(Map<String,String> parts)throws Exception{ByteArrayOutputStream out=new ByteArrayOutputStream();try(ZipOutputStream z=new ZipOutputStream(out)){for(var e:parts.entrySet()){z.putNextEntry(new ZipEntry(e.getKey()));z.write(e.getValue().getBytes(StandardCharsets.UTF_8));z.closeEntry();}}return out.toByteArray();}
 static Map<String,String> book(){
  Map<String,String> p=new LinkedHashMap<>();
  p.put("xl/workbook.xml","<workbook xmlns='http://schemas.openxmlformats.org/spreadsheetml/2006/main' xmlns:r='http://schemas.openxmlformats.org/officeDocument/2006/relationships'><sheets><sheet name='Férias' r:id='s1'/><sheet name='Resumo' r:id='s2'/></sheets></workbook>");
  p.put("xl/_rels/workbook.xml.rels","<Relationships xmlns='http://schemas.openxmlformats.org/package/2006/relationships'><Relationship Id='s1' Type='http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet' Target='worksheets/sheet1.xml'/><Relationship Id='s2' Type='http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet' Target='worksheets/sheet2.xml'/></Relationships>");
  p.put("xl/sharedStrings.xml","<sst><si><t>Servidor</t></si><si><r><t>Ana </t></r><r><t>Paula</t></r></si></sst>");
  p.put("xl/worksheets/sheet1.xml","<worksheet><sheetData><row r='1'><c r='A1' t='s'><v>0</v></c><c r='B1' t='inlineStr'><is><t>Data</t></is></c></row><row r='2'><c r='A2' t='s'><v>1</v></c><c r='B2'><v>46000</v></c><c r='C2'><f>SUM(1,2)</f><v>3</v></c><c r='M2' t='inlineStr'><is><t>Oculto</t></is></c></row><row r='5'><c r='A5' t='e'><v>#VALUE!</v></c></row></sheetData></worksheet>");
  p.put("xl/worksheets/sheet2.xml","<worksheet><sheetData><row r='1'><c r='A1' t='inlineStr'><is><r><t>Texto </t></r><r><t>rico</t></r></is></c></row></sheetData></worksheet>");return p;
 }
 static String x(Map<String,String> parts,DataFiles.Options o)throws Exception{return DataFiles.xlsx(new ByteArrayInputStream(zip(parts)),o);}
 public static void main(String[]args)throws Exception{
  String csv=DataFiles.csv("Nome;Valor\r\n\"Ana; Paula\";\"1,50\"\r\n\"Texto\nmultilinha\";\"aspas \"\"duplas\"\"\"\r\n",(char)0,o("",1,3));
  check(csv.contains("3 registros")&&csv.contains("Separador detectado: ;"),"CSV brasileiro: separador e contagem de registros lógicos");
  check(csv.contains("Ana; Paula")&&csv.contains("Texto\\nmultilinha")&&csv.contains("aspas \"duplas\""),"CSV: aspas escapadas e quebras dentro de campo");
  String ranged=DataFiles.csv("a,b\n1,2\n3,4\n",(char)0,o("",2,1));check(ranged.contains("Registro 2: 1=1 | 2=2")&&!ranged.contains("Registro 1:"),"CSV: seleção por faixa sem inferir cabeçalho");
  check(DataFiles.csv("a\tb\n1\t2",(char)0,o("",1,2)).contains("Separador detectado: TAB"),"TSV detectado");
  check(DataFiles.csv("a,b\n1\n2,3,4",(char)0,o("",1,1)).contains("quantidade diferente: 2"),"CSV irregular: estatística verificada");
  rejects(()->DataFiles.csv("\"sem fim",',',o("",1,1)),"CSV: aspas abertas recusadas");
  rejects(()->DataFiles.csv("\"x\"y",',',o("",1,1)),"CSV malformado após aspas recusado");
  check(DataFiles.csv("",',',o("",1,1)).contains("0 registros"),"CSV vazio");
  check(DataFiles.csv("a,b",',',o("",99,1)).contains("além dos registros"),"CSV: faixa inexistente informada");
  check(DataFiles.csv("a,"+"x".repeat(1000),',',o("",1,1)).contains("célula abreviada"),"Campos longos sinalizados");
  rejects(()->o("",0,8),"Faixa inicial inválida recusada");rejects(()->o("",1,31),"Amostra acima de 30 recusada");
  String all=x(book(),o("",1,8));
  check(all.contains("Abas no arquivo: 2")&&all.contains("ABA: Férias")&&all.contains("ABA: Resumo"),"XLSX: relações e nomes das abas");
  check(all.contains("Servidor")&&all.contains("Ana Paula")&&all.contains("Texto rico"),"XLSX: strings compartilhadas, inline e rich text");
  check(all.contains("linhas com células: 3 | células: 7 | fórmulas: 1"),"XLSX: contagens reais, incluindo células fora da amostra");
  check(all.contains("C2=3 [fórmula: SUM(1,2)]")&&all.contains("NÃO recalculadas"),"XLSX: fórmula e cache sem simular recálculo");
  check(all.contains("B2=46000")&&all.contains("números seriais"),"Datas numéricas não são reinterpretadas incorretamente");
  check(all.contains("#VALUE! [erro Excel]")&&!all.contains("M2=Oculto")&&all.contains("1 células da faixa além de L"),"XLSX: erros e colunas omitidas explícitos");
  var sharedFormula=book();sharedFormula.put("xl/worksheets/sheet2.xml","<worksheet><sheetData><row r='1'><c r='A1'><f t='shared' si='0'/><v>4</v></c></row></sheetData></worksheet>");check(x(sharedFormula,o("Resumo",1,1)).contains("compartilhada/sem expressão local; não expandida"),"Fórmula compartilhada sem expressão não é escondida");
  String one=x(book(),o("fÉrias",2,1));check(one.contains("Linha 2:")&&!one.contains("Linha 1:")&&!one.contains("ABA: Resumo"),"XLSX: filtro exato de aba e linha");
  check(x(book(),o("Férias",100,1)).contains("Linhas da faixa incluídas: 0"),"XLSX: faixa inexistente sinalizada");
  rejects(()->x(book(),o("Inexistente",1,8)),"XLSX: aba inexistente recusada");
  var dtd=book();dtd.put("xl/sharedStrings.xml","<!DOCTYPE sst [<!ENTITY x SYSTEM 'file:///etc/passwd'>]><sst><si><t>&x;</t></si></sst>");rejects(()->x(dtd,o("",1,8)),"XLSX: DTD e entidades externas recusados");
  var bad=book();bad.put("xl/workbook.xml","<workbook>");rejects(()->x(bad,o("",1,8)),"XLSX: XML inválido recusado");
  var external=book();external.put("xl/_rels/workbook.xml.rels",external.get("xl/_rels/workbook.xml.rels").replace("Target='worksheets/sheet1.xml'","TargetMode='External' Target='https://example.invalid/planilha'"));rejects(()->x(external,o("",1,8)),"XLSX: referência externa recusada");
  var traversal=book();traversal.put("../escape","x");rejects(()->x(traversal,o("",1,8)),"XLSX: traversal recusado");
  var bomb=book();bomb.put("xl/media/grande.bin","x".repeat(DataFiles.MAX_PART+1));rejects(()->x(bomb,o("",1,8)),"XLSX: parte descompactada excessiva recusada");
  var invalid=book();invalid.put("xl/sharedStrings.xml","<sst/>");rejects(()->x(invalid,o("",1,8)),"XLSX: índice de string inválido recusado");
  DataFiles.Report r=new DataFiles.Report();for(int i=0;i<100;i++)r.add("A".repeat(200));check(r.toString().length()<5200&&r.toString().contains("Há informações não incluídas"),"Prévia limitada com aviso explícito");
  check(DataFiles.supported("A.XLSM")&&DataFiles.database("dados.sqlite3")&&!DataFiles.supported("dados.accdb"),"Formatos suportados e limites explícitos");
  System.out.println(passed+" testes de dados passaram.");
 }
}
