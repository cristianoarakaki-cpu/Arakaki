package br.com.onda;
/** Human labels with explicit immutable bounds; no acoustic inference. */
final class MemoryNote {
 static String text(String raw){String text=raw==null?"":raw.trim();if(text.isEmpty()||text.length()>500)throw new IllegalArgumentException("Digite um nome ou anotação de até 500 caracteres.");return text;}
 static MemoryText.Cue cue(String label,int page,String from,String to,long limit){String text=text(label);if(page>=0){if(limit<=0||page>=limit)throw new IllegalArgumentException("Página indisponível.");return new MemoryText.Cue(0,0,page,text);}long start,end;try{start=ChapterEdits.parse(from);end=ChapterEdits.parse(to);}catch(IllegalArgumentException error){throw new IllegalArgumentException("Confira os horários: use minutos:segundos.milissegundos.");}if(start<0||end<=start||end>limit)throw new IllegalArgumentException("O fim deve ser maior que o início e caber no arquivo.");return new MemoryText.Cue(start,end,-1,text);}
 static long start(long position,long duration){return Math.max(0,Math.min(position,Math.max(0,duration-1)));}
 static long end(long start,long duration){return start+Math.min(8000,Math.max(0,duration-start));}
}
