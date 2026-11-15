package br.com.arakaki.codigolivre;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.zip.*;
import javax.xml.parsers.*;
import org.xml.sax.*;
import org.xml.sax.helpers.DefaultHandler;

/** Leitura de dados, sem cálculo de fórmulas ou alterações nos arquivos. */
final class DataFiles {
    static final int MAX_TEXT=2*1024*1024, MAX_PART=8*1024*1024, MAX_PACKAGE=64*1024*1024;
    static final class Options {
        final String section; final int start,rows;
        Options(String section,int start,int rows) {
            this.section=section.trim();this.start=start;this.rows=rows;
            if(start<1||start>100000||rows<1||rows>30)throw new IllegalArgumentException("Linha inicial: 1 a 100000; quantidade: 1 a 30.");
        }
    }
    static final class Report {
        private final StringBuilder text=new StringBuilder(); boolean clipped;
        void add(String s) { if(text.length()+s.length()+1<=5000)text.append(s).append('\n');else clipped=true; }
        @Override public String toString(){return text+(clipped?"\n[Prévia limitada a 5000 caracteres. Há informações não incluídas. Filtre uma aba/tabela e reduza as linhas.]\n":"");}
    }
    static String cell(String s){String v=s.replace("\r","\\r").replace("\n","\\n").replace("\t","\\t");return v.length()>160?v.substring(0,160)+"[célula abreviada]":v;}
    static boolean supported(String name){return name.toLowerCase(Locale.ROOT).matches(".*\\.(xlsx|xlsm|csv|tsv)");}
    static boolean database(String name){return name.toLowerCase(Locale.ROOT).matches(".*\\.(db|sqlite|sqlite3)");}
    static String read(InputStream in,String name,Options options)throws Exception {
        String n=name.toLowerCase(Locale.ROOT);
        if(n.endsWith(".xlsx")||n.endsWith(".xlsm"))return xlsx(in,options);
        if(n.endsWith(".csv")||n.endsWith(".tsv"))return csv(CodeFiles.decode(CodeFiles.read(in,MAX_TEXT)),n.endsWith(".tsv")?'\t':0,options);
        throw new IOException("Formato de dados não suportado.");
    }
    static String csv(String source,char separator,Options o)throws IOException {
        if(separator==0) {
            int semi=0,comma=0,tab=0;boolean quote=false;
            for(int i=0;i<source.length();i++){char c=source.charAt(i);if(c=='"')quote=!quote;else if(!quote){if(c=='\n'||c=='\r')break;if(c==';')semi++;if(c==',')comma++;if(c=='\t')tab++;}}
            separator=tab>semi&&tab>comma?'\t':semi>comma?';':',';
        }
        Report report=new Report();report.add("DADOS CSV/TSV — leitura local, sem alterações.");
        report.add("Amostra de registros lógicos "+o.start+" a "+(o.start+o.rows-1)+". A primeira linha NÃO é presumida como cabeçalho. No máximo 12 campos por registro, 160 caracteres por campo.");
        List<String> fields=new ArrayList<>();StringBuilder value=new StringBuilder();boolean quoted=false,closed=false,record=false;
        int records=0,min=Integer.MAX_VALUE,max=0,mismatch=0,expected=-1;
        for(int i=0;i<=source.length();i++){
            boolean eof=i==source.length();char c=eof?'\n':source.charAt(i);
            if(quoted){if(eof)throw new IOException("CSV inválido: aspas não fechadas.");if(c=='"'){if(i+1<source.length()&&source.charAt(i+1)=='"'){value.append('"');i++;}else{quoted=false;closed=true;}}else value.append(c);continue;}
            if(c=='"'){if(value.length()!=0||closed)throw new IOException("CSV inválido: aspas fora do início do campo.");quoted=true;record=true;continue;}
            if(c==separator||c=='\r'||c=='\n'){
                if(eof&&!record&&value.length()==0&&fields.isEmpty())break;
                fields.add(value.toString());value.setLength(0);closed=false;record=true;
                if(fields.size()>1024)throw new IOException("CSV com mais de 1024 campos por registro.");
                if(c==separator)continue;
                if(c=='\r'&&i+1<source.length()&&source.charAt(i+1)=='\n')i++;
                records++;int columns=fields.size();min=Math.min(min,columns);max=Math.max(max,columns);if(expected<0)expected=columns;else if(columns!=expected)mismatch++;
                if(records>=o.start&&records<o.start+o.rows){StringBuilder row=new StringBuilder("Registro "+records+": ");for(int k=0;k<Math.min(12,columns);k++)row.append(k==0?"":" | ").append(k+1).append('=').append(cell(fields.get(k)));if(columns>12)row.append(" | [demais campos omitidos]");report.add(row.toString());}
                fields.clear();record=false;
            }else{if(closed)throw new IOException("CSV inválido: caracteres após fechamento de aspas.");value.append(c);record=true;}
        }
        report.add("Totais lidos no arquivo: "+records+" registros; campos por registro: "+(records==0?0:min)+" a "+max+"; registros após o primeiro com quantidade diferente: "+mismatch+".");
        report.add("Separador detectado: "+(separator=='\t'?"TAB":Character.toString(separator))+". Linhas fora da amostra não foram enviadas à IA. Números, datas e fórmulas são texto; não foram calculados.");
        if(o.start>records)report.add("A faixa solicitada está além dos registros existentes.");
        return report.toString();
    }
    static void xml(byte[] data,DefaultHandler handler)throws Exception {
        String text=StandardCharsets.UTF_8.newDecoder().decode(java.nio.ByteBuffer.wrap(data)).toString();
        if(text.indexOf('\0')>=0||text.toUpperCase(Locale.ROOT).contains("<!DOCTYPE")||text.toUpperCase(Locale.ROOT).contains("<!ENTITY"))throw new IOException("XML com DTD, entidades ou codificação não suportada.");
        SAXParserFactory f=SAXParserFactory.newInstance();f.setNamespaceAware(true);
        XMLReader reader=f.newSAXParser().getXMLReader();
        reader.setEntityResolver((publicId,systemId)->{throw new SAXException("Referências externas não são permitidas.");});reader.setContentHandler(handler);reader.setErrorHandler(handler);
        reader.parse(new InputSource(new StringReader(text.replaceFirst("^\\uFEFF",""))));
    }
    static String attr(Attributes a,String key){String v=a.getValue(key);return v==null?"":v;}
    static String xlsx(InputStream source,Options o)throws Exception {
        Map<String,byte[]> parts=new HashMap<>();Set<String> seen=new HashSet<>();int total=0,entries=0;
        try(ZipInputStream zip=new ZipInputStream(source)){
            ZipEntry e;while((e=zip.getNextEntry())!=null){
                if(++entries>1000)throw new IOException("Planilha com mais de 1000 partes.");
                String p=e.getName().replace('\\','/');
                if(p.startsWith("/")||p.contains("../")||!seen.add(p))throw new IOException("Pacote XLSX inválido: caminho ou parte duplicada.");
                if(e.isDirectory())continue;
                byte[] b=CodeFiles.read(zip,Math.min(MAX_PART,MAX_PACKAGE-total));total+=b.length;
                if(p.equals("xl/workbook.xml")||p.equals("xl/_rels/workbook.xml.rels")||p.equals("xl/sharedStrings.xml")||p.matches("xl/worksheets/[^/]+\\.xml"))parts.put(p,b);
            }
        }
        if(!parts.containsKey("xl/workbook.xml")||!parts.containsKey("xl/_rels/workbook.xml.rels"))throw new IOException("Não é uma planilha XLSX/XLSM válida; arquivos criptografados não são suportados.");
        Map<String,String> rels=new HashMap<>();
        xml(parts.get("xl/_rels/workbook.xml.rels"),new DefaultHandler(){@Override public void startElement(String u,String l,String q,Attributes a)throws SAXException{
            if(!l.equals("Relationship")||!attr(a,"Type").endsWith("/worksheet"))return;
            if(attr(a,"TargetMode").equals("External"))throw new SAXException("Planilha externa não suportada.");
            String target=attr(a,"Target");String path=target.startsWith("/")?target.substring(1):"xl/"+target;
            if(!path.matches("xl/worksheets/[^/]+\\.xml"))throw new SAXException("Caminho de aba não suportado.");
            rels.put(attr(a,"Id"),path);
        }});
        List<String[]> sheets=new ArrayList<>();
        xml(parts.get("xl/workbook.xml"),new DefaultHandler(){@Override public void startElement(String u,String l,String q,Attributes a)throws SAXException{
            if(l.equals("sheet")){if(sheets.size()>=100)throw new SAXException("Mais de 100 abas.");String id=a.getValue("http://schemas.openxmlformats.org/officeDocument/2006/relationships","id");if(id==null)id=a.getValue("http://purl.oclc.org/ooxml/officeDocument/relationships","id");sheets.add(new String[]{attr(a,"name"),rels.get(id)});}
        }});
        List<String> shared=new ArrayList<>();
        if(parts.containsKey("xl/sharedStrings.xml"))xml(parts.get("xl/sharedStrings.xml"),new DefaultHandler(){StringBuilder item;boolean text;
            @Override public void startElement(String u,String l,String q,Attributes a)throws SAXException{if(l.equals("si")){if(shared.size()>=100000)throw new SAXException("Mais de 100000 textos compartilhados.");item=new StringBuilder();}if(l.equals("t"))text=true;}
            @Override public void characters(char[] c,int s,int n)throws SAXException{if(text&&item!=null){if(item.length()+n>65536)throw new SAXException("Texto de célula muito longo.");item.append(c,s,n);}}
            @Override public void endElement(String u,String l,String q){if(l.equals("t"))text=false;if(l.equals("si")){shared.add(item.toString());item=null;}}
        });
        Report report=new Report();report.add("PLANILHA XLSX/XLSM — prévia somente leitura.");
        report.add("Abas no arquivo: "+sheets.size()+". Nomes: "+cell(String.join(", ",sheets.stream().map(s->s[0]).toArray(String[]::new))));
        report.add("Faixa de linhas Excel: "+o.start+" a "+(o.start+o.rows-1)+"; colunas A a L. Textos abreviados em 160 caracteres. Até 3 abas por importação; use o nome exato da aba para selecionar outra.");
        report.add("Fórmulas NÃO recalculadas. Valores numéricos de datas são números seriais do Excel: estilos/formatação não foram interpretados. Macros VBA, gráficos, imagens e conexões externas NÃO foram analisados.");
        int selected=0;
        for(String[] sheet:sheets){if(!o.section.isEmpty()&&!sheet[0].equalsIgnoreCase(o.section))continue;if(selected>=3)break;selected++;
            if(sheet[1]==null||!parts.containsKey(sheet[1]))throw new IOException("Dados ausentes para a aba "+sheet[0]);
            SheetHandler h=new SheetHandler(shared,o);xml(parts.get(sheet[1]),h);report.add("ABA: "+sheet[0]+" | linhas com células: "+h.rows+" | células: "+h.cells+" | fórmulas: "+h.formulas);
            for(String row:h.sample)report.add(row);
            report.add("Linhas da faixa incluídas: "+h.sample.size()+". Somente a faixa acima dessa aba foi incluída. "+h.omitted+" células da faixa além de L foram omitidas.");
        }
        if(selected==0)throw new IOException("Aba não encontrada: "+o.section);
        report.add("Abas incluídas: "+selected+" de "+sheets.size()+". Linhas e abas fora da seleção não foram enviadas à IA.");return report.toString();
    }
    static final class SheetHandler extends DefaultHandler {
        final List<String> shared,sample=new ArrayList<>();final Options o;
        int rows,cells,formulas,rowNumber,sequence,lastColumn,omitted;String reference,type,tag;StringBuilder value,formula,row;boolean inCell,formulaPresent;
        SheetHandler(List<String> shared,Options o){this.shared=shared;this.o=o;}
        boolean selected(){return rowNumber>=o.start&&rowNumber<o.start+o.rows;}
        @Override public void startElement(String u,String l,String q,Attributes a)throws SAXException{
            if(l.equals("row")){try{rowNumber=attr(a,"r").isEmpty()?++sequence:Integer.parseInt(attr(a,"r"));sequence=rowNumber;if(rowNumber<1||rowNumber>1048576)throw new NumberFormatException();}catch(NumberFormatException e){throw new SAXException("Número de linha inválido.");}row=new StringBuilder("Linha "+rowNumber+": ");lastColumn=0;}
            if(l.equals("c")){if(row==null)throw new SAXException("Célula fora de linha.");cells++;reference=attr(a,"r");type=attr(a,"t");value=new StringBuilder();formula=new StringBuilder();formulaPresent=false;inCell=true;}
            if(inCell&&(l.equals("v")||l.equals("t")||l.equals("f"))){tag=l;if(l.equals("f")){formulas++;formulaPresent=true;}}
        }
        @Override public void characters(char[] c,int s,int n)throws SAXException {if(inCell&&tag!=null){StringBuilder b=tag.equals("f")?formula:value;if(b.length()+n>65536)throw new SAXException("Célula maior que 65536 caracteres.");b.append(c,s,n);}}
        @Override public void endElement(String u,String l,String q)throws SAXException{
            if(l.equals("v")||l.equals("t")||l.equals("f"))tag=null;
            if(l.equals("c")){
                int column=0;for(int k=0;k<reference.length()&&Character.isLetter(reference.charAt(k));k++){column=column*26+Character.toUpperCase(reference.charAt(k))-'A'+1;if(column>16384)throw new SAXException("Coluna inválida.");}if(column==0)column=lastColumn+1;lastColumn=column;
                String text=value.toString();if(type.equals("s")){try{int id=Integer.parseInt(text);if(id<0||id>=shared.size())throw new NumberFormatException();text=shared.get(id);}catch(NumberFormatException e){throw new SAXException("Texto compartilhado inválido.");}}
                if(selected()){if(column<=12){row.append(reference.isEmpty()?"col"+column:reference).append('=').append(cell(text));if(formulaPresent)row.append(" [fórmula: ").append(formula.length()>0?cell(formula.toString()):"compartilhada/sem expressão local; não expandida").append("]");if(type.equals("e"))row.append(" [erro Excel]");row.append(" | ");}else omitted++;}inCell=false;
            }
            if(l.equals("row")){if(lastColumn>0){rows++;if(selected())sample.add(row.toString());}row=null;}
        }
    }
}
