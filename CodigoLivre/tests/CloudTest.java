package br.com.arakaki.codigolivre;
import java.util.*;
final class CloudTest {
 static int checks;static void check(boolean v){checks++;if(!v)throw new AssertionError("check "+checks);}
 static class Memory implements CloudRouter.Memory {Map<CloudProtocol.Provider,Long> wait=new HashMap<>(),used=new HashMap<>();public long cooldown(CloudProtocol.Provider p){return wait.getOrDefault(p,0L);}public long lastUsed(CloudProtocol.Provider p){return used.getOrDefault(p,0L);}public void waitUntil(CloudProtocol.Provider p,long t){wait.put(p,t);}public void used(CloudProtocol.Provider p,long t){used.put(p,t);}}
 public static void main(String[] args)throws Exception{
  check(CloudProtocol.retryMillis("120",0)==120000);check(CloudProtocol.retryMillis(null,0)==60000);check(CloudProtocol.retryMillis("Mon, 16 Nov 2026 12:00:00 GMT",0)>0);
  check(CloudProtocol.models(CloudProtocol.Provider.OPENROUTER,"{\"data\":[{\"id\":\"x:free\",\"pricing\":{\"prompt\":\"0\",\"completion\":\"0\"}},{\"id\":\"paid\",\"pricing\":{\"prompt\":\"0\",\"completion\":\"0\"}},{\"id\":\"y:free\",\"pricing\":{\"prompt\":\"1\",\"completion\":\"0\"}}]}").size()==1);
  try{CloudProtocol.model(CloudProtocol.Provider.OPENROUTER,"paid");throw new AssertionError();}catch(IllegalArgumentException ok){checks++;}
  check(CloudProtocol.answer(CloudProtocol.Provider.GEMINI,"{\"candidates\":[{\"content\":{\"parts\":[{\"thought\":true,\"text\":\"secret\"},{\"text\":\"answer\"}]}}]}").equals("answer"));
  check(CloudProtocol.answer(CloudProtocol.Provider.GROQ,"{\"choices\":[{\"message\":{\"content\":\"answer\"},\"finish_reason\":\"length\"}]}").contains("incompleta"));
  try{CloudProtocol.body(CloudProtocol.Provider.GROQ,"llama","sys","x".repeat(200001),1024);throw new AssertionError();}catch(IllegalArgumentException ok){checks++;}
  var a=new CloudRouter.Account(CloudProtocol.Provider.GEMINI,"not-real-key-1234567890","gemini-flash");var b=new CloudRouter.Account(CloudProtocol.Provider.GROQ,"not-real-key-1234567890","llama");var accounts=List.of(a,b);Memory memory=new Memory();List<CloudProtocol.Provider> calls=new ArrayList<>();
  var result=CloudRouter.run(accounts,memory,(account,system,prompt,max)->{calls.add(account.provider);if(account==a)throw new CloudRouter.Failure(429,120000);return "ok";},()->1000L,()->false,s->{},"s","p",100,true);
  check(result.account==b);check(calls.size()==2);check(memory.cooldown(a.provider)==121000);
  calls.clear();CloudRouter.run(accounts,memory,(account,system,prompt,max)->{calls.add(account.provider);return "ok";},()->2000L,()->false,s->{},"s","p",100,true);check(calls.equals(List.of(b.provider)));
  memory.used(b.provider,10000);calls.clear();CloudRouter.run(accounts,memory,(account,system,prompt,max)->{calls.add(account.provider);return "ok";},()->122000L,()->false,s->{},"s","p",100,true);check(calls.equals(List.of(a.provider)));
  calls.clear();try{CloudRouter.run(accounts,new Memory(),(account,system,prompt,max)->{calls.add(account.provider);return "bad";},()->1000L,()->true,s->{},"s","p",100,true);throw new AssertionError();}catch(java.util.concurrent.CancellationException ok){check(calls.isEmpty());}
  calls.clear();try{CloudRouter.run(accounts,new Memory(),(account,system,prompt,max)->{calls.add(account.provider);throw new CloudRouter.Failure(429,1000);},()->1000L,()->false,s->{},"s","p",100,true);throw new AssertionError();}catch(IllegalStateException ok){check(calls.size()==2);check(!ok.getMessage().contains(a.key));}
  check(!CloudProtocol.body(CloudProtocol.Provider.GEMINI,"gemini-flash","s","p",100).contains(a.key));
  System.out.println("CloudTest: "+checks+" verificações passaram (protocolos e alternância simulados; sem chamada real).");
 }
}
