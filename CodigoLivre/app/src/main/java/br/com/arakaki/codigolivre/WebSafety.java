package br.com.arakaki.codigolivre;
import java.net.*;
import java.util.*;
final class WebSafety {
    static void url(String address){
        URI u=URI.create(address);String host=u.getHost();
        if(!"https".equals(u.getScheme())||host==null||u.getRawUserInfo()!=null||(u.getPort()!=-1&&u.getPort()!=443)||address.length()>8192)throw new IllegalArgumentException("Somente páginas HTTPS públicas são permitidas.");
        String h=host.toLowerCase(Locale.ROOT);if(h.equals("localhost")||h.endsWith(".localhost")||h.endsWith(".local")||h.endsWith(".lan")||h.endsWith(".internal"))throw new IllegalArgumentException("Endereço interno recusado.");
        if(h.matches("[0-9.]+")||h.startsWith("[")){try{if(!publicAddress(InetAddress.getByName(h)))throw new IllegalArgumentException("Endereço interno/reservado recusado.");}catch(UnknownHostException e){throw new IllegalArgumentException("IP inválido.");}}
    }
    static boolean publicAddress(InetAddress ip){
        if(ip.isAnyLocalAddress()||ip.isLoopbackAddress()||ip.isLinkLocalAddress()||ip.isSiteLocalAddress()||ip.isMulticastAddress())return false;
        byte[] b=ip.getAddress();int a=b[0]&255;
        if(b.length==4){int c=b[1]&255,d=b[2]&255;return a!=0&&a<224&&!(a==100&&c>=64&&c<=127)&&!(a==192&&c==0&&(d==0||d==2))&&!(a==198&&(c==18||c==19||c==51&&d==100))&&!(a==203&&c==0&&d==113);}
        if(a==0x20&&(b[1]&255)==2)return false; // 6to4
        if(a==0x20&&(b[1]&255)==1&&b[2]==0&&b[3]==0)return false; // Teredo
        if(a==0&&(b[1]&255)==0x64&&(b[2]&255)==0xff&&(b[3]&255)==0x9b){
            boolean wellKnown=true;for(int i=4;i<12;i++)wellKnown&=b[i]==0;
            if(!wellKnown)return false;
            try{return publicAddress(InetAddress.getByAddress(Arrays.copyOfRange(b,12,16)));}catch(UnknownHostException e){return false;}
        } // NAT64 /96: permite destinos IPv4 públicos, preserva bloqueio dos internos.
        boolean compatible=true;for(int i=0;i<12;i++)compatible&=b[i]==0;if(compatible)return false;
        return (a&0xfe)!=0xfc&&!(a==0x20&&(b[1]&255)==1&&(b[2]&255)==0x0d&&(b[3]&255)==0xb8);
    }
    static List<InetAddress> resolve(String hostname)throws UnknownHostException{
        List<InetAddress> result=Arrays.asList(InetAddress.getAllByName(hostname));
        if(result.isEmpty()||result.stream().anyMatch(a->!publicAddress(a)))throw new UnknownHostException("Destino interno ou reservado recusado.");return result;
    }
}
