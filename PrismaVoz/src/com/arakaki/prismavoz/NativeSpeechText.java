package com.arakaki.prismavoz;
import java.util.*;
/** Shared text preparation; no HTML, scripting engine or remote processing. */
final class NativeSpeechText {
    static String normalize(String text){
        if(text==null)return "";
        return text.replace("\ufb01","fi").replace("\ufb02","fl").replace("\ufb00","ff")
            .replaceAll("\u00ad\\s*\\n\\s*","").replace("\u00ad","")
            .replaceAll("[\\t \\u00a0]+"," ").replaceAll(" *\\n *","\n")
            .replaceAll("([\\p{L}])-\\n(?=\\p{L})","$1-")
            .replaceAll("([^\\n])\\n(?!\\n|[•▪●]\\s|\\d+[.)]\\s)","$1 ").trim();
    }
    static int letters(String text){return (int)text.codePoints().filter(Character::isLetterOrDigit).count();}
    static List<String> chunks(String input){
        String rest=normalize(input);List<String> result=new ArrayList<>();
        while(!rest.isEmpty()){
            int end=Math.min(700,rest.length());
            if(end<rest.length()){
                String tail=rest.substring(0,end);int sentence=-1;
                for(String mark:new String[]{". ","! ","? ","; ","\n"})sentence=Math.max(sentence,tail.lastIndexOf(mark));
                if(sentence>end*.4)end=sentence+1;else{int space=tail.lastIndexOf(' ');if(space>end*.4)end=space;}
                if(end>0&&Character.isHighSurrogate(rest.charAt(end-1)))end--;
            }
            String part=rest.substring(0,end).trim();if(!part.isEmpty())result.add(part);rest=rest.substring(end).trim();
        }
        return result;
    }
}
