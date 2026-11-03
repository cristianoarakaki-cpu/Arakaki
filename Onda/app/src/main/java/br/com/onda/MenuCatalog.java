package br.com.onda;
/** Categories only affect discovery; every original action keeps its identity and order. */
final class MenuCatalog {
 static final String[] GROUPS={"Todas as categorias","Biblioteca","Online","Reprodução","Som","Personalização","Ferramentas"};
 static int group(String description){String s=SearchText.normalize(description);if(has(s,"estudio de som","controles de audio","fones","bluetooth","aulas e podcasts"))return 4;if(has(s,"aparencias","comandos de voz","minhas frases","assistente com ia"))return 5;if(has(s,"download","radio","imagens","mensagens","onda conecta","youtube","online"))return 2;if(has(s,"busca unificada","playlist","fila de reproducao","coleco","biblioteca","arquivos do onda","continuar","ocultos","acesso aos videos","recarregar videos","reler arquivos"))return 1;if(has(s,"reprodu","faixas da coletanea","temporizador","letra","legenda","momento","trecho","segundos","aprender","gestos","abrir arquivo","sessao","janela flutuante","dj pessoal","compartilhar"))return 3;return 6;}
 static boolean matches(String label,String description,String query,int category){return (category==0||category==group(label+" "+description))&&SearchText.normalize(label+" "+description).contains(SearchText.normalize(query));}
 private static boolean has(String s,String... terms){for(String t:terms)if(s.contains(t))return true;return false;}
 static String shortName(String s){if(s.equals("Estúdio de som")||s.equals("Fones e Bluetooth"))return "Som";if(s.startsWith("Abrir arquivo"))return "Arquivo";if(s.startsWith("Legendas"))return "Legendas";return s;}
}
