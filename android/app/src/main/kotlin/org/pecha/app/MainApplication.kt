package org.pecha.app

import co.ab180.airbridge.flutter.AirbridgeFlutter
import android.app.Application

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        AirbridgeFlutter.initializeSDK(this, BuildConfig.AIRBRIDGE_APP_NAME, BuildConfig.AIRBRIDGE_SDK_TOKEN)
    }
}
