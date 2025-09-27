import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}
// profile page where we can se name and creditse
class _ProfileState extends State<Profile> {
  final _firebaseAuth = FirebaseAuth.instance;
  final _firebaseDb = FirebaseFirestore.instance;
  User? get user => _firebaseAuth.currentUser;
  Future<Map<String, dynamic>?> getUserDetails() async {
    final username = await _firebaseDb.collection("Users").doc(user!.uid).get();
    return username.data();
    // return username;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile"), automaticallyImplyLeading: false),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getUserDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            Center(child: Text("Error ${snapshot.error} "));
          }
          var userData = snapshot!.data;
          return Card(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    // getUserDetails() ?? "No Name",
                    "${userData?['name'] ?? "No Name"}",
                    style: TextStyle(color: Colors.black, fontSize: 20),
                  ),
                  Text(
                    user!.email ?? "No Email",
                    style: TextStyle(color: Colors.black, fontSize: 20),
                  ),
                  Text("Credits Remain: ${userData?['credits']}"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
