package br.com.onda;
import java.util.*;

/** User-visible diagnostic without signed URLs, private storage URIs or stack dumps. */
final class DownloadFailure {
 static String describe(String stage,Throwable error){String message="Falha não identificada";boolean bot=false;Throwable cause=error;Set<Throwable> seen=Collections.newSetFromMap(new IdentityHashMap<>());for(int i=0;cause!=null&&i<6&&seen.add(cause);i++,cause=cause.getCause()){if(cause instanceof ResilientDownload.Failure){message=cause.getMessage();break;}String type=cause.getClass().getSimpleName();if(type.contains("SignInConfirmNotBot")||type.contains("ReCaptcha"))bot=true;if(cause.getMessage()!=null&&!cause.getMessage().trim().isEmpty())message=cause.getMessage();}if(bot)message="O YouTube exigiu confirmação de que você não é um robô. Tente mais tarde.";message=message.replaceAll("(?i)(?:https?|content|file)://[^\\s]+","[endereço]").replaceAll("/data/(?:user|data)/[^\\s]+","[pasta privada]").replaceAll("[\\r\\n]+"," ").trim();if(message.length()>240)message=message.substring(0,240)+"…";return stage+": "+message;}
}
