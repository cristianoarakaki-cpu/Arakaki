package br.com.onda;
/** Curated dark interfaces. Layout sizes and Android font scaling stay unchanged. */
final class AppearancePalette {
 final String id,name,description;final int bg,end,surface,raised,border,accent,secondary;final float corners;final int variant;
 static final int TEXT=0xFFF2F6FF,MUTED=0xFF99ADC7;
 AppearancePalette(String id,String name,String description,int bg,int end,int surface,int raised,int border,int accent,int secondary,float corners){this(id,name,description,bg,end,surface,raised,border,accent,secondary,corners,0);}
 AppearancePalette(String id,String name,String description,int bg,int end,int surface,int raised,int border,int accent,int secondary,float corners,int variant){this.variant=variant;this.id=id;this.name=name;this.description=description;this.bg=bg;this.end=end;this.surface=surface;this.raised=raised;this.border=border;this.accent=accent;this.secondary=secondary;this.corners=corners;}
 static final AppearancePalette[] ALL={
  new AppearancePalette("original","Onda Original","Azul profundo, ciano e cartões arredondados",0xFF080C17,0xFF0C1122,0xFF111A2B,0xFF172338,0xFF27374F,0xFF69E7FF,0xFFAB97FF,1f),
  new AppearancePalette("nebula","Nebulosa","Violeta, brilho rosado e curvas suaves",0xFF110B1E,0xFF20112F,0xFF20172F,0xFF2A1E3B,0xFF584267,0xFFE2B4FF,0xFFFFB6DB,1.35f),
  new AppearancePalette("circuit","Circuito","Verde menta, fundo escuro e linhas precisas",0xFF061410,0xFF0B211B,0xFF11241E,0xFF193129,0xFF315749,0xFF7DF5C0,0xFF8FDDD7,.55f),
  new AppearancePalette("solar","Cyber Solar","Âmbar, preto e cartões com cantos angulares",0xFF151009,0xFF241A0D,0xFF272015,0xFF33291C,0xFF665237,0xFFFFCC80,0xFFFFA990,.2f),
  new AppearancePalette("graphite","Grafite","Monocromático, discreto e com poucos contrastes de cor",0xFF101114,0xFF191B20,0xFF202328,0xFF2B2F35,0xFF545C66,0xFFE5E7EB,0xFFB7C2CF,.6f),
  new AppearancePalette("aurora","Aurora 3D","Orbes de luz, menta e violeta sobre azul polar",0xFF08131B,0xFF101B2A,0xFF142330,0xFF1B2D3C,0xFF3A5269,0xFF8CF8DC,0xFFC8B6FF,1.3f,1),
  new AppearancePalette("titanium","Titânio 3D","Metal azulado, emblemas facetados e botões chanfrados",0xFF0D121A,0xFF17202A,0xFF1B2632,0xFF233242,0xFF4E637A,0xFFBCDFFF,0xFFE1CBFF,.4f,2),
  new AppearancePalette("hologram","Holograma 3D","Prismas ciano, bordas luminosas e superfícies de cristal",0xFF06151A,0xFF101F29,0xFF122A33,0xFF1A3440,0xFF356276,0xFF91F1FF,0xFFBDBDFF,.9f,3),
  new AppearancePalette("plasma","Plasma 3D","Cristais magenta, painéis angulares e energia violeta",0xFF170B1C,0xFF24132B,0xFF291831,0xFF34203D,0xFF694678,0xFFFFBAE6,0xFFDBB9FF,.35f,4),
  new AppearancePalette("abyss","Abissal 3D","Escudos oceânicos e botões com profundidade azul",0xFF07121D,0xFF0D1F31,0xFF122739,0xFF1C3448,0xFF3E5F78,0xFF99DCFF,0xFF8FF2E0,1.1f,5),
  new AppearancePalette("emerald","Esmeralda 3D","Gemas verdes, acabamento fosco e detalhes dourados",0xFF0A1511,0xFF142219,0xFF192C22,0xFF24372B,0xFF486750,0xFFADF2B7,0xFFF0D9A2,.65f,6),
  new AppearancePalette("nova","Nova 3D","Estrelas âmbar e comandos com recortes espaciais",0xFF191009,0xFF281C12,0xFF2D2219,0xFF392D22,0xFF71573D,0xFFFFD59B,0xFFFFBFB0,.25f,7),
  new AppearancePalette("lunar","Lunar 3D","Órbitas prateadas, reflexos frios e curvas de cápsula",0xFF11121B,0xFF1A1D2B,0xFF222638,0xFF2C3142,0xFF59637B,0xFFD9E3FF,0xFFCFBEFF,1.5f,8),
  new AppearancePalette("obsidian","Obsidiana 3D","Monólitos escuros, cristal violeta e linhas de precisão",0xFF100E18,0xFF1B1728,0xFF231F32,0xFF30293E,0xFF605174,0xFFE0C3FF,0xFFFFC9DD,.2f,9),
  new AppearancePalette("spectrum","Espectro 3D","Portais multicoloridos, ciano e rosa com relevo suave",0xFF0C101B,0xFF171A2B,0xFF1D2436,0xFF293145,0xFF53627E,0xFF9CF3F5,0xFFFFC2EC,1.05f,10),
  new AppearancePalette("festival","Festival","Rosa elétrico, ciano e portais coloridos em relevo",0xFF0A0C18,0xFF18102A,0xFF15172A,0xFF1B1D31,0xFF7351A2,0xFFFF9CE1,0xFF8EF2FF,1.05f,10),
  new AppearancePalette("candy","Algodão","Rosa doce, lilás e cristais com contraste suave",0xFF170C1A,0xFF241025,0xFF26152A,0xFF2D1B31,0xFF865777,0xFFFFA9D8,0xFFC8B1FF,1.25f,4),
  new AppearancePalette("sunset","Pôr do Sol","Coral, pêssego e magenta em painéis luminosos",0xFF190D14,0xFF241322,0xFF2A1920,0xFF301F27,0xFF925466,0xFFFFBE87,0xFFFF9FD5,.6f,7),
  new AppearancePalette("lagoon","Lagoa","Turquesa, azul claro e cristais oceânicos",0xFF071620,0xFF0B2330,0xFF102633,0xFF182F3B,0xFF377D91,0xFF79F3DC,0xFF9AD5FF,.9f,3)
 };
 static AppearancePalette find(String id){for(AppearancePalette p:ALL)if(p.id.equals(id))return p;return ALL[0];}
 static int blend(int first,int second,float mix){float m=Math.max(0,Math.min(1,mix));int r=Math.round(((first>>16)&255)*(1-m)+((second>>16)&255)*m),g=Math.round(((first>>8)&255)*(1-m)+((second>>8)&255)*m),b=Math.round((first&255)*(1-m)+(second&255)*m);return 0xFF000000|r<<16|g<<8|b;}
 static double luminance(int color){double[] c={((color>>16)&255)/255d,((color>>8)&255)/255d,(color&255)/255d};for(int i=0;i<3;i++)c[i]=c[i]<=.04045?c[i]/12.92:Math.pow((c[i]+.055)/1.055,2.4);return .2126*c[0]+.7152*c[1]+.0722*c[2];}
 static double contrast(int a,int b){double x=luminance(a),y=luminance(b);return (Math.max(x,y)+.05)/(Math.min(x,y)+.05);}
}
