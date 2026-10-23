package br.com.onda;
import android.app.Activity;
import java.util.function.Consumer;

/** Local classifier runs only on a submitted phrase. No network or background work. */
final class VoiceAssistant {
    void interpret(Activity activity,String phrase,Consumer<VoiceCommand> result){
        result.accept(VoiceAiSettings.enabled(activity)?LocalVoiceModel.interpret(phrase):VoiceCommand.parse(phrase));
    }
}
