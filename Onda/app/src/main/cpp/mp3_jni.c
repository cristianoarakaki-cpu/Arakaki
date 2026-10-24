#include <jni.h>
#include <stdint.h>
#include "lame.h"
static void fail(JNIEnv *env,const char *message){(*env)->ThrowNew(env,(*env)->FindClass(env,"java/io/IOException"),message);}
JNIEXPORT jlong JNICALL Java_br_com_onda_Mp3Converter_open(JNIEnv *env,jclass type,jint rate,jint channels,jint bitrate){
 if((channels!=1&&channels!=2)||rate<8000||rate>48000||(bitrate!=128&&bitrate!=192)){fail(env,"Formato PCM incompatível");return 0;}
 lame_t g=lame_init();if(!g){fail(env,"Não foi possível iniciar o MP3");return 0;}
 lame_set_in_samplerate(g,rate);lame_set_num_channels(g,channels);lame_set_brate(g,bitrate);lame_set_quality(g,3);lame_set_mode(g,channels==1?MONO:JOINT_STEREO);lame_set_bWriteVbrTag(g,0);
 if(lame_init_params(g)<0){lame_close(g);fail(env,"Não foi possível configurar o MP3");return 0;}
 return (jlong)(intptr_t)g;
}
JNIEXPORT jint JNICALL Java_br_com_onda_Mp3Converter_encode(JNIEnv *env,jclass type,jlong handle,jshortArray pcm,jint samples,jbyteArray bytes,jint channels){
 if(!handle||samples<0||samples>16384||(*env)->GetArrayLength(env,pcm)<samples*channels||(*env)->GetArrayLength(env,bytes)<32768){fail(env,"Bloco PCM inválido");return -1;}
 jshort *p=(*env)->GetShortArrayElements(env,pcm,0);jbyte *out=(*env)->GetByteArrayElements(env,bytes,0);if(!p||!out){if(p)(*env)->ReleaseShortArrayElements(env,pcm,p,JNI_ABORT);if(out)(*env)->ReleaseByteArrayElements(env,bytes,out,0);return -1;}
 int n=channels==1?lame_encode_buffer((lame_t)(intptr_t)handle,p,p,samples,(unsigned char*)out,(*env)->GetArrayLength(env,bytes)):lame_encode_buffer_interleaved((lame_t)(intptr_t)handle,p,samples,(unsigned char*)out,(*env)->GetArrayLength(env,bytes));
 (*env)->ReleaseShortArrayElements(env,pcm,p,JNI_ABORT);(*env)->ReleaseByteArrayElements(env,bytes,out,0);if(n<0)fail(env,"Falha ao codificar MP3");return n;
}
JNIEXPORT jint JNICALL Java_br_com_onda_Mp3Converter_flush(JNIEnv *env,jclass type,jlong handle,jbyteArray bytes){
 jbyte *out=(*env)->GetByteArrayElements(env,bytes,0);if(!out)return -1;int n=lame_encode_flush((lame_t)(intptr_t)handle,(unsigned char*)out,(*env)->GetArrayLength(env,bytes));(*env)->ReleaseByteArrayElements(env,bytes,out,0);if(n<0)fail(env,"Falha ao finalizar MP3");return n;
}
JNIEXPORT void JNICALL Java_br_com_onda_Mp3Converter_close(JNIEnv *env,jclass type,jlong handle){if(handle)lame_close((lame_t)(intptr_t)handle);}
