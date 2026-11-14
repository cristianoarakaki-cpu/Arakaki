#include <jni.h>
#include <atomic>
#include <algorithm>
#include <string>
#include <vector>
#include "whisper.h"
struct OndaWhisper {whisper_context *ctx;std::atomic<int> epoch{0};};
struct OndaAbort {OndaWhisper *engine;int epoch;};
static void fail(JNIEnv *e,const char *m){e->ThrowNew(e->FindClass("java/io/IOException"),m);}
extern "C" JNIEXPORT jlong JNICALL Java_br_com_onda_WhisperEngine_open(JNIEnv *e,jclass,jstring path){
 const char *name=e->GetStringUTFChars(path,nullptr);if(!name)return 0;
 auto params=whisper_context_default_params();params.use_gpu=false;
 whisper_context *ctx=whisper_init_from_file_with_params(name,params);e->ReleaseStringUTFChars(path,name);
 if(!ctx){fail(e,"Falha ao carregar modelo local Whisper");return 0;}auto *state=new OndaWhisper;state->ctx=ctx;return reinterpret_cast<jlong>(state);
}
extern "C" JNIEXPORT jbyteArray JNICALL Java_br_com_onda_WhisperEngine_run(JNIEnv *e,jclass,jlong handle,jfloatArray input,jstring lang,jint threads){
 auto *s=reinterpret_cast<OndaWhisper*>(handle);int n=e->GetArrayLength(input);if(!s||n<1600||n>16000*12){fail(e,"Trecho de áudio inválido");return nullptr;}
 std::vector<float> pcm(n);e->GetFloatArrayRegion(input,0,n,pcm.data());if(e->ExceptionCheck())return nullptr;
 const char *language=e->GetStringUTFChars(lang,nullptr);if(!language)return nullptr;
 if(whisper_lang_id(language)<0){e->ReleaseStringUTFChars(lang,language);fail(e,"Idioma não suportado no reconhecimento");return nullptr;}
 auto p=whisper_full_default_params(WHISPER_SAMPLING_GREEDY);p.n_threads=std::max(1,std::min(2,(int)threads));p.language=language;p.no_context=true;p.single_segment=true;p.no_timestamps=true;p.print_special=false;p.print_progress=false;p.print_realtime=false;p.print_timestamps=false;p.audio_ctx=512;p.max_tokens=64;p.temperature=0;p.temperature_inc=0;
 OndaAbort cancel{s,s->epoch.load()};p.abort_callback=[](void *user){auto *c=static_cast<OndaAbort*>(user);return c->engine->epoch.load()!=c->epoch;};p.abort_callback_user_data=&cancel;
 int result=whisper_full(s->ctx,p,pcm.data(),n);e->ReleaseStringUTFChars(lang,language);if(s->epoch.load()!=cancel.epoch)return e->NewByteArray(0);
 if(result!=0){fail(e,"Falha ao reconhecer este trecho de áudio");return nullptr;}
 std::string text;for(int i=0;i<whisper_full_n_segments(s->ctx);i++){if(whisper_full_get_segment_no_speech_prob(s->ctx,i)>.65f)continue;text+=whisper_full_get_segment_text(s->ctx,i);}
 jbyteArray out=e->NewByteArray((jsize)text.size());if(out)e->SetByteArrayRegion(out,0,(jsize)text.size(),reinterpret_cast<const jbyte*>(text.data()));return out;
}
extern "C" JNIEXPORT void JNICALL Java_br_com_onda_WhisperEngine_abort(JNIEnv*,jclass,jlong h){auto *s=reinterpret_cast<OndaWhisper*>(h);if(s)s->epoch.fetch_add(1);}
extern "C" JNIEXPORT void JNICALL Java_br_com_onda_WhisperEngine_destroy(JNIEnv*,jclass,jlong h){auto *s=reinterpret_cast<OndaWhisper*>(h);if(s){whisper_free(s->ctx);delete s;}}
