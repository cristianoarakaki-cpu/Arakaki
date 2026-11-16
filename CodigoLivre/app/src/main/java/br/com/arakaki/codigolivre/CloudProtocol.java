package br.com.arakaki.codigolivre;
import org.json.*;
import java.util.*;
import java.time.*;
import java.time.format.DateTimeFormatter;
final class CloudProtocol {
 enum Provider {
  GEMINI("Gemini","https://generativelanguage.googleapis.com/v1beta/models","https://aistudio.google.com/apikey"),
  GROQ("Groq","https://api.groq.com/openai/v1/models","https://console.groq.com/keys"),
  OPENROUTER("OpenRouter · grátis","https://openrouter.ai/api/v1/models","https://openrouter.ai/settings/keys");
  final String label,modelsUrl,keyUrl;Provider(String label,String modelsUrl,String keyUrl){this.label=label;this.modelsUrl=modelsUrl;this.keyUrl=keyUrl;}
 }
 static final class Model {final String id,label;Model(String id,String label){this.id=id;this.label=label;}}
 static void key(String key){if(!key.matches("[A-Za-z0-9_-]{20,256}"))throw new IllegalArgumentException("Chave inválida. Insira somente no aplicativo, sem espaços.");}
 static void model(Provider p,String id){if(!id.matches("[A-Za-z0-9._:/-]{1,160}")||p==Provider.GEMINI&&id.contains("/")||p==Provider.OPENROUTER&&!(id.endsWith(":free")||id.equals("openrouter/free")))throw new IllegalArgumentException("Modelo não permitido. No OpenRouter use somente modelos :free.");}
 static List<Model> models(Provider p,String json)throws Exception{
  JSONObject root=new JSONObject(json);JSONArray list=root.optJSONArray(p==Provider.GEMINI?"models":"data");List<Model> result=new ArrayList<>();if(list==null)throw new IllegalArgumentException("Catálogo não reconhecido.");
  for(int i=0;i<list.length();i++){
   JSONObject item=list.getJSONObject(i);String id=p==Provider.GEMINI?item.optString("name").replaceFirst("^models/",""):item.optString("id");String lower=id.toLowerCase(Locale.ROOT);
   if(p==Provider.GEMINI){JSONArray methods=item.optJSONArray("supportedGenerationMethods");if(methods==null||!methods.toString().contains("generateContent")||!lower.contains("flash")||lower.matches(".*(image|tts|audio|live|embedding).*"))continue;}
   if(p==Provider.GROQ&&(!lower.matches(".*(llama|qwen|gpt-oss).*" )||lower.matches(".*(guard|whisper|tts|safeguard).*")))continue;
   if(p==Provider.OPENROUTER){JSONObject price=item.optJSONObject("pricing");if(price==null||!zero(price.optString("prompt"))||!zero(price.optString("completion")))continue;}
   try{model(p,id);}catch(Exception ignored){continue;}result.add(new Model(id,item.optString(p==Provider.GEMINI?"displayName":"name",id)));
  }
  result.sort(Comparator.comparing(m->m.id));return result;
 }
 static boolean zero(String value){try{return new java.math.BigDecimal(value).signum()==0;}catch(Exception e){return false;}}
 static String endpoint(Provider p,String id){model(p,id);return switch(p){case GEMINI->"https://generativelanguage.googleapis.com/v1beta/models/"+id+":generateContent";case GROQ->"https://api.groq.com/openai/v1/chat/completions";case OPENROUTER->"https://openrouter.ai/api/v1/chat/completions";};}
 static String body(Provider p,String id,String system,String prompt,int max)throws Exception{
  model(p,id);if(prompt.length()>200000)throw new IllegalArgumentException("Pedido online excede 200 mil caracteres. Divida o material ou use análise local em partes; nada foi descartado.");
  JSONObject body=new JSONObject();
  if(p==Provider.GEMINI){body.put("systemInstruction",new JSONObject().put("parts",new JSONArray().put(new JSONObject().put("text",system))));body.put("contents",new JSONArray().put(new JSONObject().put("role","user").put("parts",new JSONArray().put(new JSONObject().put("text",prompt)))));body.put("generationConfig",new JSONObject().put("maxOutputTokens",max));}
  else{body.put("model",id);body.put("messages",new JSONArray().put(new JSONObject().put("role","system").put("content",system)).put(new JSONObject().put("role","user").put("content",prompt)));body.put("max_tokens",max);body.put("stream",false);}
  return body.toString();
 }
 static String answer(Provider p,String json)throws Exception{
  JSONObject root=new JSONObject(json);StringBuilder text=new StringBuilder();String finish="";
  if(p==Provider.GEMINI){JSONArray candidates=root.optJSONArray("candidates");if(candidates==null||candidates.length()==0)throw new IllegalStateException("O provedor não retornou resposta utilizável.");JSONObject candidate=candidates.getJSONObject(0);finish=candidate.optString("finishReason");JSONObject content=candidate.optJSONObject("content");if(content!=null){JSONArray parts=content.optJSONArray("parts");if(parts!=null)for(int i=0;i<parts.length();i++){JSONObject part=parts.getJSONObject(i);if(!part.optBoolean("thought"))text.append(part.optString("text"));}}}
  else{JSONArray choices=root.optJSONArray("choices");if(choices==null||choices.length()==0)throw new IllegalStateException("O provedor não retornou resposta utilizável.");JSONObject choice=choices.getJSONObject(0);finish=choice.optString("finish_reason");JSONObject message=choice.optJSONObject("message");if(message!=null)text.append(message.optString("content",""));}
  if(text.toString().trim().isEmpty())throw new IllegalStateException("Resposta sem texto visível; pode haver bloqueio ou limite do modelo.");
  if(finish.equals("MAX_TOKENS")||finish.equals("length"))text.append("\n\n[Saída cortada pelo limite desta chamada; pode estar incompleta.]");return text.toString();
 }
 static long retryMillis(String header,long now){
  if(header==null||header.isEmpty())return 60000;
  try{long seconds=Long.parseLong(header.trim());return seconds<=0?1000:seconds>Long.MAX_VALUE/1000?Long.MAX_VALUE:seconds*1000;}catch(Exception ignored){}
  try{return Math.max(1000,ZonedDateTime.parse(header,DateTimeFormatter.RFC_1123_DATE_TIME).toInstant().toEpochMilli()-now);}catch(Exception e){return 60000;}
 }
 static String error(int status){return switch(status){case 401,403->"Chave recusada ou acesso não autorizado. Confira a conta e as permissões.";case 429->"Cota/limite do provedor atingido. Respeitando a espera informada.";case 400->"Pedido recusado: confira tamanho, modelo e formato.";case 404->"Modelo/rota indisponível. Atualize o catálogo.";default->"Serviço indisponível (HTTP "+status+").";};}
}
