package br.com.onda;

import android.content.Context;
import android.graphics.*;
import android.graphics.pdf.PdfDocument;
import android.graphics.pdf.PdfRenderer;
import android.net.Uri;
import android.os.ParcelFileDescriptor;
import android.text.*;
import android.util.Xml;
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader;
import com.tom_roush.pdfbox.io.MemoryUsageSetting;
import com.tom_roush.pdfbox.pdmodel.PDDocument;
import com.tom_roush.pdfbox.text.PDFTextStripper;
import org.xmlpull.v1.XmlPullParser;
import java.io.*;
import java.nio.charset.*;
import java.util.*;
import java.util.zip.*;

/** Offline conversions, one image/page at a time. Never opens an original for writing. */
final class DocumentConverter {
 enum Mode {
  IMAGES_PDF("Fotos → PDF","pdf","application/pdf"),
  TEXT_PDF("Texto → PDF","pdf","application/pdf"),
  DOCX_PDF("DOCX (texto) → PDF","pdf","application/pdf"),
  PDF_IMAGES("PDF → imagens PNG (ZIP)","zip","application/zip"),
  PDF_TEXT("PDF → texto TXT","txt","text/plain");
  final String label,extension,mime;
  Mode(String label,String extension,String mime){this.label=label;this.extension=extension;this.mime=mime;}
 }
 interface Progress{void page(int done,int total);}
 static File folder(Context c)throws IOException{File f=new File(c.getCacheDir(),"shares/documents");if(!f.isDirectory()&&!f.mkdirs())throw new IOException("Não foi possível preparar a pasta temporária.");return f;}
 static File convert(Context context,List<Uri> sources,Mode mode,LocalAiModels.Cancel cancel,Progress progress)throws Exception{
  if(sources.isEmpty())throw new IOException("Escolha um arquivo primeiro.");
  File target=new File(folder(context),"Onda-documento-"+UUID.randomUUID()+"."+mode.extension);
  boolean complete=false;
  try{cancel.check();switch(mode){
   case IMAGES_PDF: images(context,sources,target,cancel,progress);break;
   case TEXT_PDF: text(context,sources.get(0),target,false,cancel,progress);break;
   case DOCX_PDF: text(context,sources.get(0),target,true,cancel,progress);break;
   case PDF_IMAGES: pdfImages(context,sources.get(0),target,cancel,progress);break;
   case PDF_TEXT: pdfText(context,sources.get(0),target,cancel,progress);break;
  }cancel.check();if(target.length()==0)throw new IOException("A conversão não produziu um arquivo.");complete=true;return target;
  }finally{if(!complete)target.delete();}
 }
 static InputStream open(Context c,Uri uri)throws IOException{InputStream in=c.getContentResolver().openInputStream(uri);if(in==null)throw new IOException("Arquivo indisponível. Selecione novamente.");return in;}
 static void copy(InputStream in,OutputStream out,LocalAiModels.Cancel cancel)throws IOException{byte[] b=new byte[32768];int n;while((n=in.read(b))!=-1){cancel.check();out.write(b,0,n);}cancel.check();}
 private static File spool(Context c,Uri source,LocalAiModels.Cancel cancel)throws IOException{File f=File.createTempFile("onda-document-source-",".pdf",c.getCacheDir());boolean ok=false;try(InputStream in=open(c,source);OutputStream out=new FileOutputStream(f)){copy(in,out,cancel);ok=true;return f;}finally{if(!ok)f.delete();}}
 private static void images(Context c,List<Uri> sources,File target,LocalAiModels.Cancel cancel,Progress progress)throws Exception{
  PdfDocument pdf=new PdfDocument();try{
   Paint paint=new Paint(Paint.ANTI_ALIAS_FLAG|Paint.FILTER_BITMAP_FLAG);int count=0;
   for(Uri source:sources){cancel.check();Bitmap image=LocalAiPhotos.load(c,source,1600,cancel);PdfDocument.Page page=null;try{
    boolean landscape=image.getWidth()>image.getHeight();int w=landscape?842:595,h=landscape?595:842;
    page=pdf.startPage(new PdfDocument.PageInfo.Builder(w,h,++count).create());Canvas canvas=page.getCanvas();canvas.drawColor(Color.WHITE);
    float scale=Math.min((w-48f)/image.getWidth(),(h-48f)/image.getHeight());float bw=image.getWidth()*scale,bh=image.getHeight()*scale;
    canvas.drawBitmap(image,null,new RectF((w-bw)/2,(h-bh)/2,(w+bw)/2,(h+bh)/2),paint);
   }finally{image.recycle();if(page!=null)pdf.finishPage(page);}progress.page(count,sources.size());}
   cancel.check();try(OutputStream out=new FileOutputStream(target)){pdf.writeTo(out);}
  }finally{pdf.close();}
 }
 /** Text uses Android shaping (including accented scripts), paginated rather than clipped. */
 private static final class TextPdf implements Closeable {
  final PdfDocument pdf=new PdfDocument();final TextPaint paint=new TextPaint(Paint.ANTI_ALIAS_FLAG);final LocalAiModels.Cancel cancel;final Progress progress;
  PdfDocument.Page page;Canvas canvas;int y=40,pages;boolean hasText;
  TextPdf(LocalAiModels.Cancel cancel,Progress progress){this.cancel=cancel;this.progress=progress;paint.setColor(Color.BLACK);paint.setTextSize(12);paint.setTypeface(Typeface.create("sans-serif",Typeface.NORMAL));}
  void newPage(){if(page!=null)pdf.finishPage(page);page=pdf.startPage(new PdfDocument.PageInfo.Builder(595,842,++pages).create());canvas=page.getCanvas();canvas.drawColor(Color.WHITE);y=40;progress.page(pages,0);}
  void add(String text)throws IOException{
   cancel.check();if(!text.trim().isEmpty())hasText=true;
   if(page==null)newPage();
   StaticLayout layout=StaticLayout.Builder.obtain(text,0,text.length(),paint,515).setIncludePad(false).setBreakStrategy(Layout.BREAK_STRATEGY_SIMPLE).setLineSpacing(3,1).build();
   for(int line=0;line<layout.getLineCount();line++){
    cancel.check();int top=layout.getLineTop(line),bottom=layout.getLineBottom(line),height=bottom-top;if(y+height>802)newPage();
    canvas.save();canvas.clipRect(40,y,555,y+height);canvas.translate(40,y-top);layout.draw(canvas);canvas.restore();y+=height;
   }
  }
  void write(File target)throws IOException{cancel.check();if(!hasText)throw new IOException("Nenhum texto legível encontrado neste documento.");if(page!=null){pdf.finishPage(page);page=null;}try(OutputStream out=new FileOutputStream(target)){pdf.writeTo(out);}}
  public void close(){if(page!=null){pdf.finishPage(page);page=null;}pdf.close();}
 }
 private static Reader reader(InputStream stream)throws IOException{
  PushbackInputStream in=new PushbackInputStream(stream,3);byte[] start=new byte[3];int n=0,b;while(n<3&&(b=in.read())!=-1)start[n++]=(byte)b;
  Charset charset=StandardCharsets.UTF_8;int skip=0;
  if(n>=2&&(start[0]&255)==255&&(start[1]&255)==254){charset=StandardCharsets.UTF_16LE;skip=2;}
  else if(n>=2&&(start[0]&255)==254&&(start[1]&255)==255){charset=StandardCharsets.UTF_16BE;skip=2;}
  else if(n==3&&(start[0]&255)==239&&(start[1]&255)==187&&(start[2]&255)==191)skip=3;
  in.unread(start,skip,n-skip);
  return new InputStreamReader(in,charset.newDecoder().onMalformedInput(CodingErrorAction.REPORT).onUnmappableCharacter(CodingErrorAction.REPORT));
 }
 private static void text(Context c,Uri source,File target,boolean docx,LocalAiModels.Cancel cancel,Progress progress)throws Exception{
  try(TextPdf pdf=new TextPdf(cancel,progress);InputStream in=open(c,source)){
   if(docx)docx(in,pdf,cancel);
   else try(Reader reader=reader(in)){char[] block=new char[2048];StringBuilder pending=new StringBuilder();int n;while((n=reader.read(block))!=-1){cancel.check();for(int i=0;i<n;i++){char ch=block[i];if(ch==0||Character.isISOControl(ch)&&ch!='\r'&&ch!='\n'&&ch!='\t'&&ch!='\f')throw new IOException("O arquivo não é texto simples compatível. Escolha TXT, CSV, MD, JSON ou LOG.");if(ch=='\r')continue;if(ch=='\n'){pdf.add(pending.toString());pending.setLength(0);}else{pending.append(ch=='\t'?' ':ch);if(pending.length()>=2048&&!Character.isHighSurrogate(ch)){pdf.add(pending.toString());pending.setLength(0);}}}}if(pending.length()>0)pdf.add(pending.toString());}
   pdf.write(target);
  }catch(CharacterCodingException e){throw new IOException("O texto deve usar UTF-8 ou UTF-16. Exporte-o com essa codificação e tente novamente.",e);}
 }
 private static void docx(InputStream input,TextPdf pdf,LocalAiModels.Cancel cancel)throws Exception{
  try(ZipInputStream zip=new ZipInputStream(input)){
   ZipEntry entry;boolean found=false;
   while((entry=zip.getNextEntry())!=null){cancel.check();if(!entry.getName().equals("word/document.xml")){zip.closeEntry();continue;}found=true;
    XmlPullParser parser=Xml.newPullParser();parser.setFeature(XmlPullParser.FEATURE_PROCESS_NAMESPACES,true);parser.setInput(zip,null);
    StringBuilder paragraph=new StringBuilder();boolean text=false;String ns="http://schemas.openxmlformats.org/wordprocessingml/2006/main";
    for(int event=parser.next();event!=XmlPullParser.END_DOCUMENT;event=parser.next()){
     cancel.check();if(event==XmlPullParser.DOCDECL)throw new IOException("Conteúdo XML não permitido.");
     boolean word=ns.equals(parser.getNamespace());String tag=parser.getName();
     if(event==XmlPullParser.START_TAG&&word){if("t".equals(tag))text=true;else if("tab".equals(tag))paragraph.append(' ');else if("br".equals(tag)){pdf.add(paragraph.toString());paragraph.setLength(0);}}
     else if(event==XmlPullParser.TEXT&&text){String value=parser.getText();for(int i=0;i<value.length();i++){paragraph.append(value.charAt(i));if(paragraph.length()>=2048&&!Character.isHighSurrogate(value.charAt(i))){pdf.add(paragraph.toString());paragraph.setLength(0);}}}
     else if(event==XmlPullParser.END_TAG&&word){if("t".equals(tag))text=false;else if("p".equals(tag)){pdf.add(paragraph.toString());paragraph.setLength(0);}else if("tc".equals(tag))paragraph.append(' ');}
    }
    if(paragraph.length()>0)pdf.add(paragraph.toString());break;
   }
   if(!found)throw new IOException("Escolha um DOCX válido. DOC, XLS e arquivos com senha não são aceitos.");
  }
 }
 private static void pdfImages(Context c,Uri source,File target,LocalAiModels.Cancel cancel,Progress progress)throws Exception{
  File local=spool(c,source,cancel);
  try(ParcelFileDescriptor descriptor=ParcelFileDescriptor.open(local,ParcelFileDescriptor.MODE_READ_ONLY);PdfRenderer renderer=new PdfRenderer(descriptor);ZipOutputStream zip=new ZipOutputStream(new FileOutputStream(target))){
   int count=renderer.getPageCount();if(count==0)throw new IOException("PDF sem páginas.");zip.setLevel(0);
   for(int i=0;i<count;i++){cancel.check();try(PdfRenderer.Page page=renderer.openPage(i)){
    float scale=1600f/Math.max(page.getWidth(),page.getHeight());int w=Math.max(1,Math.round(page.getWidth()*scale)),h=Math.max(1,Math.round(page.getHeight()*scale));
    Bitmap image=Bitmap.createBitmap(w,h,Bitmap.Config.ARGB_8888);try{image.eraseColor(Color.WHITE);page.render(image,null,null,PdfRenderer.Page.RENDER_MODE_FOR_PRINT);cancel.check();zip.putNextEntry(new ZipEntry(String.format(Locale.ROOT,"pagina-%04d.png",i+1)));if(!image.compress(Bitmap.CompressFormat.PNG,100,zip))throw new IOException("Não foi possível gerar a imagem.");zip.closeEntry();}finally{image.recycle();}
   }progress.page(i+1,count);}
  }finally{local.delete();}
 }
 private static void pdfText(Context c,Uri source,File target,LocalAiModels.Cancel cancel,Progress progress)throws Exception{
  File local=spool(c,source,cancel);PDFBoxResourceLoader.init(c.getApplicationContext());final boolean[] hasText={false};
  try(PDDocument doc=PDDocument.load(local,MemoryUsageSetting.setupTempFileOnly().setTempDir(c.getCacheDir()));Writer output=new OutputStreamWriter(new FileOutputStream(target),StandardCharsets.UTF_8)){
   if(!doc.getCurrentAccessPermission().canExtractContent())throw new IOException("O autor deste PDF não permite extrair texto.");
   Writer checked=new Writer(){public void write(char[] chars,int off,int count)throws IOException{cancel.check();for(int i=off;i<off+count;i++)if(!Character.isWhitespace(chars[i]))hasText[0]=true;output.write(chars,off,count);}public void flush()throws IOException{output.flush();}public void close(){}};
   PDFTextStripper stripper=new PDFTextStripper();stripper.setSortByPosition(true);
   for(int i=1;i<=doc.getNumberOfPages();i++){cancel.check();stripper.setStartPage(i);stripper.setEndPage(i);stripper.writeText(doc,checked);progress.page(i,doc.getNumberOfPages());}
   if(!hasText[0])throw new IOException("Este PDF contém imagens ou não tem texto selecionável. Use OCR da página no leitor de PDF.");
  }finally{local.delete();}
 }
}
