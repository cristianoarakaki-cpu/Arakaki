package br.com.onda;
import android.app.AlertDialog;
import android.content.Context;
import android.net.Uri;
import java.util.*;
/** User-reversible list exclusions, without touching files, favorites or queues. */
final class HiddenMedia {
 static final int LIMIT=200;
 static Set<String> read(Context c,String type){try{return new HashSet<>(c.getSharedPreferences("hidden_media",0).getStringSet(type,Collections.emptySet()));}catch(ClassCastException e){return new HashSet<>();}}
 static boolean local(Uri uri){return uri!=null&&("content".equalsIgnoreCase(uri.getScheme())||"file".equalsIgnoreCase(uri.getScheme()))&&uri.toString().length()<=2048;}
 static synchronized void hide(Context c,String type,Uri uri){if(!local(uri)||!("audio".equals(type)||"video".equals(type)))return;Set<String> values=read(c,type);if(values.contains(uri.toString()))return;if(values.size()>=LIMIT)values.remove(values.iterator().next());values.add(uri.toString());c.getSharedPreferences("hidden_media",0).edit().putStringSet(type,values).apply();}
 static void restore(Context c,String type){c.getSharedPreferences("hidden_media",0).edit().remove(type).apply();}
 static void settings(Context c,Runnable refresh){new AlertDialog.Builder(c).setTitle("Arquivos ocultos das listas").setMessage(read(c,"audio").size()+" áudios • "+read(c,"video").size()+" vídeos\n\nArquivos, favoritos e listas salvas são preservados. Apenas a biblioteca principal e a lista de vídeos são filtradas. Não há varredura de codecs em segundo plano. Até 200 referências por tipo; use Restaurar para tentar novamente após trocar o arquivo ou atualizar o app.").setPositiveButton("Restaurar áudios",(d,w)->{restore(c,"audio");refresh.run();}).setNeutralButton("Restaurar vídeos",(d,w)->{restore(c,"video");refresh.run();}).setNegativeButton("Fechar",null).show();}
}
