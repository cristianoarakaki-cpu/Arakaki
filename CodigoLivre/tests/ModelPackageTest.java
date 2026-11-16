package br.com.arakaki.codigolivre;
import java.io.*;
import java.nio.file.*;
import java.security.*;
import java.util.*;
final class ModelPackageTest {
 static int checks;static void check(boolean value){checks++;if(!value)throw new AssertionError("check "+checks);}
 interface Work{void run()throws Exception;}static void reject(Work work)throws Exception{try{work.run();throw new AssertionError("expected rejection");}catch(IOException|IllegalArgumentException|org.json.JSONException|java.util.concurrent.CancellationException expected){checks++;}}
 static String hash(byte[] bytes)throws Exception{StringBuilder out=new StringBuilder();for(byte b:MessageDigest.getInstance("SHA-256").digest(bytes))out.append(String.format("%02x",b&255));return out.toString();}
 static String metadata(String revision,String hash,long size){return "{\"sha\":\""+revision+"\",\"siblings\":[{\"rfilename\":\""+ModelPackage.FILE+"\",\"lfs\":{\"sha256\":\""+hash+"\",\"size\":"+size+"}}]}";}
 public static void main(String[] args)throws Exception{
  byte[] data=new byte[4096];new Random(1).nextBytes(data);System.arraycopy(new byte[]{'G','G','U','F'},0,data,0,4);String revision="a".repeat(40),digest=hash(data);ModelPackage.Info info=ModelPackage.parse(metadata(revision,digest,data.length));
  check(info.size==4096);check(info.hash.equals(digest));check(info.url().contains("/resolve/"+revision+"/"));check(info.url().endsWith(ModelPackage.FILE));
  reject(()->ModelPackage.parse(metadata("main",digest,4096)));reject(()->ModelPackage.parse(metadata(revision,"bad",4096)));reject(()->ModelPackage.parse(metadata(revision,digest,0)));reject(()->ModelPackage.parse(metadata(revision,digest,3L*1024*1024*1024)));reject(()->ModelPackage.parse("{\"sha\":\""+revision+"\",\"siblings\":[]}"));
  File file=Files.createTempFile("model-test",".gguf").toFile();try{
   List<Long> progress=new ArrayList<>();ModelPackage.receive(new ByteArrayInputStream(data),file,0,data.length,()->false,progress::add);check(file.length()==data.length);check(progress.get(progress.size()-1)==data.length);ModelPackage.verify(file,info,()->false);checks++;
   Files.write(file.toPath(),Arrays.copyOf(data,1024));ModelPackage.range("bytes 1024-4095/4096",1024,4096);checks++;ModelPackage.receive(new ByteArrayInputStream(Arrays.copyOfRange(data,1024,data.length)),file,1024,data.length,()->false,n->{});ModelPackage.verify(file,info,()->false);check(Arrays.equals(Files.readAllBytes(file.toPath()),data));
   reject(()->ModelPackage.range("bytes 0-4095/4096",1024,4096));reject(()->ModelPackage.range("bytes 1024-4095/8192",1024,4096));reject(()->ModelPackage.range("bytes 1024-2047/4096",1024,4096));reject(()->ModelPackage.range(null,1024,4096));
   byte[] corrupt=data.clone();corrupt[100]++;Files.write(file.toPath(),corrupt);reject(()->ModelPackage.verify(file,info,()->false));corrupt[0]=0;Files.write(file.toPath(),corrupt);reject(()->ModelPackage.verify(file,info,()->false));
   Files.write(file.toPath(),new byte[0]);reject(()->ModelPackage.receive(new ByteArrayInputStream(data),file,1,4096,()->false,n->{}));reject(()->ModelPackage.receive(new ByteArrayInputStream(Arrays.copyOf(data,1024)),file,0,4096,()->false,n->{}));check(file.length()==1024);
   reject(()->ModelPackage.receive(new ByteArrayInputStream(Arrays.copyOf(data,4097)),file,1024,4096,()->false,n->{}));check(file.length()==1024);
   reject(()->ModelPackage.receive(new ByteArrayInputStream(data),file,1024,4096,()->true,n->{}));check(file.length()==1024);
   Files.write(file.toPath(),data);reject(()->ModelPackage.verify(file,info,()->true));
  }finally{file.delete();}
  System.out.println("ModelPackageTest: "+checks+" verificações passaram com metadados e GGUF fictícios; sem download/carregamento real.");
 }
}
