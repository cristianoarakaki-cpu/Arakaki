package br.com.arakaki.codigolivre;
final class SpeedProfile {
    final String name;final int context,output,reserve;
    private SpeedProfile(String name,int context,int output,int reserve){this.name=name;this.context=context;this.output=output;this.reserve=reserve;}
    static SpeedProfile of(int index){return switch(index){case 1->new SpeedProfile("Equilibrado",4096,1536,1536);case 2->new SpeedProfile("Longo",8192,0,2048);default->new SpeedProfile("Rápido",3072,768,768);};}
}
