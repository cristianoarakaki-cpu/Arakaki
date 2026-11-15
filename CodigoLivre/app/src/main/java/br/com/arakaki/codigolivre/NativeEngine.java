package br.com.arakaki.codigolivre;
final class NativeEngine {
    static { System.loadLibrary("codigolivre"); }
    interface Callback { void onText(byte[] utf8); }
    static native void load(byte[] path);
    static native void unload();
    static native void resetCancel();
    static native void cancel();
    static native byte[] generate(byte[] system, byte[] request, Callback callback, int limit, int threads);
}
