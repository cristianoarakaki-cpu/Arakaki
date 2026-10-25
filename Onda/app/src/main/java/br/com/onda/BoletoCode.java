package br.com.onda;
import java.util.*;
import java.util.regex.*;
/** Brazilian bank/collection lines with field and general check digits. No payment operation. */
final class BoletoCode {
 final String line,barcode;final boolean collection;
 private BoletoCode(String l,String b,boolean c){line=l;barcode=b;collection=c;}
 static int mod10(String s){int sum=0,weight=2;for(int i=s.length()-1;i>=0;i--){int n=(s.charAt(i)-'0')*weight;sum+=n>9?n-9:n;weight=3-weight;}return (10-sum%10)%10;}
 private static int remainder11(String s){int sum=0,w=2;for(int i=s.length()-1;i>=0;i--){sum+=(s.charAt(i)-'0')*w;if(++w>9)w=2;}return sum%11;}
 private static int bankDigit(String s){int n=11-remainder11(s);return n<=1||n>9?1:n;}
 private static int collectionDigit(String s,char reference){if(reference=='6'||reference=='7')return mod10(s);int r=remainder11(s);return r==0||r==1?0:r==10?1:11-r;}
 private static boolean collectionValid(String b){return b.charAt(0)=='8'&&"12345679".indexOf(b.charAt(1))>=0&&"6789".indexOf(b.charAt(2))>=0&&collectionDigit(b.substring(0,3)+b.substring(4),b.charAt(2))==b.charAt(3)-'0';}
 private static boolean bankValid(String b){return !b.startsWith("000")&&b.charAt(3)=='9'&&bankDigit(b.substring(0,4)+b.substring(5))==b.charAt(4)-'0';}
 static BoletoCode from(String raw){if(raw==null||raw.length()>200)return null;String n=raw.replaceAll("[^0-9]","");
  if(n.length()==47){if(mod10(n.substring(0,9))!=n.charAt(9)-'0'||mod10(n.substring(10,20))!=n.charAt(20)-'0'||mod10(n.substring(21,31))!=n.charAt(31)-'0')return null;String b=n.substring(0,4)+n.charAt(32)+n.substring(33)+n.substring(4,9)+n.substring(10,20)+n.substring(21,31);return bankValid(b)?new BoletoCode(n,b,false):null;}
  if(n.length()==48){if("6789".indexOf(n.charAt(2))<0)return null;StringBuilder b=new StringBuilder();for(int i=0;i<48;i+=12){String data=n.substring(i,i+11);if(collectionDigit(data,n.charAt(2))!=n.charAt(i+11)-'0')return null;b.append(data);}return collectionValid(b.toString())?new BoletoCode(n,b.toString(),true):null;}
  if(n.length()!=44)return null;
  if(collectionValid(n)&&bankValid(n))return null;
  if(collectionValid(n)){StringBuilder l=new StringBuilder();for(int i=0;i<44;i+=11){String part=n.substring(i,i+11);l.append(part).append(collectionDigit(part,n.charAt(2)));}return new BoletoCode(l.toString(),n,true);}
  if(!bankValid(n))return null;String a=n.substring(0,4)+n.substring(19,24),b=n.substring(24,34),c=n.substring(34);return new BoletoCode(a+mod10(a)+b+mod10(b)+c+mod10(c)+n.charAt(4)+n.substring(5,19),n,false);
 }
 static List<BoletoCode> find(String text){List<BoletoCode> out=new ArrayList<>();Set<String> found=new HashSet<>();List<int[]> spans=new ArrayList<>();if(text==null)return out;String value=text.substring(0,Math.min(100000,text.length()));for(int digits:new int[]{48,47,44}){Matcher m=Pattern.compile("(?<![0-9])(?=([0-9](?:[\\s.\\-\\u00a0]{0,6}[0-9]){"+(digits-1)+"})(?![0-9]))").matcher(value);while(m.find()){int start=m.start(1),end=m.end(1);boolean overlap=false;for(int[] span:spans)if(start<span[1]&&end>span[0]){overlap=true;break;}if(overlap)continue;BoletoCode code=from(m.group(1));if(code!=null){spans.add(new int[]{start,end});if(found.add(code.barcode))out.add(code);if(out.size()>=10)return out;}}}return out;}
 String formatted(){if(collection){StringBuilder out=new StringBuilder();for(int i=0;i<48;i+=12){if(i>0)out.append(' ');out.append(line,i,i+11).append('-').append(line.charAt(i+11));}return out.toString();}return line.substring(0,5)+"."+line.substring(5,10)+" "+line.substring(10,15)+"."+line.substring(15,21)+" "+line.substring(21,26)+"."+line.substring(26,32)+" "+line.charAt(32)+" "+line.substring(33);}
}
