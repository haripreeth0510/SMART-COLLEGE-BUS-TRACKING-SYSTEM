// Firebase options for Flutter app - campus_go
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBMX-plrjgxXw13ek2Ej53LFhE4n9BoaKE',
    appId: '1:63402055837:web:01341ef463ea091a27dc74',
    messagingSenderId: '63402055837',
    projectId: 'bus-tracking-system-32f89',
    authDomain: 'bus-tracking-system-32f89.firebaseapp.com',
    databaseURL: 'https://bus-tracking-system-32f89-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'bus-tracking-system-32f89.firebasestorage.app',
    measurementId: 'G-YVM1PTZCMM',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBmu18VezBCmDWYd41z-Tly__Gl5KhseMk',
    appId: '1:63402055837:android:624ce7e77d4934ef27dc74',
    messagingSenderId: '63402055837',
    projectId: 'bus-tracking-system-32f89',
    databaseURL: 'https://bus-tracking-system-32f89-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'bus-tracking-system-32f89.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBmu18VezBCmDWYd41z-Tly__Gl5KhseMk',
    appId: '1:63402055837:android:624ce7e77d4934ef27dc74',
    messagingSenderId: '63402055837',
    projectId: 'bus-tracking-system-32f89',
    databaseURL: 'https://bus-tracking-system-32f89-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'bus-tracking-system-32f89.firebasestorage.app',
  );
}
