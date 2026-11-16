package br.com.arakaki.codigolivre;
import java.util.*;
import java.util.function.*;
/** Failover respeita Retry-After e não repete um provedor na mesma pergunta. */
final class CloudRouter {
 static final class Account {final CloudProtocol.Provider provider;final String key,model;Account(CloudProtocol.Provider p,String key,String model){this.provider=p;this.key=key;this.model=model;}}
 interface Memory {long cooldown(CloudProtocol.Provider p);long lastUsed(CloudProtocol.Provider p);void waitUntil(CloudProtocol.Provider p,long time);void used(CloudProtocol.Provider p,long time);}
 interface Client {String generate(Account account,String system,String prompt,int max)throws Exception;}
 static final class Failure extends Exception {final int status;final long retry;Failure(int status,long retry){super(CloudProtocol.error(status));this.status=status;this.retry=retry;}}
 static final class Result {final Account account;final String text;Result(Account a,String text){account=a;this.text=text;}}
 static Result run(List<Account> accounts,Memory memory,Client client,LongSupplier clock,BooleanSupplier cancelled,Consumer<String> progress,String system,String prompt,int max,boolean automatic)throws Exception{
  if(accounts.isEmpty())throw new IllegalStateException("Configure ao menos uma chave e um modelo no menu IA online.");
  List<Account> order=new ArrayList<>(accounts);if(automatic)order.sort(Comparator.comparingLong(a->memory.lastUsed(a.provider)));
  List<String> reasons=new ArrayList<>();
  for(Account account:order){if(cancelled.getAsBoolean())throw new java.util.concurrent.CancellationException("Consulta interrompida.");long now=clock.getAsLong();if(memory.cooldown(account.provider)>now){reasons.add(account.provider.label+": aguardando cota");continue;}
   progress.accept("Consultando "+account.provider.label+" · "+account.model+"…");memory.used(account.provider,now);
   try{return new Result(account,client.generate(account,system,prompt,max));}
   catch(Failure e){if(e.status==429){long delay=Math.max(1000,e.retry);long until=delay>Long.MAX_VALUE-now?Long.MAX_VALUE:now+delay;memory.waitUntil(account.provider,until);}else if(e.status==401||e.status==403)memory.waitUntil(account.provider,now+300000);else if(e.status>=500)memory.waitUntil(account.provider,now+30000);
    reasons.add(account.provider.label+": "+e.getMessage());if(!automatic||e.status==400)break;
   }catch(java.io.IOException e){reasons.add(account.provider.label+": falha de conexão");if(!automatic)break;}
  }
  throw new IllegalStateException("Nenhum provedor online respondeu. "+String.join(" | ",reasons)+". O app não garante uso ilimitado; aguarde ou use a IA local.");
 }
}
