import 'dart:async';
import 'package:card_warrior/ui/game_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchingPage extends StatefulWidget {
  const MatchingPage({super.key});

  @override
  State<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage> {
  bool isMatched = false;
  String matchMessage = '';
  Timer? _timer;
  final _authentication = FirebaseAuth.instance;
  User? loggedUser;
  String? userId = '';
  String matchedUserId = '';

  void initState() {
    super.initState();
    getCurrentUser();
    userId = loggedUser?.email?.split('@').first;
    startMatching();
  }

  void getCurrentUser() {
    try {
      final user = _authentication.currentUser;
      if (user != null) {
        loggedUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  void startMatching() async {
    await FirebaseFirestore.instance
        .collection('UserMatching')
        .doc('matching')
        .set({
      'users': FieldValue.arrayUnion([userId]) // 접속 중인 유저 추가
    }, SetOptions(merge: true));

    print(userId);
    await FirebaseFirestore.instance
        .collection('UserMatching')
        .doc(userId)
        .set({
      'matchedWith': '',
      'status': 'notMatched',
    }, SetOptions(merge: true));

    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      findMatch(); // 매칭을 찾는 함수 호출
    });
  }

  Future<void> findMatch() async {
    try {
      DocumentSnapshot myMatchedSnapshot = await FirebaseFirestore.instance
          .collection('UserMatching')
          .doc(userId)
          .get();

      if (myMatchedSnapshot.exists) {
        // 만약 매칭이 이미 되어 있으면
        dynamic status = myMatchedSnapshot['status'];
        if (status == 'matched') {
          setState(() {
            matchedUserId = myMatchedSnapshot['matchedWith'];
            matchMessage = '유저를 찾았습니다.';
            isMatched = true;
          });
          _timer?.cancel();

          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      MatchedPage(matchedUserId: matchedUserId)));
        } else {
          // 매칭이 되어 있지 않는다면
          DocumentSnapshot snapshot = await FirebaseFirestore.instance
              .collection('UserMatching')
              .doc('matching')
              .get();

          if (snapshot.exists) {
            List<dynamic> users = snapshot['users'];
            if (users.length > 1) {
              // 매칭 대기 2명이상 존재(본인 포함임)
              matchedUserId = (users
                    ..where((id) => id != userId).toList()
                    ..shuffle())
                  .first;

              //매칭 성공
              setState(() {
                matchMessage = '유저를 찾았습니다.';
                isMatched = true;
              });
              _timer?.cancel();

              await FirebaseFirestore.instance
                  .collection('UserMatching')
                  .doc('matching')
                  .set({
                'users': FieldValue.arrayRemove([userId]),
              }, SetOptions(merge: true));

              await FirebaseFirestore.instance
                  .collection('UserMatching')
                  .doc('matching')
                  .set({
                'users': FieldValue.arrayRemove([matchedUserId]),
              }, SetOptions(merge: true));

              await FirebaseFirestore.instance
                  .collection('UserMatching')
                  .doc(matchedUserId)
                  .set({
                'matchedWith': userId,
                'status': 'matched',
              }, SetOptions(merge: true));

              await FirebaseFirestore.instance
                  .collection('UserMatching')
                  .doc(userId)
                  .set({
                'matchedWith': matchedUserId,
                'status': 'matched',
              }, SetOptions(merge: true));

              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          MatchedPage(matchedUserId: matchedUserId)));
            } else {
              setState(() {
                matchMessage = '매칭 중입니다.';
                isMatched = false;
              });
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        matchMessage = '오류가 발생했습니다.';
        isMatched = true;
      });
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // 위젯이 dispose될 때 타이머 중지
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('매칭 중'),
      ),
      body: Center(
        child: isMatched ? Text(matchMessage) : CircularProgressIndicator(),
      ),
    );
  }
}

class MatchedPage extends StatefulWidget {
  final String matchedUserId;
  MatchedPage({required this.matchedUserId});

  @override
  State<MatchedPage> createState() => _MatchedPageState();
}


class _MatchedPageState extends State<MatchedPage> {
  Timer? _timer; // 타이머 변수

  @override
  void initState() {
    super.initState();
    // 5초 후에 다른 페이지로 이동
    _timer = Timer(Duration(seconds: 5), () {
      Navigator.pushNamed(context, '/gamepage');
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 위젯이 dispose될 때 타이머 중지
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('매칭 완료'),
      ),
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('매칭된 유저'),
              SizedBox(
                height: 20,
              ),
              Text(widget.matchedUserId)
            ],
          )
      ),
    );
  }
}


