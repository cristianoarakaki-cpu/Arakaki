package br.com.arakaki.codigolivre;
import java.io.*;
import java.nio.charset.*;
import java.util.*;
import java.util.zip.*;
public class CodeFilesTest {
 static int passed;
 static void check(boolean ok,String label){if(!ok)throw new AssertionError(label);System.out.println("OK "+(++passed)+" "+label);}
 static byte[] zip(String... pairs)throws Exception{ByteArrayOutputStream out=new ByteArrayOutputStream();try(ZipOutputStream z=new ZipOutputStream(out)){for(int i=0;i<pairs.length;i+=2){z.putNextEntry(new ZipEntry(pairs[i]));z.write(pairs[i+1].getBytes(StandardCharsets.UTF_8));z.closeEntry();}}return out.toByteArray();}
 static String load(byte[] bytes,String name)throws Exception{return CodeFiles.importCode(new ByteArrayInputStream(bytes),name);}
 static void rejects(byte[] bytes,String name,String label)throws Exception{boolean failed=false;try{load(bytes,name);}catch(IOException e){failed=true;}check(failed,label);}
 public static void main(String[]args)throws Exception{
 check(load("print('ação')".getBytes(StandardCharsets.UTF_8),"main.py").contains("ação"),"UTF-8 preservado");
 check(load("' revisão".getBytes(Charset.forName("windows-1252")),"mod.bas").contains("revisão"),"VBA Windows-1252");
 check(load(zip("src/a.py","print(1)","src/b.bas","Option Explicit"),"projeto.zip").contains("src/b.bas"),"ZIP multiarquivo");
 rejects(zip("../fora.py","x"),"projeto.zip","ZIP traversal recusado");
 rejects(zip("C:/fora.py","x"),"projeto.zip","ZIP caminho Windows absoluto recusado");
 rejects(new byte[]{1,0,2},"main.py","binário recusado");
 rejects("abc".getBytes(),"app.apk","APK recusado");
 rejects(new byte[CodeFiles.MAX_BYTES+1],"main.py","limite de tamanho");
 rejects(zip("imagem.png","x"),"projeto.zip","ZIP sem fonte recusado");
 rejects(zip("bin.dat","a".repeat(CodeFiles.MAX_BYTES+1)),"projeto.zip","entrada ignorada também limitada");
 String[] entries=new String[402];for(int i=0;i<201;i++){entries[2*i]="x"+i+".py";entries[2*i+1]="x";}rejects(zip(entries),"projeto.zip","limite de entradas");
 byte[] exported=CodeFiles.exportZip("Análise\n```python\nprint('ação')\n```\n```vba\nOption Explicit\n```\n");
 Map<String,String> result=new HashMap<>();try(ZipInputStream z=new ZipInputStream(new ByteArrayInputStream(exported))){ZipEntry e;while((e=z.getNextEntry())!=null)result.put(e.getName(),new String(CodeFiles.read(z,100000),StandardCharsets.UTF_8));}
 check(result.size()==4,"ZIP inclui relatório e dois blocos");check(result.get("codigo-01.py").contains("ação"),"exportação código Python");check(result.containsKey("codigo-02.bas"),"exportação código VBA");
 check(!CodeFiles.source("arquivo.exe")&&CodeFiles.source("build.gradle"),"extensões permitidas");
 System.out.println(passed+" testes passaram.");
 }
}
