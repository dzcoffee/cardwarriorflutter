import 'dart:async';

import 'package:card_warrior/game_service/main_service.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  MainService gameInstance = MainService();
  bool _isMyTurn = true;

  final _authentication = FirebaseAuth.instance;
  User? loggedUser;
  String? userId = '';
  String? docId;
  StreamSubscription<DocumentSnapshot>? matchNewSubs;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    userId = loggedUser?.email?.split('@').first;
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


  @override
  void dispose(){
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 여기서 arguments를 받아올 수 있습니다
    final String? arguments = ModalRoute.of(context)?.settings.arguments as String?;
    if (arguments != null) {
      docId = arguments; // docId 변수에 저장
      listenToNewMatch(docId!);
    }
  }

  void listenToNewMatch(String docId) {
    matchNewSubs = FirebaseFirestore.instance.collection('matches').doc(docId).snapshots().listen((docSnapshot) {
      print('docId는 다음과 같습니다' + docId);
    });
  }

  void stopSubs(){
    if(matchNewSubs != null){
      print('매치성공 구독 종료');
      matchNewSubs!.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
          children: [
            GameWidget(
              game: gameInstance,
            ),
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                iconSize: 50,
                onPressed: () {
                  setState(() {
                    _showMenuPopup(context);
                  });
                },
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 75,
                height: 40,
                child: ElevatedButton(
                  onPressed: (){
                    setState(() {
                      _isMyTurn = false;
                    });
                  },
                  child: Text('내 턴 종료'),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 75,
                height: 40,
                child: ElevatedButton(
                  onPressed: (){
                    setState(() {
                      _isMyTurn = true;
                    });
                  },
                  child: const Text('상대 턴 종료'),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if(gameInstance.cards.length > 3) {
                      gameInstance.allMoveLeft();
                    }
                  },
                      icon: const Icon(Icons.arrow_back, size: 40, color: Colors.white),
                    ),
                    Container(
                      width: 150,
                      height: 70,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[900],
                      ),
                      child: Center(
                        child: Text(
                          '카드 놓는 곳',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if(gameInstance.cards.length > 3) {
                      gameInstance.allMoveRight();
                    }
                  },
                      icon: const Icon(Icons.arrow_forward, size: 40, color: Colors.white),
                    ),
                  ],
                ),
              ),
            )
          ],
        )
    );
  }


  void _showMenuPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Expanded(child: SizedBox()),
              const Expanded(child: SizedBox()),
              const Expanded(
                child: Text(
                  'Menu',
                  textAlign: TextAlign.center,
                ),
              ),
              const Expanded(child: SizedBox()),
              ElevatedButton(
                onPressed: (){
                  Navigator.pop(context);
                },
                child: const Icon(Icons.close),
              )
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showExitConfirmationPopup(context); // 나가기 전 확인 팝업
                  },
                  child: const Text('나가기'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    // 여기에 버튼 동작 추가
                  },
                  child: const Text('어떤 기능 버튼'),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ],
        );
      },
    );
  }



  void _showExitConfirmationPopup(BuildContext context){
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context){
        return AlertDialog(
          title: const Text('나가시겠습니까?\n지금 나가면 항복 처리가 됩니다.', textAlign: TextAlign.center,),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: ()async{
                    stopSubs();
                    await FirebaseFirestore.instance.collection('matches').doc(docId).delete();

                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context);
                    gameInstance = MainService();
                  },
                  child: const Text('네'),
                ),
                ElevatedButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  child: const Text('아니오'),
                )
              ],
            )

          ],
        );
      }
    );
  }
}
