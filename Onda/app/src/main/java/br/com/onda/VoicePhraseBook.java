package br.com.onda;

import java.util.*;
import org.json.*;

/** Exact user-defined aliases. No executable code, network or automatic fuzzy matching. */
final class VoicePhraseBook {
    static final int LIMIT=100;
    static final class Entry {
        final String id,phrase;final VoiceCommand command;
        Entry(String id,String phrase,VoiceCommand command){this.id=id;this.phrase=phrase;this.command=command;}
    }
    final List<Entry> entries=new ArrayList<>();
    VoicePhraseBook(String json){
        try{JSONArray array=new JSONArray(json);for(int i=0;i<array.length()&&entries.size()<LIMIT;i++){
            try{JSONObject o=array.getJSONObject(i);put(o.getString("id"),o.getString("phrase"),VoiceCommand.Action.valueOf(o.getString("action")),o.getString("query"),o.getInt("minutes"));}catch(JSONException|IllegalArgumentException ignored){}
        }}catch(JSONException ignored){}
    }
    static String key(String phrase){return SearchText.normalize(VoiceCommand.cleanPhrase(phrase));}
    Entry put(String id,String phrase,VoiceCommand.Action action,String query,int minutes){
        phrase=phrase==null?"":phrase.trim();query=query==null?"":query.trim();String normalized=key(phrase);
        if(normalized.length()<3||phrase.length()>120)throw new IllegalArgumentException("Use uma frase entre 3 e 120 caracteres.");
        if(normalized.matches("(?:busque|buscar|pesquise|pesquisar|procure|procurar) .*"))throw new IllegalArgumentException("Frases iniciadas por buscar ou pesquisar são reservadas para buscas. Escolha outra frase.");
        VoiceCommand.Action builtIn=VoiceCommand.parse(phrase).action;
        if(builtIn!=VoiceCommand.Action.SEARCH&&builtIn!=VoiceCommand.Action.PLAY_QUERY)throw new IllegalArgumentException("Essa frase já é um comando padrão. Escolha uma nova frase para seu atalho.");
        for(Entry e:entries)if(key(e.phrase).equals(normalized)&&!e.id.equals(id))throw new IllegalArgumentException("Essa frase já está cadastrada. Edite a frase existente.");
        VoiceCommand command=VoiceCommand.custom(action,query,minutes);
        if(id==null){if(entries.size()>=LIMIT)throw new IllegalArgumentException("Limite de 100 frases. Edite ou exclua uma frase existente.");id=UUID.randomUUID().toString();}
        Entry entry=new Entry(id,phrase,command);for(int i=0;i<entries.size();i++)if(entries.get(i).id.equals(id)){entries.set(i,entry);return entry;}
        entries.add(entry);return entry;
    }
    void remove(String id){entries.removeIf(e->e.id.equals(id));}
    VoiceCommand find(String phrase){String value=key(phrase);for(Entry e:entries)if(key(e.phrase).equals(value))return e.command;return null;}
    String json(){
        JSONArray array=new JSONArray();for(Entry e:entries)try{array.put(new JSONObject().put("id",e.id).put("phrase",e.phrase).put("action",e.command.action.name()).put("query",e.command.query).put("minutes",e.command.minutes));}catch(JSONException impossible){throw new IllegalStateException(impossible);}
        return array.toString();
    }
}
