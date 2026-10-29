package br.com.onda;
/** Curated dark interfaces. Layout sizes and Android font scaling stay unchanged. */
final class AppearancePalette {
 final String id,name,description;final int bg,end,surface,raised,border,accent,secondary;final float corners;
 static final int TEXT=0xFFF2F6FF,MUTED=0xFF99ADC7;
 AppearancePalette(String id,String name,String description,int bg,int end,int surface,int raised,int border,int accent,int secondary,float corners){this.id=id;this.name=name;this.description=description;this.bg=bg;this.end=end;this.surface=surface;this.raised=raised;this.border=border;this.accent=accent;this.secondary=secondary;this.corners=corners;}
 static final AppearancePalette[] ALL={
  new AppearancePalette("original","Onda Original","Azul profundo, ciano e cartões arredondados",0xFF080C17,0xFF0C1122,0xFF111A2B,0xFF172338,0xFF27374F,0xFF69E7FF,0xFFAB97FF,1f),
  new AppearancePalette("nebula","Nebulosa","Violeta, brilho rosado e curvas suaves",0xFF110B1E,0xFF20112F,0xFF20172F,0xFF2A1E3B,0xFF584267,0xFFE2B4FF,0xFFFFB6DB,1.35f),
  new AppearancePalette("circuit","Circuito","Verde menta, fundo escuro e linhas precisas",0xFF061410,0xFF0B211B,0xFF11241E,0xFF193129,0xFF315749,0xFF7DF5C0,0xFF8FDDD7,.55f),
  new AppearancePalette("solar","Cyber Solar","Âmbar, preto e cartões com cantos angulares",0xFF151009,0xFF241A0D,0xFF272015,0xFF33291C,0xFF665237,0xFFFFCC80,0xFFFFA990,.2f),
  new AppearancePalette("graphite","Grafite","Monocromático, discreto e com poucos contrastes de cor",0xFF101114,0xFF191B20,0xFF202328,0xFF2B2F35,0xFF545C66,0xFFE5E7EB,0xFFB7C2CF,.6f)
 };
 static AppearancePalette find(String id){for(AppearancePalette p:ALL)if(p.id.equals(id))return p;return ALL[0];}
 static int blend(int first,int second,float mix){float m=Math.max(0,Math.min(1,mix));int r=Math.round(((first>>16)&255)*(1-m)+((second>>16)&255)*m),g=Math.round(((first>>8)&255)*(1-m)+((second>>8)&255)*m),b=Math.round((first&255)*(1-m)+(second&255)*m);return 0xFF000000|r<<16|g<<8|b;}
 static double luminance(int color){double[] c={((color>>16)&255)/255d,((color>>8)&255)/255d,(color&255)/255d};for(int i=0;i<3;i++)c[i]=c[i]<=.04045?c[i]/12.92:Math.pow((c[i]+.055)/1.055,2.4);return .2126*c[0]+.7152*c[1]+.0722*c[2];}
 static double contrast(int a,int b){double x=luminance(a),y=luminance(b);return (Math.max(x,y)+.05)/(Math.min(x,y)+.05);}
}
