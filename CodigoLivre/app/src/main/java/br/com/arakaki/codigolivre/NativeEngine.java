package br.com.arakaki.codigolivre;
final class NativeEngine {
    static { System.loadLibrary("codigolivre"); }
    interface Callback { void onText(byte[] utf8); default void onProgress(String phase,int done,int total,float rate) {} }
    static native void load(byte[] path);
    static native void unload();
    static native void configure(int context);
    static native void releaseContext();
    static native void resetCancel();
    static native void cancel();
    static native boolean cancelled();
    static native int capacity();
    static native int count(byte[] system, byte[] request);
    static native byte[] generate(byte[] system, byte[] request, Callback callback, int limit, int threads);
}
