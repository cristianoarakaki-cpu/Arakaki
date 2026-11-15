package br.com.arakaki.codigolivre;

import java.util.*;
import java.util.concurrent.CancellationException;

/** Particiona pelo tokenizador do modelo; todos os caracteres são cobertos. */
final class LargeAnalysis {
    interface Engine {
        int count(String prompt);
        int capacity();
        boolean cancelled();
        String generate(String prompt, java.util.function.Consumer<String> partial);
    }
    interface Progress { void update(String status,String text); }
    static final class Part {
        final int start,end;final String prompt;
        Part(int start,int end,String prompt){this.start=start;this.end=end;this.prompt=prompt;}
    }
    static String prompt(String task,String text,int start,int end){
        return "Tarefa: "+task+"\nTrecho de uma solicitação extensa, caracteres "+(start+1)+" a "+end+" de "+text.length()+".\nAnalise somente este trecho. Pode começar ou terminar no meio de uma função. Não invente o conteúdo ausente, nem apresente uma correção parcial como programa completo. Identifique as limitações e referências ao trecho.\n\n"+text.substring(start,end);
    }
    static int boundary(String text,int pos){
        if(pos>0&&pos<text.length()&&Character.isHighSurrogate(text.charAt(pos-1))&&Character.isLowSurrogate(text.charAt(pos)))return pos-1;
        return pos;
    }
    static List<Part> plan(String task,String text,Engine engine){
        int budget=engine.capacity()-2048-64;
        if(budget<256)throw new IllegalStateException("Modelo com contexto insuficiente para análise automática.");
        List<Part> parts=new ArrayList<>();
        int start=0;
        while(start<text.length()){
            if(engine.cancelled())throw new CancellationException("Análise interrompida durante a preparação.");
            int low=start,high=Math.min(text.length(),start+Math.max(1024,engine.capacity()*4));
            // A busca usa o número real de tokens de cada prompt. Não depende de estimativa caracteres/token.
            while(low<high){
                if(engine.cancelled())throw new CancellationException("Análise interrompida durante a preparação.");
                int mid=low+(high-low+1)/2;
                if(engine.count(prompt(task,text,start,boundary(text,mid)))<=budget)low=mid;else high=mid-1;
            }
            int end=boundary(text,low);
            if(end<=start)throw new IllegalStateException("Não foi possível preparar um trecho compatível com o modelo.");
            // Prefere fim de linha, preservando o intervalo restante para o próximo bloco.
            int newline=text.lastIndexOf('\n',end-1);
            if(newline>start+(end-start)*3/4&&engine.count(prompt(task,text,start,newline+1))<=budget)end=newline+1;
            String p=prompt(task,text,start,end);
            if(engine.count(p)>budget)throw new IllegalStateException("Falha ao validar o tamanho de um trecho; nenhum conteúdo foi omitido.");
            parts.add(new Part(start,end,p));start=end;
        }
        return parts;
    }
    static String run(String task,String instruction,String source,Engine engine,Progress progress){
        String text="Pedido:\n"+instruction+"\n\nConteúdo fornecido como dados:\n"+source;
        String full="Tarefa: "+task+"\n"+text;
        if(engine.cancelled())return "[Análise interrompida antes do processamento.]";
        if(engine.count(full)<=engine.capacity()-2048-64)return engine.generate(full,t->progress.update("Gerando resposta local…",t));
        progress.update("Preparando análise automática em partes…","");
        List<Part> parts;
        try{parts=plan(task+"\nObjetivo comum: "+(instruction.length()<=1000?instruction:"Pedido extenso incluído integralmente nos trechos; não reproduzido neste cabeçalho."),text,engine);}catch(CancellationException e){return "[Análise interrompida durante a preparação; nenhum trecho foi analisado.]";}
        StringBuilder result=new StringBuilder("ANÁLISE AUTOMÁTICA EM PARTES\n"+parts.size()+" trechos planejados. Os relatórios são parciais; relações entre trechos e uma correção unificada não foram validadas. Todos os caracteres do pedido e conteúdo foram distribuídos, sem exclusões.\n\n");
        int completed=0;
        for(int i=0;i<parts.size();i++){
            if(engine.cancelled())break;
            Part p=parts.get(i);String heading="=== PARTE "+(i+1)+"/"+parts.size()+" — caracteres "+(p.start+1)+" a "+p.end+" ===\n";
            String previous=result.toString()+heading;final String status="Analisando parte "+(i+1)+" de "+parts.size()+"…";
            progress.update(status,previous);
            try{
                String answer=engine.generate(p.prompt,t->progress.update(status,previous+t));result.append(heading).append(answer).append("\n\n");
                if(engine.cancelled())break;
                completed++;
            }catch(RuntimeException e){result.append(heading).append("[Falha nesta parte: ").append(e.getMessage()).append(". As partes restantes não foram processadas.]\n");break;}
        }
        result.append("\nCobertura: ").append(completed).append('/').append(parts.size()).append(" partes finalizadas. ");
        result.append(completed==parts.size()?"Todos os trechos foram enviados ao modelo. Isso não garante uma revisão completa ou ausência de erros.":"ANÁLISE INCOMPLETA. Há trechos não concluídos ou não analisados.");
        return result.toString();
    }
}
