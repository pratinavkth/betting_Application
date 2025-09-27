import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

// then this homepage
class _HomepageState extends State<Homepage> {
  final _firebaseDb = FirebaseFirestore.instance;
  Future<List<Map<String, dynamic>>> fetchNews() async {
    try {
      final snapshot = await _firebaseDb.collection("Events").get();
      return snapshot.docs.map((doc) {
        return {"id": doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      print(e.toString());
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ongoing Challenges"),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder(
        future: fetchNews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text("No events found"));
          }
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final event = data[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/ongoingMatch',
                    arguments: {"docId": event['id']},
                  );
                },
                child: Card(
                  elevation: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1.0),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          event['title'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (event['imageUrl'] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              event['imageUrl'],
                              height: 350,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          event['description'] ?? 'No Description',
                          style: const TextStyle(color: Colors.grey),
                        ),
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

// https://firebasestorage.googleapis.com/v0/b/neweraassignment-b10f1.firebasestorage.app/o/India-Pakistan-Live-Match.jpg?alt=media&token=987667c6-e4a7-460f-b9f3-031d1514a9c6
// https://firebasestorage.googleapis.com/v0/b/neweraassignment-b10f1.firebasestorage.app/o/Screenshot%202025-09-24%20090755.png?alt=media&token=f5549f6d-1d9d-4a80-9d81-068c2d7e907f
// https://firebasestorage.googleapis.com/v0/b/neweraassignment-b10f1.firebasestorage.app/o/Screenshot%202025-09-24%20092028.png?alt=media&token=965f0393-466c-4ca9-92c7-7c06215fa078
