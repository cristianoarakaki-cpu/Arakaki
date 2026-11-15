package br.com.arakaki.codigolivre;
import java.util.*;
public class LargeAnalysisTest {
 static int passed;
 static void check(boolean v,String label){if(!v)throw new AssertionError(label);System.out.println("OK "+(++passed)+" "+label);}
 static class Fake implements LargeAnalysis.Engine {
  boolean stopped;int calls,counts,stopAfter,failAfter,density=1;boolean stopInPlan;
  List<String> prompts=new ArrayList<>();
  public int count(String p){counts++;if(stopInPlan&&counts>3)stopped=true;return p.codePointCount(0,p.length())*density+120;}
  public int capacity(){return 8192;}
  public boolean cancelled(){return stopped;}
  public String generate(String p,java.util.function.Consumer<String> partial){calls++;prompts.add(p);check(count(p)<=capacity()-2048,"Prompt real da chamada "+calls+" cabe na etapa");if(failAfter==calls)throw new IllegalStateException("falha simulada");partial.accept("rascunho-"+calls);if(stopAfter==calls)stopped=true;return "resposta-"+calls;}
 }
 static class Recorder implements LargeAnalysis.Progress {
  final List<int[]> stages=new ArrayList<>();
  public void update(String s,String t){}
  public void stage(int completed,int total){stages.add(new int[]{completed,total});}
  int[] last(){return stages.get(stages.size()-1);}
 }
 static void coverage(String source,List<LargeAnalysis.Part> parts,Fake engine){int next=0;StringBuilder rebuilt=new StringBuilder();for(var p:parts){if(p.start!=next||p.end<=p.start)throw new AssertionError("Intervalo incorreto");if(p.end<source.length()&&Character.isHighSurrogate(source.charAt(p.end-1))&&Character.isLowSurrogate(source.charAt(p.end)))throw new AssertionError("Unicode quebrado");if(engine.count(p.prompt)>engine.capacity()-2048-64)throw new AssertionError("Prompt excessivo");rebuilt.append(source,p.start,p.end);next=p.end;}check(rebuilt.toString().equals(source),"Cobertura integral sem buracos, duplicação ou divisão de surrogate");}
 public static void main(String[]args){
  Fake small=new Fake();String direct=LargeAnalysis.run("Analisar","explique","print(1)",small,(s,t)->{});check(small.calls==1&&direct.equals("resposta-1"),"Conteúdo pequeno segue em chamada única");
  String big=("Option Explicit\nSub Exemplo()\n  ' ação 😀\nEnd Sub\n").repeat(1000);
  Fake planner=new Fake();var parts=LargeAnalysis.plan("Analisar",big,planner);check(big.length()>30000&&parts.size()>1,"Pedido acima de 30 mil caracteres é dividido automaticamente");coverage(big,parts,planner);
  Fake dense=new Fake();dense.density=4;coverage(big,LargeAnalysis.plan("Corrigir",big,dense),dense);
  Fake longLine=new Fake();coverage("😀".repeat(20000),LargeAnalysis.plan("Explicar","😀".repeat(20000),longLine),longLine);
  Fake f=new Fake();List<String> progress=new ArrayList<>();String result=LargeAnalysis.run("Analisar","procure falhas",big,f,(s,t)->progress.add(s));check(f.calls>1&&result.contains("Todos os trechos foram enviados")&&result.contains("relações entre trechos"),"Relatórios parciais e conclusão com escopo explícito");check(result.contains("resposta-1")&&result.contains("resposta-"+f.calls),"Respostas inicial e final preservadas");check(progress.stream().anyMatch(s->s.startsWith("Analisando parte")),"Progresso informado por parte");
  Fake cancel=new Fake();cancel.stopAfter=2;String cancelled=LargeAnalysis.run("Corrigir","",big,cancel,(s,t)->{});check(cancel.calls==2&&cancelled.contains("ANÁLISE INCOMPLETA")&&cancelled.contains("1/"),"Interrupção mantém resultados e marca cobertura incompleta");
  Fake planCancel=new Fake();planCancel.stopInPlan=true;String pc=LargeAnalysis.run("Analisar","",big,planCancel,(s,t)->{});check(planCancel.calls==0&&pc.contains("nenhum trecho foi analisado"),"Interrupção durante planejamento");
  Fake failure=new Fake();failure.failAfter=2;String failed=LargeAnalysis.run("Analisar","",big,failure,(s,t)->{});check(failure.calls==2&&failed.contains("resposta-1")&&failed.contains("falha simulada")&&failed.contains("ANÁLISE INCOMPLETA"),"Falha não descarta resultados nem declara análise completa");
  Fake hugeRequest=new Fake();String hr=LargeAnalysis.run("Criar",big,"",hugeRequest,(s,t)->{});check(hugeRequest.calls>1&&hr.contains("Todos os trechos foram enviados"),"Pedido longo no campo de instruções também é coberto");
  Fake sf=new Fake();Recorder sr=new Recorder();LargeAnalysis.run("Analisar","","x",sf,sr);check(sr.stages.size()==2&&sr.stages.get(0)[0]==0&&sr.last()[0]==1&&sr.last()[1]==1,"Etapa única informa início e conclusão reais");
  Fake mf=new Fake();Recorder mr=new Recorder();LargeAnalysis.run("Analisar","",big,mf,mr);boolean ordered=true;int prev=-1;for(int[] st:mr.stages){ordered&=st[0]==prev+1&&st[0]<=st[1];prev=st[0];}check(ordered&&mr.last()[0]==mf.calls&&mr.last()[1]==mf.calls,"Progresso em partes é monotônico e chega a 100% ao concluir");
  Fake cf=new Fake();cf.stopAfter=2;Recorder cr=new Recorder();LargeAnalysis.run("Analisar","",big,cf,cr);check(cr.last()[0]==1&&cr.last()[0]<cr.last()[1],"Cancelamento não informa 100% indevidamente");
  Fake ef=new Fake();ef.failAfter=2;Recorder er=new Recorder();LargeAnalysis.run("Analisar","",big,ef,er);check(er.last()[0]==1&&er.last()[0]<er.last()[1],"Falha mantém percentual das partes realmente finalizadas");
  System.out.println("Testes de análise em partes passaram: "+passed+" verificações.");
 }
}
