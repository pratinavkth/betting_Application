import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class Ongoinmatch extends StatefulWidget {
  const Ongoinmatch({super.key});

  @override
  State<Ongoinmatch> createState() => _OngoinmatchState();
}

class _OngoinmatchState extends State<Ongoinmatch> {
  final _firebaseAuth = FirebaseAuth.instance;
  final _firebaseDb = FirebaseFirestore.instance;
  User? get user => _firebaseAuth.currentUser;

  String? teamId;
  YoutubePlayerController? _controller;

  final TextEditingController _chatController = TextEditingController();
  final TextEditingController _betAmountController = TextEditingController();

  String? selectedTeam;
  int betAmount = 0;
  String? selectedWinner;

  Future<Map<String, dynamic>?> eventData(String teamId) async {
    try {
      final snapshot = await _firebaseDb.collection("Events").doc(teamId).get();
      return snapshot.data();
    } catch (e) {
      print("Error fetching event: $e");
      return null;
    }
  }

  Future<Map<String, String>> fetchTeamNames(List<dynamic> teamIds) async {
    Map<String, String> teamsMap = {};
    for (String id in teamIds) {
      final teamDoc = await _firebaseDb.collection("Teams").doc(id).get();
      if (teamDoc.exists) {
        teamsMap[id] = teamDoc["name"];
      }
    }
    return teamsMap;
  }

  Future<void> sendMessage() async {
    if (_chatController.text.trim().isEmpty) return;

    await _firebaseDb.collection("Events").doc(teamId).collection("chats").add({
      "message": _chatController.text.trim(),
      "senderId": user!.uid,
      "timestamp": FieldValue.serverTimestamp(),
    });

    _chatController.clear();
  }

  Future<void> placeBet() async {
    if (selectedTeam == null || betAmount <= 0) return;

    final userRef = _firebaseDb.collection("Users").doc(user!.uid);
    final userSnap = await userRef.get();
    int credits = userSnap["credits"] ?? 1000;

    if (betAmount > credits) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Not enough credits!")));
      return;
    }

    await _firebaseDb
        .collection("Events")
        .doc(teamId)
        .collection("Bets")
        .doc(user!.uid)
        .set({"teamId": selectedTeam, "amount": betAmount});

    await userRef.update({"credits": credits - betAmount});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Bet placed successfully!")));
  }

  Future<void> declareWinner(String winnerId) async {
    setState(() {
      selectedWinner = winnerId;
    });

    await _firebaseDb.collection("Events").doc(teamId).update({
      "winner": winnerId,
    });

    // Process winnings
    final betsSnap =
        await _firebaseDb
            .collection("Events")
            .doc(teamId)
            .collection("Bets")
            .get();

    for (var betDoc in betsSnap.docs) {
      final bet = betDoc.data();
      if (bet["teamId"] == winnerId) {
        int winAmount = bet["amount"] * 2;

        await _firebaseDb.runTransaction((transaction) async {
          final userRef = _firebaseDb.collection("Users").doc(betDoc.id);
          final userSnap = await transaction.get(userRef);
          if (userSnap.exists) {
            int currentCredits = userSnap["credits"] ?? 1000;
            transaction.update(userRef, {
              "credits": currentCredits + winAmount,
            });
          }
        });
      }
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Winner updated!")));
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    teamId ??= args['docId'];

    return Scaffold(
      appBar: AppBar(title: const Text("Event Details")),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: eventData(teamId!),
        builder: (context, eventSnap) {
          if (eventSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (eventSnap.hasError) {
            return Center(child: Text("Error: ${eventSnap.error}"));
          }
          if (!eventSnap.hasData || eventSnap.data == null) {
            return const Center(child: Text("No Event Found"));
          }

          final eventDetails = eventSnap.data!;
          final videoUrl = eventDetails["youtubeUrl"] ?? "";
          final teamIds = List<String>.from(eventDetails["teams"] ?? []);
          final winnerFromDb = eventDetails["winner"];

          if (videoUrl.isNotEmpty && _controller == null) {
            final videoId = YoutubePlayer.convertUrlToId(videoUrl);
            if (videoId != null) {
              _controller = YoutubePlayerController(
                initialVideoId: videoId,
                flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
              );
            }
          }

          return FutureBuilder<Map<String, String>>(
            future: fetchTeamNames(teamIds),
            builder: (context, teamSnap) {
              if (teamSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!teamSnap.hasData || teamSnap.data!.isEmpty) {
                return const Center(child: Text("Teams not found"));
              }

              final teamsMap = teamSnap.data!;

              if (selectedWinner == null ||
                  !teamsMap.containsKey(selectedWinner)) {
                selectedWinner =
                    winnerFromDb != null && teamsMap.containsKey(winnerFromDb)
                        ? winnerFromDb
                        : null;
              }

              return Column(
                children: [
                  if (_controller != null)
                    YoutubePlayer(
                      controller: _controller!,
                      showVideoProgressIndicator: true,
                    )
                  else
                    const Text("No Video Available"),

                  Card(
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text(
                            "Place Your Bet",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DropdownButton<String>(
                            value: selectedTeam,
                            hint: const Text("Select Team"),
                            items:
                                teamsMap.entries.map((entry) {
                                  return DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  );
                                }).toList(),
                            onChanged: (val) {
                              setState(() => selectedTeam = val);
                            },
                          ),
                          TextField(
                            controller: _betAmountController,
                            decoration: const InputDecoration(
                              labelText: "Bet Amount",
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              setState(
                                () => betAmount = int.tryParse(val) ?? 0,
                              );
                            },
                          ),
                          ElevatedButton(
                            onPressed: placeBet,
                            child: const Text("Place Bet"),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          _firebaseDb
                              .collection("Events")
                              .doc(teamId)
                              .collection("chats")
                              .orderBy("timestamp", descending: true)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final messages = snapshot.data!.docs;

                        return ListView.builder(
                          reverse: true,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isMe = msg["senderId"] == user!.uid;

                            return Align(
                              alignment:
                                  isMe
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      isMe
                                          ? Colors.blueAccent
                                          : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  msg["message"] ?? "",
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            decoration: const InputDecoration(
                              hintText: "Type a message...",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: sendMessage,
                        ),
                      ],
                    ),
                  ),

                  Card(
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text(
                            "Declare Winner",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DropdownButton<String>(
                            value: selectedWinner,
                            hint: const Text("Select Winner"),
                            items:
                                teamsMap.entries.map((entry) {
                                  return DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  );
                                }).toList(),
                            onChanged: (val) {
                              if (val != null) declareWinner(val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (selectedWinner != null)
                    Text(
                      "Winner: ${teamsMap[selectedWinner] ?? selectedWinner}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
