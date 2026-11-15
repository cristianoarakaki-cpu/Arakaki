package br.com.arakaki.codigolivre;
import java.io.*;
import java.nio.charset.*;
import java.util.*;
import java.time.*;
import java.time.format.DateTimeFormatter;
import javax.xml.parsers.*;
import org.xml.sax.*;
import org.xml.sax.helpers.DefaultHandler;
final class LiveFeeds {
    static final class Item {
        String title="",link="",date="",source="",description="";
        boolean valid(){try{java.net.URI u=java.net.URI.create(link);return !title.isEmpty()&&"https".equals(u.getScheme())&&u.getHost()!=null&&u.getUserInfo()==null;}catch(Exception e){return false;}}
    }
    static List<Item> rss(byte[] bytes)throws Exception{
        String xml=StandardCharsets.UTF_8.newDecoder().decode(java.nio.ByteBuffer.wrap(bytes)).toString();
        String upper=xml.toUpperCase(Locale.ROOT);if(xml.indexOf('\0')>=0||upper.contains("<!DOCTYPE")||upper.contains("<!ENTITY"))throw new IOException("RSS com DTD/entidades recusado.");
        List<Item> items=new ArrayList<>();SAXParserFactory f=SAXParserFactory.newInstance();f.setNamespaceAware(true);XMLReader reader=f.newSAXParser().getXMLReader();
        DefaultHandler h=new DefaultHandler(){Item current;String tag="";StringBuilder value=new StringBuilder();
            @Override public void startElement(String u,String local,String q,Attributes a)throws SAXException{if(local.equals("item")){current=new Item();}if(current!=null){tag=local;value.setLength(0);}}
            @Override public void characters(char[] c,int s,int n)throws SAXException{if(current!=null){if(value.length()+n>65536)throw new SAXException("Campo RSS excessivo.");value.append(c,s,n);}}
            @Override public void endElement(String u,String local,String q)throws SAXException{if(current==null)return;String text=value.toString().trim();if(local.equals(tag))switch(local){case "title":current.title=plain(text,500);break;case "link":current.link=text;break;case "pubDate":current.date=text;break;case "source":current.source=plain(text,120);break;case "description":current.description=plain(text,500);break;default:break;}if(local.equals("item")){if(current.valid())items.add(current);if(items.size()>100)throw new SAXException("RSS com mais de 100 resultados.");current=null;}}
        };
        reader.setContentHandler(h);reader.setErrorHandler(h);reader.setEntityResolver((p,s)->{throw new SAXException("Referência externa recusada.");});reader.parse(new InputSource(new StringReader(xml.replaceFirst("^\\uFEFF",""))));return items;
    }
    static String plain(String text,int max){String s=text.replaceAll("<[^>]*>"," ").replace("&nbsp;"," ").replace("&amp;","&").replace("&quot;","\"").replace("&#39;","'").replaceAll("\\s+"," ").trim();return s.length()>max?s.substring(0,max)+"…":s;}
    static String time(String date){try{return ZonedDateTime.parse(date,DateTimeFormatter.RFC_1123_DATE_TIME).withZoneSameInstant(ZoneId.of("America/Sao_Paulo")).format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm 'Brasília'"));}catch(Exception e){return date;}}
    static final class Match {
        final String id,opponents,competition,url;final Instant when;final boolean timeValid;
        Match(String id,String opponents,String competition,String date,String url,boolean timeValid){this.id=id;this.opponents=opponents;this.competition=competition;this.when=Instant.parse(date);this.url=url;this.timeValid=timeValid;}
    }
    static Match earliest(List<Match> matches,Instant now){return matches.stream().filter(m->m.when.isAfter(now)).min(Comparator.comparing(m->m.when)).orElse(null);}
    static String describe(Match m){String date=m.when.atZone(ZoneId.of("America/Sao_Paulo")).format(DateTimeFormatter.ofPattern(m.timeValid?"dd/MM/yyyy 'às' HH:mm '(Brasília)'":"dd/MM/yyyy '(horário a confirmar)'"));return m.opponents+"\n"+m.competition+"\n"+date+"\nFonte: "+m.url;}
}
