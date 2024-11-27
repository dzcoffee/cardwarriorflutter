import 'dart:async';
import 'dart:math';

import 'package:card_warrior/game_service/main_service.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:card_warrior/game_logic.dart';


class GamePage extends StatefulWidget {
  const GamePage({required this.docId});
  final String docId;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  MainService gameInstance = MainService();
  bool? _isMyTurn;
  bool _isWin = false;
  Timer? _timer; // 타이머 변수

  final _authentication = FirebaseAuth.instance;
  User? loggedUser;
  String? userId = '';
  String? docId;
  String? matchedUserId;
  StreamSubscription<DocumentSnapshot>? matchNewSubs;
  FirebaseDatabase database = FirebaseDatabase.instance;
  List<Warrior> deck = [];
  List<Warrior> myHandCards = [];
  List<Warrior> yourHandCards = [];
  List<Warrior> myFieldCards = [];
  List<Warrior> yourFieldCards = [];
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    docId = widget.docId;
    getCurrentUser();
    userId = loggedUser?.email?.split('@').first;
    _fetchData();
  }

  Future<void> _fetchData() async {
    // TODO: implement initState
    DataSnapshot snapshot = await database.ref("userDeck/${userId}").ref.get();
    Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;

    List<Warrior> fetchedCards = [];

    values.forEach((key, value) async {
      final warrior = Warrior(
          value['name'],
          value['cost'],
          value['hp'],
          value['attack'],
          value['type'],
          value['id']
      );
      deck.add(warrior);
    });
    print('덱은 다음과 같음 : ${deck}');
    if(deck.length >= 3){
      await saveRandomCardsOnHand();

    }
  }

  Future<void> _getMatchedUserId() async {
    DocumentSnapshot docSnapshot = await firestore.collection('matches').doc(docId).get();

    print('docsnapshot 있음? ${docSnapshot['userId']}');
    if(docSnapshot.exists){ // matchedUserId 확인
      matchedUserId = docSnapshot['matchedUserId'];
      if(matchedUserId == userId){ // matchedUserId가 나면 userId 받아오기
        matchedUserId = docSnapshot['userId'];
        _isMyTurn = true;
        try{
          Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

          // userId와 matchedUserId의 기존 객체 가져오기
          Map<String, dynamic> matchedUserObj = data[userId] ?? {};
          matchedUserObj['isMyTurn'] = true; // 또는 필요한 값을 설정

          // 업데이트 수행
          await firestore.collection('matches').doc(docId).update({
            '${userId}': matchedUserObj,
          });
          print('턴 업데이트 완료');
          _showMyTurn();
          _drawWarriorFromDeck();
        }catch(e){
          print(e);
        }
      }else{ //내가 userId면
        _isMyTurn = false;
        try{
          Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

          // userId와 matchedUserId의 기존 객체 가져오기
          Map<String, dynamic> userObject = data[userId] ?? {};
          userObject['isMyTurn'] = false; // 또는 필요한 값을 설정

          // 업데이트 수행
          await firestore.collection('matches').doc(docId).update({
            '${userId}': userObject,
          });
          print('턴 업데이트 완료');
          _showYourTurn();

          listenToNewMatch(docId!);
        }catch(e){
          print(e);
        }
      }
    }
  }

  Future<void> saveRandomCardsOnHand() async {
    // 랜덤하게 2개의 카드 뽑기
    final random = Random();
    if (deck.length < 2) {
      print('Deck에 카드가 2개 이상 있어야 합니다.');
      return;
    }

    // 랜덤 인덱스 생성
    int index1 = random.nextInt(deck.length);
    int index2, index3;

    // 중복되지 않는 인덱스 생성
    do {
      index2 = random.nextInt(deck.length);
    } while (index1 == index2);

    do {
      index3 = random.nextInt(deck.length);
    } while (index1 == index3 || index2 == index3);

    // 선택된 카드
    Warrior warrior1 = deck[index1];
    print('warrior1 : ${warrior1}');
    Warrior warrior2 = deck[index2];
    print('warrior2 : ${warrior2}');
    Warrior warrior3 = deck[index3];
    print('warrior3 : ${warrior3}');

    myHandCards.add(warrior1);
    myHandCards.add(warrior2);
    myHandCards.add(warrior3);

    deck.remove(warrior1);
    deck.remove(warrior2);
    deck.remove(warrior3);

    try{
      print("덱 카드 저장 직전");
      await firestore.collection('matches').doc(docId).update({
        '${userId}':
        {
          'onHand' :
          {
            'Card${warrior1.id}': {
              'id': warrior1.id, // 카드의 id 속성
              'name': warrior1.name, // 카드의 name 속성
              'attack': warrior1.atk, // 카드의 attack 속성
              'cost' : warrior1.cost,
              'type' : warrior1.type,
              'hp' : warrior1.hp,
            },
            'Card${warrior2.id}': {
              'id': warrior2.id,
              'name': warrior2.name,
              'attack': warrior2.atk,
              'cost' : warrior2.cost,
              'type' : warrior2.type,
              'hp' : warrior2.hp,
            },
            'Card${warrior3.id}': {
              'id': warrior3.id, // 카드의 id 속성
              'name': warrior3.name, // 카드의 name 속성
              'attack': warrior3.atk, // 카드의 attack 속성
              'cost' : warrior3.cost,
              'type' : warrior3.type,
              'hp' : warrior3.hp,
            },
          },
        }
      });
      _getMatchedUserId(); // 다 가져오면 턴 정하기
    }catch(e){
      print(e);
    }
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

  Future<void> _drawWarriorFromDeck() async {
    print('덱 길이 : ${deck.length}');
    final random = Random();
    int index = random.nextInt(deck.length);
    Warrior warrior = deck[index];
    myHandCards.add(warrior);
    deck.removeAt(index);

    DocumentSnapshot docSnapshot = await firestore.collection('matches').doc(docId).get();
    Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

    // userId와 matchedUserId의 기존 객체 가져오기
    Map<String, dynamic> userObj = data[userId] ?? {};

    if (userObj['onHand'] == null) {
      userObj['onHand'] = [];
    }
    userObj['onHand']['Card${warrior.id}'] = {
      'id': warrior.id, // 카드의 id 속성
      'name': warrior.name, // 카드의 name 속성
      'attack': warrior.atk, // 카드의 attack 속성
      'cost' : warrior.cost,
      'type' : warrior.type,
      'hp' : warrior.hp,
    };

    await firestore.collection('matches').doc(docId).update({
      '${userId}': userObj,
    });

  }

  Future<void> _moveWarriorHandToField(int indexWhy) async{
    final random = Random();
    int indexRandom = random.nextInt(myHandCards.length); // 이 index는 나중에 함수 호출 할 때 index 넣어줘야 함.
    print('내 핸드 카드 : ${myHandCards}');

    Warrior warriorInHand = myHandCards[indexRandom];
    myFieldCards.add(warriorInHand);
    myHandCards.removeAt(indexRandom);
    print('인 핸드에서 카드로 : ${warriorInHand}');

    DocumentSnapshot docSnapshot = await firestore.collection('matches').doc(docId).get();
    Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

    // userId와 matchedUserId의 기존 객체 가져오기
    Map<String, dynamic> userObj = data[userId] ?? {};

    print('${userObj}');
    // onHand에서 카드 삭제
    if (userObj['onHand'] != null && userObj['onHand'] is Map) {
      // 카드 ID에 해당하는 키를 사용하여 삭제
      String cardKey = 'Card${warriorInHand.id}';
      userObj['onHand'].remove(cardKey); // Card${id} 형식으로 키를 사용하여 삭제
    }



    if (userObj['onField'] == null) {
      userObj['onField'] = {};
    }
    userObj['onField']['Card${warriorInHand.id}'] = {
      'id': warriorInHand.id, // 카드의 id 속성
      'name': warriorInHand.name, // 카드의 name 속성
      'attack': warriorInHand.atk, // 카드의 attack 속성
      'cost' : warriorInHand.cost,
      'type' : warriorInHand.type,
      'hp' : warriorInHand.hp,
    };

    await firestore.collection('matches').doc(docId).update({
      '${userId}': userObj,
    });

  }


  @override
  void dispose(){
    super.dispose();
  }

  void listenToNewMatch(String docId) { //여기서 FireStore값에 따라 상태 업데이트
    matchNewSubs = FirebaseFirestore.instance.collection('matches').doc(docId).snapshots().listen((docSnapshot) {
      print('docId는 다음과 같습니다' + docId);
      if(!docSnapshot.exists){
        _isWin = true;
        if(_isWin == true){
          _showVictoryPopup();
        }
      }

      Map<String, dynamic> data = docSnapshot['${userId}'];
      if(data['isMyTurn'] == true && _isMyTurn != true){
        _showMyTurn();
        _isMyTurn = true;
        _drawWarriorFromDeck();
      }

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
                  onPressed: () async {
                    setState(() {
                      _isMyTurn = false;
                    });

                    try{
                      DocumentSnapshot docSnapshot = await firestore.collection('matches').doc(docId).get();
                      if(docSnapshot.exists){
                        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

                        // userId와 matchedUserId의 기존 객체 가져오기
                        Map<String, dynamic> userObj = data[userId] ?? {};
                        Map<String, dynamic> matchedUserObj = data[matchedUserId] ?? {};

                        userObj['isMyTurn'] = false; // 또는 필요한 값을 설정
                        matchedUserObj['isMyTurn'] = true; // 또는 필요한 값을 설정

                        await firestore.collection('matches').doc(docId).update({
                          '${userId}': userObj,
                          '${matchedUserId}': matchedUserObj,
                        });
                        _showYourTurn();
                      }
                      
                    }catch(e){
                      print(e);
                    }
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
                      gameInstance.drawCard();
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
                      gameInstance.MoveLeft();
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
                      gameInstance.MoveRight();
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
                    _moveWarriorHandToField(1);
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
                    setState(() {
                      _isWin = false;
                    });
                    stopSubs();
                    await FirebaseFirestore.instance.collection('matches').doc(docId).delete();

                    gameInstance = MainService();
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context);

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

  void _showVictoryPopup() {
    stopSubs();
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context){
          return AlertDialog(
            title: Row(
              children: [
                const Expanded(
                    child: Text('승리!', textAlign: TextAlign.center)
                ),
                ElevatedButton(
                  onPressed: (){
                    stopSubs();

                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context);

                  },
                  child: const Icon(Icons.close)
                )
              ],
            ),
          );
        }
    );
  }
  
  void _showMyTurn() {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context){
          return AlertDialog(
            title: Row(
              children: [
                const Expanded(
                    child: Text('내 턴', textAlign: TextAlign.center)
                ),
              ],
            ),
          );
        }
    );

  }

  void _showYourTurn() {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context){
          return AlertDialog(
            title: Row(
              children: [
                const Expanded(
                    child: Text('상대 턴', textAlign: TextAlign.center)
                ),
              ],
            ),
          );
        }
    );

  }
}
