#include <jni.h>
#include <string>

#include "AudioEngine.h"

extern "C" {

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void* /*reserved*/) {
    AudioEngine::Instance().SetJavaVM(vm);
    return JNI_VERSION_1_6;
}

JNIEXPORT jboolean JNICALL
Java_net_djbird_toney_AudioEngineBridge_nativeLoad(JNIEnv* env, jobject /*thiz*/, jstring path) {
    const char* cPath = env->GetStringUTFChars(path, nullptr);
    bool ok = AudioEngine::Instance().Load(cPath ? cPath : "");
    env->ReleaseStringUTFChars(path, cPath);
    return ok ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jboolean JNICALL
Java_net_djbird_toney_AudioEngineBridge_nativePlay(JNIEnv* /*env*/, jobject /*thiz*/) {
    return AudioEngine::Instance().Play() ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jboolean JNICALL
Java_net_djbird_toney_AudioEngineBridge_nativePause(JNIEnv* /*env*/, jobject /*thiz*/) {
    return AudioEngine::Instance().Pause() ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jboolean JNICALL
Java_net_djbird_toney_AudioEngineBridge_nativeStop(JNIEnv* /*env*/, jobject /*thiz*/) {
    return AudioEngine::Instance().Stop() ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jboolean JNICALL
Java_net_djbird_toney_AudioEngineBridge_nativeSeek(JNIEnv* /*env*/, jobject /*thiz*/, jlong position_ms) {
    return AudioEngine::Instance().SeekMs(static_cast<int64_t>(position_ms))
               ? JNI_TRUE
               : JNI_FALSE;
}

JNIEXPORT jboolean JNICALL
Java_net_djbird_toney_AudioEngineBridge_nativeSetVolume(JNIEnv* /*env*/, jobject /*thiz*/, jdouble volume) {
    return AudioEngine::Instance().SetVolume(volume) ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jdouble JNICALL
Java_net_djbird_toney_AudioEngineBridge_nativeGetVolume(JNIEnv* /*env*/, jobject /*thiz*/) {
    return AudioEngine::Instance().GetVolume();
}

JNIEXPORT jobject JNICALL
Java_net_djbird_toney_AudioEngineBridge_nativeExtractMetadata(JNIEnv* env, jobject /*thiz*/, jstring path) {
    const char* cPath = env->GetStringUTFChars(path, nullptr);
    jobject map = AudioEngine::Instance().ExtractMetadata(env, cPath ? cPath : "");
    env->ReleaseStringUTFChars(path, cPath);
    return map;
}

JNIEXPORT void JNICALL
Java_net_djbird_toney_AudioEngineBridge_nativeSetOnPlaybackEnded(JNIEnv* env, jobject /*thiz*/, jobject runnable) {
    AudioEngine::Instance().SetOnPlaybackEnded(env, runnable);
}

}
