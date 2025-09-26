import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:new_era_assignment/Home/HomePage.dart';
import 'package:new_era_assignment/Home/profile.dart';
import 'package:new_era_assignment/Home/teams.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _firebaseAuth = FirebaseAuth.instance;
  final _firebaseDb = FirebaseFirestore.instance;
  User? get user => _firebaseAuth.currentUser;
  int currentPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    List _screens = [Homepage(), Teams(), Profile()];

    return Scaffold(
      body: _screens[currentPageIndex],
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        destinations: <Widget>[
          NavigationDestination(icon: Icon(Icons.home), label: "Home"),
          NavigationDestination(icon: Icon(Icons.people), label: "Teams"),
          NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
      // body: ListView.builder(itemBuilder: ),
    );
  }
}
