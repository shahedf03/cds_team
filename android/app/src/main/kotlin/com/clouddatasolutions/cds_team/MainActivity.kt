package com.clouddatasolutions.cds_team

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth needs a FragmentActivity to host the biometric prompt.
// Extending plain FlutterActivity makes the fingerprint dialog fail at
// runtime on Android.
class MainActivity : FlutterFragmentActivity()
