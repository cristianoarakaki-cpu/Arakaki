package br.com.arakaki.codigolivre;
import java.security.*;
import java.util.*;
public class UpdatePolicyTest {
 static int passed;
 static void check(boolean ok,String label){if(!ok)throw new AssertionError(label);System.out.println("OK "+(++passed)+" "+label);}
 interface Task{void run()throws Exception;}
 static void rejects(Task t,String label){boolean rejected=false;try{t.run();}catch(Exception e){rejected=true;}check(rejected,label);}
 static String url="https://raw.githubusercontent.com/cristianoarakaki-cpu/Arakaki/entrega/codigo-livre-android-offline/entregas/CodigoLivre_0_5_0/CodigoLivre-0.5.0-arm64.apk";
 static UpdatePolicy.Info info(long version,String sha,long size,String pkg){return new UpdatePolicy.Info(version,"0.5.0",url,sha,size,pkg,"Notas");}
 public static void main(String[]args)throws Exception{
  String sha=UpdatePolicy.hex(MessageDigest.getInstance("SHA-256").digest("apk fictício".getBytes(java.nio.charset.StandardCharsets.UTF_8)));
  var i=info(5,sha,100,UpdatePolicy.PACKAGE);check(i.newerThan(4)&&!i.newerThan(5)&&!i.newerThan(6),"Atualização apenas para versão superior");
  check(UpdatePolicy.validDigest(sha,MessageDigest.getInstance("SHA-256").digest("apk fictício".getBytes(java.nio.charset.StandardCharsets.UTF_8))),"Digest correto aceito");check(!UpdatePolicy.validDigest(sha,new byte[32]),"Digest diferente recusado");
  for(String bad:new String[]{"http://raw.githubusercontent.com/cristianoarakaki-cpu/Arakaki/x","https://evil.invalid/cristianoarakaki-cpu/Arakaki/x","https://raw.githubusercontent.com/outro/Arakaki/x","https://raw.githubusercontent.com/cristianoarakaki-cpu/Arakaki/../outro/x","https://user@raw.githubusercontent.com/cristianoarakaki-cpu/Arakaki/x",url+"?x=1",url+"#x","https://raw.githubusercontent.com:8443/cristianoarakaki-cpu/Arakaki/x"})rejects(()->UpdatePolicy.trusted(bad),"URL não autorizada recusada");
  rejects(()->info(5,"falso",100,UpdatePolicy.PACKAGE),"SHA256 malformado recusado");rejects(()->info(5,sha,UpdatePolicy.MAX_APK+1,UpdatePolicy.PACKAGE),"APK excessivo recusado");rejects(()->info(5,sha,0,UpdatePolicy.PACKAGE),"Arquivo vazio recusado");rejects(()->info(5,sha,100,"outro.pacote"),"Pacote diferente recusado");
  check(UpdatePolicy.sameSigners(Arrays.asList("a","b"),Arrays.asList("b","a")),"Ordem dos signatários não altera identidade");check(!UpdatePolicy.sameSigners(Arrays.asList("a"),Arrays.asList("b")),"Assinatura diferente recusada");check(!UpdatePolicy.sameSigners(Collections.emptyList(),Collections.emptyList()),"Assinatura ausente recusada");
  check(AssistantModes.system(6,"técnico").contains("conhecimentos gerais")&&AssistantModes.system(0,"técnico").equals("técnico"),"Modo geral e técnico separados");
  check(!AssistantModes.modelUrl(false,"3").contains("Coder")&&AssistantModes.modelUrl(true,"7").contains("Coder-7B"),"Modelos gerais e Coder têm links distintos");
  rejects(()->AssistantModes.modelUrl(false,"999"),"Modelo desconhecido recusado");
  System.out.println(passed+" verificações de atualização/modos passaram.");
 }
}
