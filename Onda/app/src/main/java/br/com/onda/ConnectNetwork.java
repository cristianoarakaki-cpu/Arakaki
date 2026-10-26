package br.com.onda;
import android.content.Context;
import android.net.*;
final class ConnectNetwork {
 final Network network;final String host;
 private ConnectNetwork(Network network,String host){this.network=network;this.host=host;}
 static ConnectNetwork wifi(Context context)throws Exception{ConnectivityManager manager=(ConnectivityManager)context.getSystemService(Context.CONNECTIVITY_SERVICE);for(Network n:manager.getAllNetworks()){NetworkCapabilities c=manager.getNetworkCapabilities(n);LinkProperties p=manager.getLinkProperties(n);if(c==null||p==null||!c.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)||c.hasTransport(NetworkCapabilities.TRANSPORT_VPN))continue;for(LinkAddress address:p.getLinkAddresses()){String host=address.getAddress().getHostAddress();if(ConnectProtocol.privateHost(host))return new ConnectNetwork(n,host);}}throw new java.io.IOException("Conecte os dois celulares à mesma rede Wi-Fi privada. Redes de convidados podem bloquear a conexão.");}
}
