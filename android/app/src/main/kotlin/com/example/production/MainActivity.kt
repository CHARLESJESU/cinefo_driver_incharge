package com.vlabs.cinefo_driver

import android.app.PendingIntent
import android.content.Intent
import android.content.IntentFilter
import android.nfc.NfcAdapter
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    private var nfcAdapter: NfcAdapter? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)
    }

    override fun onResume() {
        super.onResume()

        nfcAdapter?.let {
            // Intent to bring this activity to front
            val intent = Intent(this, javaClass).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)

            val pendingIntent = PendingIntent.getActivity(
                this, 0, intent,
                PendingIntent.FLAG_MUTABLE // Use FLAG_MUTABLE for Android 12+
            )

            // Optional: filters (empty = accept all)
            val filters = arrayOf<IntentFilter>()

            // This filters for MIFARE and NfcA tags only
            val techLists = arrayOf(
                arrayOf("android.nfc.tech.NfcA"),
                arrayOf("android.nfc.tech.MifareClassic")
            )

            // Enable foreground dispatch
            it.enableForegroundDispatch(this, pendingIntent, filters, techLists)
        }
    }

    override fun onPause() {
        super.onPause()
        nfcAdapter?.disableForegroundDispatch(this)
    }
}
