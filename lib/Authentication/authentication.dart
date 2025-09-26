import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Authentication {
  final _firebaseAuth = FirebaseAuth.instance;
  final _firebaseDb = FirebaseFirestore.instance;

  Future<void> signup(String name, String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;
      if (user != null) {
        await _firebaseDb.collection("Users").doc(user!.uid).set({
          "name": name,
          "email": email,
          "credits": 1000,
          "followings": [],
          "createdAt": FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error during signup: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> signin(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;
      if (user != null) {
        DocumentSnapshot doc =
            await _firebaseDb.collection("Users").doc(user.uid).get();
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>;
        } else {
          print("User document not found in Firestore");
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      print("Error during signin: $e");
      rethrow;
    }
  }

  Future<void> signout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print("Error during signout: $e");
      rethrow;
    }
  }
}
