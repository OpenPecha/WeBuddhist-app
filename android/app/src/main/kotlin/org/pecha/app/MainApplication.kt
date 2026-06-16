package org.pecha.app

import co.ab180.airbridge.flutter.AirbridgeFlutter
import android.app.Application

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        AirbridgeFlutter.initializeSDK(this, "webuddhistdev", "3f20a516a1ec42faa2ad9bd9a23fb9ec")
    }
}
