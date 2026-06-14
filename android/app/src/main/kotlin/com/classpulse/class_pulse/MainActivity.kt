package com.classpulse.class_pulse

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        configureEdgeToEdge()
    }

    override fun onPostResume() {
        super.onPostResume()
        configureEdgeToEdge()
    }

    private fun configureEdgeToEdge() {
        // Force edge-to-edge layout so app draws behind system bars
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // Make bars fully transparent (using 0x00000001 to bypass Android/Samsung black fallback bug)
        window.navigationBarColor = 0x00000001
        window.statusBarColor = android.graphics.Color.TRANSPARENT

        // Disable system-enforced contrast scrim (Android 10+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
            window.isStatusBarContrastEnforced = false
        }
    }
}
