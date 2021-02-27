// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase/firebase.dart';

class AuthService {
  static Future<String> getUserId() async {
    if (auth().currentUser != null) {
      return auth().currentUser.uid;
    } else {
      UserCredential userId = await auth().signInAnonymously();
      return userId.user.uid;
    }
  }
}
