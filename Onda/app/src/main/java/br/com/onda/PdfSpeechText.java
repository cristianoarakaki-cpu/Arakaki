package br.com.onda;

/** Bounded utterances, without dropping characters or splitting UTF-16 pairs. */
final class PdfSpeechText {
 private PdfSpeechText(){}
 static int end(String text,int start,int maximum){
  if(start<0||start>text.length()||maximum<2)throw new IllegalArgumentException();
  int end=Math.min(text.length(),start+maximum);
  if(end<text.length()&&Character.isHighSurrogate(text.charAt(end-1))&&Character.isLowSurrogate(text.charAt(end)))end--;
  if(end<text.length())for(int i=end-1;i>start+maximum/2;i--){char c=text.charAt(i);if(c=='.'||c=='!'||c=='?'||c=='\n'||Character.isWhitespace(c))return i+1;}
  return end;
 }
}
