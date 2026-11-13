package br.com.onda;
import com.google.mlkit.common.model.DownloadConditions;
import com.google.mlkit.nl.translate.*;
/** No API key or per-use billing; language models are downloaded on explicit request. */
final class LocalLyricTranslator implements AutoCloseable,LyricTranslation.Engine {
 private final Translator translator;private boolean closed;
 LocalLyricTranslator(String source,String target){translator=Translation.getClient(new TranslatorOptions.Builder().setSourceLanguage(source).setTargetLanguage(target).build());}
 void prepare(boolean wifi,Runnable ready,java.util.function.Consumer<Exception> failure){DownloadConditions.Builder conditions=new DownloadConditions.Builder();if(wifi)conditions.requireWifi();translator.downloadModelIfNeeded(conditions.build()).addOnSuccessListener(v->{if(!closed)ready.run();}).addOnFailureListener(e->{if(!closed)failure.accept(e);});}
 @Override public void translate(String text,LyricTranslation.Result callback){if(closed)return;translator.translate(text).addOnSuccessListener(value->{if(!closed)callback.success(value);}).addOnFailureListener(e->{if(!closed)callback.failure(e);});}
 @Override public void close(){if(!closed){closed=true;translator.close();}}
}
