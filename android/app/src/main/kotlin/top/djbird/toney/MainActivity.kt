package top.djbird.toney

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Register the Android AudioEngine stub (FFmpeg-based engine can be added later).
        AudioEnginePlugin.registerWith(flutterEngine)
        MoodEnginePlugin.registerWith(this, flutterEngine)
    }
}
