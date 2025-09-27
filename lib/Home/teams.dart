import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Teams extends StatefulWidget {
  const Teams({super.key});

  @override
  State<Teams> createState() => _TeamsState();
}
// teams page where we can follow and unfollow them

class _TeamsState extends State<Teams> {
  final _firebaseDb = FirebaseFirestore.instance;
  final _firebaseAuth = FirebaseAuth.instance;
  User? get user => _firebaseAuth.currentUser;
  // bool followed = false;
  Future<List<Map<String, dynamic>>> temasList() async {
    try {
      final snapshot = await _firebaseDb.collection("Teams").get();
      final list =
          snapshot.docs.map((doc) {
            return {"id": doc.id, ...doc.data()};
          }).toList();
      return list;
    } catch (e) {
      print("Error Fetching while Having Error$e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Teams"), automaticallyImplyLeading: false),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: temasList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            Center(child: Text("Error occur ${snapshot.error}"));
          }
          final teams = snapshot.data ?? [];

          return ListView.builder(
            itemCount: teams.length,

            itemBuilder: (context, index) {
              final team = teams[index];
              List<dynamic> followedBy = team["followedBy"] ?? [];
              final bool isFollowed = followedBy.contains(user!.uid);
              return GestureDetector(
                onTap: () {
                  
                },
                child: Card(
                  child: Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("${team['name'] ?? "No Team"}"),
                            Spacer(),

                            // if(team['followedBy'])
                            ElevatedButton(
                              onPressed: () async {
                                final teamId = team['id'];
                                // team['followedBy']
                                if (isFollowed) {
                                  _firebaseDb
                                      .collection("Teams")
                                      .doc(teamId)
                                      .update({
                                        "followedBy": FieldValue.arrayRemove([
                                          user!.uid,
                                        ]),
                                      });
                                } else {
                                  _firebaseDb
                                      .collection("Teams")
                                      .doc(teamId)
                                      .update({
                                        "followedBy": FieldValue.arrayUnion([
                                          user!.uid,
                                        ]),
                                      });
                                }
                                setState(() {
                                });
                              },
                              child: Text(isFollowed ? "Follow" : "Following"),
                            ),
                          ],
                        ),
                        Text("Followers : ${team["followedBy"].length - 1}"),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
