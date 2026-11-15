package br.com.arakaki.codigolivre;
import java.util.concurrent.*;
/** Uma única fila compartilha o motor nativo entre tela e serviço. */
final class ModelRuntime {
    static final ExecutorService WORKER=Executors.newSingleThreadExecutor();
}
