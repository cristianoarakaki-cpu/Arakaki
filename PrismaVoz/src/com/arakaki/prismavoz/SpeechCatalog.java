package com.arakaki.prismavoz;

import android.content.Context;
import android.speech.tts.TextToSpeech;
import android.speech.tts.Voice;
import org.json.JSONArray;
import org.json.JSONObject;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/** Lists voices from the user's default Android engine; never installs packages. */
final class SpeechCatalog {
    private TextToSpeech engine;
    private volatile String snapshot = "{\"ready\":false,\"voices\":[]}";
    SpeechCatalog(Context context) {
        engine = new TextToSpeech(context.getApplicationContext(), status -> {
            if (status != TextToSpeech.SUCCESS) {
                snapshot = "{\"ready\":true,\"error\":\"Nenhum motor de voz disponível. Instale ou ative um nas configurações do Android.\",\"voices\":[]}";
                return;
            }
            try {
                JSONArray voices = new JSONArray();
                List<Voice> sorted = new ArrayList<>();
                if (engine.getVoices() != null) sorted.addAll(engine.getVoices());
                Collections.sort(sorted, (a,b) -> a.getName().compareTo(b.getName()));
                for (Voice voice : sorted) {
                    if (voice.getFeatures().contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED)) continue;
                    JSONObject item = new JSONObject();
                    item.put("id", voice.getName());
                    item.put("language", voice.getLocale().toLanguageTag());
                    item.put("label", voice.getLocale().getDisplayName(new java.util.Locale("pt", "BR")) + " — " + voice.getName());
                    item.put("network", voice.isNetworkConnectionRequired());
                    voices.put(item);
                }
                snapshot = new JSONObject().put("ready",true).put("voices",voices).toString();
            } catch (Exception e) {
                snapshot = "{\"ready\":true,\"error\":\"Não foi possível listar as vozes. Confira o motor de voz do Android.\",\"voices\":[]}";
            }
        });
    }
    String state() { return snapshot; }
    void close() { if (engine != null) { engine.shutdown(); engine = null; } }
}
