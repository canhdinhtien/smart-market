import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // Thông số Web (Nếu bạn chưa tạo Web app trên Firebase, các thông số này dựa trên Android)
      return const FirebaseOptions(
        apiKey: 'AIzaSyC9BoIAKqOiaZY8SwkHubVfoaS3G_d9oNg',
        appId: '1:1098703054802:web:e7d18f16fb5dbb0c538a0b',
        messagingSenderId: '1098703054802',
        projectId: 'smart-market-71fb8',
        authDomain: 'smart-market-71fb8.firebaseapp.com',
        storageBucket: 'smart-market-71fb8.firebasestorage.app',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'AIzaSyC9BoIAKqOiaZY8SwkHubVfoaS3G_d9oNg',
          appId: '1:1098703054802:android:e7d18f16fb5dbb0c538a0b',
          messagingSenderId: '1098703054802',
          projectId: 'smart-market-71fb8',
          storageBucket: 'smart-market-71fb8.firebasestorage.app',
        );
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: 'AIzaSyC9BoIAKqOiaZY8SwkHubVfoaS3G_d9oNg',
          appId: '1:1098703054802:ios:e7d18f16fb5dbb0c538a0b',
          messagingSenderId: '1098703054802',
          projectId: 'smart-market-71fb8',
          storageBucket: 'smart-market-71fb8.firebasestorage.app',
          iosBundleId: 'com.group7.smart_market',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}