#include <jni.h>
#include <atomic>
#include <memory>
#include <string>
#include <vector>
#include <algorithm>
#include <stdexcept>
#include "llama.h"

namespace {
llama_model * model = nullptr;
std::atomic<bool> stopped{false};
void fail(JNIEnv * env, const char * msg) { env->ThrowNew(env->FindClass("java/lang/IllegalStateException"), msg); }
std::string bytes(JNIEnv * env, jbyteArray value) {
    auto n = env->GetArrayLength(value); std::string s(n, '\0');
    env->GetByteArrayRegion(value, 0, n, reinterpret_cast<jbyte *>(s.data())); return s;
}
bool abort_eval(void *) { return stopped.load(); }
jbyteArray array(JNIEnv * env, const std::string & s) {
    auto out = env->NewByteArray(s.size());
    if (out) env->SetByteArrayRegion(out, 0, s.size(), reinterpret_cast<const jbyte *>(s.data()));
    return out;
}
int capacity() { return model ? std::min(8192,static_cast<int>(llama_model_n_ctx_train(model))) : 0; }
std::string format(const std::string & system,const std::string & request) {
    if(!model) throw std::runtime_error("Carregue um modelo primeiro.");
    llama_chat_message messages[]={{"system",system.c_str()},{"user",request.c_str()}};
    const char * tmpl=llama_model_chat_template(model,nullptr);
    int n=llama_chat_apply_template(tmpl,messages,2,true,nullptr,0);
    if(n<=0)throw std::runtime_error("Template do modelo não suportado.");
    std::vector<char> buffer(n+1);
    int written=llama_chat_apply_template(tmpl,messages,2,true,buffer.data(),buffer.size());
    if(written<=0||written>=static_cast<int>(buffer.size()))throw std::runtime_error("Falha ao preparar a solicitação.");
    return std::string(buffer.data(),written);
}

}
extern "C" JNIEXPORT void JNICALL Java_br_com_arakaki_codigolivre_NativeEngine_resetCancel(JNIEnv *, jclass) { stopped=false; }
extern "C" JNIEXPORT void JNICALL Java_br_com_arakaki_codigolivre_NativeEngine_cancel(JNIEnv *, jclass) { stopped=true; }
extern "C" JNIEXPORT void JNICALL Java_br_com_arakaki_codigolivre_NativeEngine_unload(JNIEnv *, jclass) {
    if (model) llama_model_free(model); model=nullptr;
}
extern "C" JNIEXPORT void JNICALL Java_br_com_arakaki_codigolivre_NativeEngine_load(JNIEnv * env, jclass, jbyteArray path) {
    try {
        static bool init=false; if (!init) { llama_backend_init(); init=true; }
        if (model) llama_model_free(model); model=nullptr;
        auto params=llama_model_default_params(); params.n_gpu_layers=0; params.use_mmap=true;
        model=llama_model_load_from_file(bytes(env,path).c_str(), params);
        if (!model) throw std::runtime_error("Modelo incompatível ou memória insuficiente. Use Qwen2.5-Coder Instruct GGUF Q4_K_M (1,5B ou 3B; 7B exige mais RAM).");
    } catch(const std::exception & e) { fail(env,e.what()); }
}
extern "C" JNIEXPORT jbyteArray JNICALL Java_br_com_arakaki_codigolivre_NativeEngine_generate(
        JNIEnv * env, jclass, jbyteArray sys, jbyteArray user, jobject callback, jint limit, jint threads) {
    try {
        if (!model) throw std::runtime_error("Importe e carregue um modelo GGUF primeiro.");
        std::string formatted=format(bytes(env,sys),bytes(env,user));
        const auto * vocab=llama_model_get_vocab(model);
        int count=-llama_tokenize(vocab,formatted.data(),formatted.size(),nullptr,0,true,true);
        int available=capacity()-count-1;
        if(count<=0||available<1)throw std::runtime_error("Trecho acima do contexto do modelo; a análise automática precisa dividi-lo novamente.");
        limit=limit<=0?available:std::min(static_cast<int>(limit),available);
        std::vector<llama_token> tokens(count);
        if (llama_tokenize(vocab,formatted.data(),formatted.size(),tokens.data(),count,true,true)!=count) throw std::runtime_error("Falha na tokenização.");
        auto cp=llama_context_default_params(); cp.n_ctx=capacity(); cp.n_batch=256; cp.n_ubatch=128;
        cp.n_threads=std::clamp(static_cast<int>(threads),1,8); cp.n_threads_batch=cp.n_threads;
        cp.abort_callback=abort_eval; cp.abort_callback_data=nullptr;
        std::unique_ptr<llama_context,decltype(&llama_free)> ctx(llama_init_from_model(model,cp),llama_free);
        if (!ctx) throw std::runtime_error("Não foi possível reservar memória para o contexto.");
        std::unique_ptr<llama_sampler,decltype(&llama_sampler_free)> sampler(llama_sampler_chain_init(llama_sampler_chain_default_params()),llama_sampler_free);
        llama_sampler_chain_add(sampler.get(),llama_sampler_init_top_k(40));
        llama_sampler_chain_add(sampler.get(),llama_sampler_init_top_p(0.9f,1));
        llama_sampler_chain_add(sampler.get(),llama_sampler_init_temp(0.2f));
        llama_sampler_chain_add(sampler.get(),llama_sampler_init_dist(42));
        auto cls=env->GetObjectClass(callback); auto method=env->GetMethodID(cls,"onText","([B)V");
        if (!method) return nullptr;
        for (int pos=0;pos<count && !stopped;pos+=256) {
            auto batch=llama_batch_get_one(tokens.data()+pos,std::min(256,count-pos));
            if (llama_decode(ctx.get(),batch)!=0 && !stopped) throw std::runtime_error("Falha no processamento do código.");
        }
        std::string output; bool complete=false;
        for(int i=0;i<limit && !stopped;i++) {
            auto token=llama_sampler_sample(sampler.get(),ctx.get(),-1);
            if (llama_vocab_is_eog(vocab,token)) { complete=true; break; }
            std::vector<char> piece(256); int size=llama_token_to_piece(vocab,token,piece.data(),piece.size(),0,true);
            if(size<0) { piece.resize(-size); size=llama_token_to_piece(vocab,token,piece.data(),piece.size(),0,true); }
            if(size<0) throw std::runtime_error("Falha ao decodificar resposta.");
            output.append(piece.data(),size);
            if(i%8==0) { auto chunk=array(env,output); env->CallVoidMethod(callback,method,chunk); env->DeleteLocalRef(chunk); if(env->ExceptionCheck()) return nullptr; }
            if (stopped) break;
            auto batch=llama_batch_get_one(&token,1);
            if(llama_decode(ctx.get(),batch)!=0 && !stopped) throw std::runtime_error("Falha durante a geração.");
        }
        if(stopped) output+="\n\n[Resposta interrompida pelo usuário; pode estar incompleta.]";
        else if(!complete) output+=limit==available?"\n\n[Contexto desta resposta esgotado; este trecho pode precisar de continuação.]":"\n\n[Resposta encerrada pelo modo Econômico; pode estar incompleta. Use Automático para mais espaço.]";
        return array(env,output);
    } catch(const std::exception & e) { fail(env,e.what()); return nullptr; }
}

extern "C" JNIEXPORT jboolean JNICALL Java_br_com_arakaki_codigolivre_NativeEngine_cancelled(JNIEnv *,jclass){return stopped.load();}
extern "C" JNIEXPORT jint JNICALL Java_br_com_arakaki_codigolivre_NativeEngine_capacity(JNIEnv *,jclass){return capacity();}
extern "C" JNIEXPORT jint JNICALL Java_br_com_arakaki_codigolivre_NativeEngine_count(JNIEnv * env,jclass,jbyteArray sys,jbyteArray user){
    try{auto p=format(bytes(env,sys),bytes(env,user));return -llama_tokenize(llama_model_get_vocab(model),p.data(),p.size(),nullptr,0,true,true);}
    catch(const std::exception & e){fail(env,e.what());return 0;}
}
