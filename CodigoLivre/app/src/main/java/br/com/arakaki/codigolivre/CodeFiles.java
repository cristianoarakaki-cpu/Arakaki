package br.com.arakaki.codigolivre;
import java.io.*;
import java.nio.*;
import java.nio.charset.*;
import java.util.*;
import java.util.regex.*;
import java.util.zip.*;

final class CodeFiles {
    static final int MAX_BYTES=256*1024;
    static final Set<String> EXT=new HashSet<>(Arrays.asList("java","kt","kts","py","js","ts","tsx","jsx","html","htm","css","scss","json","xml","yaml","yml","md","txt","bas","cls","vbs","vb","sql","ps1","bat","cmd","c","h","cpp","hpp","cs","go","rs","dart","php","rb","sh","swift","r","lua","toml","gradle","properties"));
    static boolean source(String name) {
        String n=name.toLowerCase(Locale.ROOT); int p=n.lastIndexOf('.');
        return EXT.contains(p<0?n:n.substring(p+1));
    }
    static byte[] read(InputStream in,int max) throws IOException {
        ByteArrayOutputStream out=new ByteArrayOutputStream();byte[] b=new byte[8192];int n;
        while((n=in.read(b))!=-1) { if(out.size()+n>max) throw new IOException("Arquivo/projeto excede o limite de leitura de "+max+" bytes. Envie menos arquivos.");out.write(b,0,n); }
        return out.toByteArray();
    }
    static String decode(byte[] b) throws IOException {
        for(byte c:b) if(c==0) throw new IOException("Arquivo binário: envie o código-fonte em texto.");
        try { return StandardCharsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT).decode(ByteBuffer.wrap(b)).toString().replace("\uFEFF",""); }
        catch(CharacterCodingException e) { return Charset.forName("windows-1252").decode(ByteBuffer.wrap(b)).toString(); }
    }
    static String importCode(InputStream in,String name) throws IOException {
        if(!name.toLowerCase(Locale.ROOT).endsWith(".zip")) {
            if(!source(name)) throw new IOException("Formato não suportado. Envie código em texto ou ZIP; ACCDB, APK e EXE não são códigos-fonte.");
            return decode(read(in,MAX_BYTES));
        }
        StringBuilder result=new StringBuilder();int total=0,entries=0,accepted=0;
        try(ZipInputStream zip=new ZipInputStream(in)) {
            ZipEntry entry;
            while((entry=zip.getNextEntry())!=null) {
                if(++entries>200) throw new IOException("ZIP com mais de 200 entradas. Reduza o projeto.");
                String path=entry.getName().replace('\\','/');
                if(path.startsWith("/")||path.matches("^[A-Za-z]:.*")||Arrays.asList(path.split("/")).contains("..")) throw new IOException("Caminho inseguro dentro do ZIP.");
                if(entry.isDirectory()) continue;
                // Todas as entradas são limitadas, inclusive binários ignorados: não inflar ZIP sem limite.
                byte[] b=read(zip,MAX_BYTES-total);total+=b.length;
                if(!source(path)) continue;
                String text=decode(b);result.append("\n--- ARQUIVO: ").append(path).append(" ---\n").append(text).append('\n');accepted++;
            }
        }
        if(accepted==0) throw new IOException("ZIP sem arquivos de código reconhecidos.");
        return result.toString();
    }
    static byte[] exportZip(String answer) throws IOException {
        ByteArrayOutputStream out=new ByteArrayOutputStream();
        try(ZipOutputStream zip=new ZipOutputStream(out)) {
            add(zip,"LEIA-ME.txt","Código gerado por IA local. Revise e teste antes de usar. Nenhum teste de execução foi feito automaticamente.\n");
            add(zip,"resposta-completa.txt",answer);
            Matcher m=Pattern.compile("(?m)^```([a-zA-Z0-9_+.#-]*)[^\\r\\n]*\\r?\\n([\\s\\S]*?)^```[ \\t]*$",Pattern.MULTILINE).matcher(answer);
            int i=0;while(m.find()) {
                String lang=m.group(1).toLowerCase(Locale.ROOT);
                String ext=switch(lang) {case "python"->"py";case "javascript"->"js";case "typescript"->"ts";case "powershell"->"ps1";case "vba"->"bas";case "c++"->"cpp";case "csharp"->"cs";case "kotlin"->"kt";case "bash","shell"->"sh";default->lang;};if(!EXT.contains(ext)) ext="txt";
                add(zip,String.format(Locale.ROOT,"codigo-%02d.%s",++i,ext),m.group(2));
            }
        }return out.toByteArray();
    }
    private static void add(ZipOutputStream zip,String name,String text) throws IOException {
        zip.putNextEntry(new ZipEntry(name));zip.write(text.getBytes(StandardCharsets.UTF_8));zip.closeEntry();
    }
}
