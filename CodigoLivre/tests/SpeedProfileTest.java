package br.com.arakaki.codigolivre;
import java.util.*;
public class SpeedProfileTest {
 static int passed;
 static void check(boolean ok,String label){if(!ok)throw new AssertionError(label);System.out.println("OK "+(++passed)+" "+label);}
 static class Engine implements LargeAnalysis.Engine {
  final SpeedProfile p;Engine(int index){p=SpeedProfile.of(index);}
  public int count(String s){return s.length()+120;}
  public int capacity(){return p.context;}
  public int responseReserve(){return p.reserve;}
  public boolean cancelled(){return false;}
  public String generate(String s,java.util.function.Consumer<String> callback){if(count(s)>capacity()-responseReserve()-64)throw new AssertionError("Trecho excessivo");return "ok";}
 }
 public static void main(String[]args){
  check(SpeedProfile.of(0).context==3072&&SpeedProfile.of(0).output==768,"Rápido usa contexto e respostas menores");
  check(SpeedProfile.of(1).context==4096&&SpeedProfile.of(1).output==1536,"Equilibrado preserva mais espaço para detalhes");
  check(SpeedProfile.of(2).context==8192&&SpeedProfile.of(2).output==0,"Longo mantém geração até o espaço disponível");
  check(SpeedProfile.of(999).name.equals("Rápido"),"Perfil inválido retorna padrão Rápido");
  String text="function exemplo() { return 1; }\n".repeat(3000);int previousCount=Integer.MAX_VALUE;
  for(int index=0;index<3;index++){
   Engine e=new Engine(index);List<LargeAnalysis.Part> parts=LargeAnalysis.plan("Analisar",text,e);StringBuilder rebuilt=new StringBuilder();int next=0,max=0;
   for(var part:parts){if(part.start!=next||e.count(part.prompt)>e.capacity()-e.responseReserve()-64)throw new AssertionError("Cobertura/limite inválidos");rebuilt.append(text,part.start,part.end);next=part.end;max=Math.max(max,e.count(part.prompt));}
   check(rebuilt.toString().equals(text),"Perfil "+index+": todos os caracteres preservados");
   check(max<=e.capacity()-e.responseReserve()-64,"Perfil "+index+": reserva de saída respeitada");
   check(parts.size()<=previousCount,"Perfil "+index+": ampliar contexto não aumenta quantidade de etapas no caso de teste");previousCount=parts.size();
  }
  check(AssistantModes.modelUrl(false,"1.5").contains("1.5B-Instruct"),"Modelo leve geral disponível");
  check(AssistantModes.modelUrl(true,"1.5").contains("coder-1.5b"),"Modelo leve Coder disponível");
  System.out.println(passed+" verificações de perfis passaram (motor simulado, sem benchmark de celular).");
 }
}
