#include <jni.h>
#include <atomic>
#include <algorithm>
#include <mutex>
#include <string>
#include <vector>
#include <memory>
#include <exception>
#include "llama.h"
struct OndaAi {llama_model *model=nullptr;llama_context *ctx=nullptr;std::atomic<bool> cancelled{false};};
static void fail(JNIEnv *e,const char *message){e->ThrowNew(e->FindClass("java/io/IOException"),message);}
static jbyteArray bytes(JNIEnv *e,const std::string &text){auto out=e->NewByteArray((jsize)text.size());if(out)e->SetByteArrayRegion(out,0,(jsize)text.size(),reinterpret_cast<const jbyte*>(text.data()));return out;}
struct OndaLoadCancel {JavaVM *vm;JNIEnv *owner;jobject object;jmethodID method;
 OndaLoadCancel(JNIEnv *env,jobject value):owner(env){env->GetJavaVM(&vm);object=env->NewGlobalRef(value);jclass type=env->GetObjectClass(value);method=env->GetMethodID(type,"cancelled","()Z");env->DeleteLocalRef(type);}
 ~OndaLoadCancel(){if(object)owner->DeleteGlobalRef(object);}
 static bool progress(float,void *data){auto *c=static_cast<OndaLoadCancel*>(data);JNIEnv *env=nullptr;bool attached=false;if(c->vm->GetEnv(reinterpret_cast<void**>(&env),JNI_VERSION_1_6)==JNI_EDETACHED){
#ifdef __ANDROID__
 if(c->vm->AttachCurrentThread(&env,nullptr)!=JNI_OK)return false;
#else
 if(c->vm->AttachCurrentThread(reinterpret_cast<void**>(&env),nullptr)!=JNI_OK)return false;
#endif
 attached=true;}bool stop=env->CallBooleanMethod(c->object,c->method);if(env->ExceptionCheck()){env->ExceptionClear();stop=true;}if(attached)c->vm->DetachCurrentThread();return !stop;}
};
static std::once_flag initialized;
extern "C" JNIEXPORT jlong JNICALL Java_br_com_onda_LocalAiEngine_open(JNIEnv *e,jclass,jstring path,jint threads,jobject cancellation){
 try{OndaLoadCancel loading(e,cancellation);if(e->ExceptionCheck())return 0;std::call_once(initialized,[]{llama_backend_init();});const char *name=e->GetStringUTFChars(path,nullptr);if(!name)return 0;auto modelParams=llama_model_default_params();modelParams.n_gpu_layers=0;modelParams.use_mmap=true;modelParams.progress_callback=OndaLoadCancel::progress;modelParams.progress_callback_user_data=&loading;llama_model *model=llama_model_load_from_file(name,modelParams);e->ReleaseStringUTFChars(path,name);if(!model){fail(e,"Não foi possível abrir o modelo de IA local.");return 0;}
 if(!OndaLoadCancel::progress(1,&loading)){llama_model_free(model);fail(e,"Pedido interrompido");return 0;}auto params=llama_context_default_params();params.n_ctx=2048;params.n_batch=128;params.n_ubatch=128;params.n_threads=std::max(1,std::min(2,(int)threads));params.n_threads_batch=params.n_threads;params.no_perf=true;llama_context *ctx=llama_init_from_model(model,params);if(!ctx){llama_model_free(model);fail(e,"Não há memória suficiente para este modelo.");return 0;}auto *state=new OndaAi;state->model=model;state->ctx=ctx;return reinterpret_cast<jlong>(state);
 }catch(const std::exception &){fail(e,"Não foi possível reservar memória para a IA.");return 0;}
}
extern "C" JNIEXPORT jbyteArray JNICALL Java_br_com_onda_LocalAiEngine_run(JNIEnv *e,jclass,jlong handle,jbyteArray input,jint maximum,jobject listener){
 auto *s=reinterpret_cast<OndaAi*>(handle);if(!s||!input){fail(e,"IA local encerrada.");return nullptr;}int size=e->GetArrayLength(input);if(size<1||size>16000){fail(e,"O pedido é muito longo. Comece uma nova conversa.");return nullptr;}std::string prompt(size,'\0');e->GetByteArrayRegion(input,0,size,reinterpret_cast<jbyte*>(&prompt[0]));if(e->ExceptionCheck())return nullptr;
 const llama_vocab *vocab=llama_model_get_vocab(s->model);int n=-llama_tokenize(vocab,prompt.data(),size,nullptr,0,true,true);int limit=std::max(1,std::min(640,(int)maximum));if(n<=0||n+limit>=2048){fail(e,"A conversa está longa para este modelo. Limpe a conversa e envie um pedido menor.");return nullptr;}std::vector<llama_token> tokens(n);if(llama_tokenize(vocab,prompt.data(),size,tokens.data(),n,true,true)<0){fail(e,"Não foi possível preparar o pedido.");return nullptr;}
 llama_memory_clear(llama_get_memory(s->ctx),true);llama_set_abort_callback(s->ctx,[](void *data){return static_cast<OndaAi*>(data)->cancelled.load();},s);
 auto sampler=std::unique_ptr<llama_sampler,decltype(&llama_sampler_free)>(llama_sampler_chain_init(llama_sampler_chain_default_params()),llama_sampler_free);llama_sampler_chain_add(sampler.get(),llama_sampler_init_penalties(64,1.12f,0,0));llama_sampler_chain_add(sampler.get(),llama_sampler_init_greedy());std::string text;int result=0;
 for(int offset=0;offset<n;offset+=128){if(s->cancelled.load())break;int count=std::min(128,n-offset);result=llama_decode(s->ctx,llama_batch_get_one(tokens.data()+offset,count));if(result!=0)break;}
 jclass callback=listener?e->GetObjectClass(listener):nullptr;jmethodID update=callback?e->GetMethodID(callback,"changed","([B)V"):nullptr;
 if(!e->ExceptionCheck()&&result==0)for(int i=0;i<limit&&!s->cancelled.load();i++){llama_token token=llama_sampler_sample(sampler.get(),s->ctx,-1);if(llama_vocab_is_eog(vocab,token))break;char piece[256];int length=llama_token_to_piece(vocab,token,piece,sizeof(piece),0,false);if(length<0){result=-1;break;}text.append(piece,length);if(update&&i%12==0){jbyteArray chunk=bytes(e,text);if(chunk){e->CallVoidMethod(listener,update,chunk);e->DeleteLocalRef(chunk);}if(e->ExceptionCheck())break;}result=llama_decode(s->ctx,llama_batch_get_one(&token,1));if(result!=0)break;}
 llama_set_abort_callback(s->ctx,nullptr,nullptr);if(callback)e->DeleteLocalRef(callback);if(e->ExceptionCheck())return nullptr;if(s->cancelled.load())return bytes(e,"");if(result!=0){fail(e,"A IA não conseguiu concluir. Tente um pedido menor ou o modelo leve.");return nullptr;}return bytes(e,text);
}
extern "C" JNIEXPORT void JNICALL Java_br_com_onda_LocalAiEngine_abort(JNIEnv*,jclass,jlong handle){auto *s=reinterpret_cast<OndaAi*>(handle);if(s)s->cancelled.store(true);}
extern "C" JNIEXPORT void JNICALL Java_br_com_onda_LocalAiEngine_destroy(JNIEnv*,jclass,jlong handle){auto *s=reinterpret_cast<OndaAi*>(handle);if(s){llama_free(s->ctx);llama_model_free(s->model);delete s;}}
