import 'dart:async';
import 'dart:math';

import 'package:card_warrior/game_service/main_service.dart';
import 'package:card_warrior/game_service/resource_service.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:card_warrior/game_logic.dart';

late int size;

class GamePage extends StatefulWidget {
  const GamePage({required this.docId});
  final String docId;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  MainService gameInstance = MainService();
  int testValue = 0;
  bool? _isMyTurn;
  bool _isWin = false;
  Timer? _timer; // 타이머 변수

  final _authentication = FirebaseAuth.instance;
  User? loggedUser;
  String? userId = '';
  String? docId;
  String? matchedUserId;
  int? drawCardCount;
  StreamSubscription<DocumentSnapshot>? matchNewSubs;
  FirebaseDatabase database = FirebaseDatabase.instance;
  List<Warrior> deck = [];
  List<Warrior> myHandCards = [];
  List<Warrior> yourHandCards = [];
  List<Warrior> myFieldCards = [];
  Map<int, int> myFieldIndex = {};
  Map<int, int> myFieldAttackTime = {};
  Map<int, int> yourFieldIndex = {}; // key는 Warrior Id, values 위치(index)
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
      final warrior = Warrior(value['name'], value['cost'], value['hp'],
          value['attack'], value['type'], value['id']);
      deck.add(warrior);
    });
    print('덱은 다음과 같음 : ${deck}');
    if (deck.length >= 3) {
      await saveRandomCardsOnHand();
    }
  }

  Future<void> _getMatchedUserId() async {
    DocumentSnapshot docSnapshot =
        await firestore.collection('matches').doc(docId).get();

    print('docsnapshot 있음? ${docSnapshot['userId']}');
    if (docSnapshot.exists) {
      // matchedUserId 확인
      matchedUserId = docSnapshot['matchedUserId'];
      if (matchedUserId == userId) {
        // matchedUserId가 나면 userId 받아오기
        matchedUserId = docSnapshot['userId'];
        setState(() {
          _isMyTurn = true;
        });

        try {
          Map<String, dynamic> data =
              docSnapshot.data() as Map<String, dynamic>;

          // userId와 matchedUserId의 기존 객체 가져오기
          Map<String, dynamic> matchedUserObj = data[userId] ?? {};
          matchedUserObj['isMyTurn'] = true; // 또는 필요한 값을 설정

          // 업데이트 수행
          await firestore.collection('matches').doc(docId).update({
            '${userId}': matchedUserObj,
          });
          print('턴 업데이트 완료');

          _showMyTurn();
          setAttackTime();
          gameInstance.cost.addCost();
          _drawWarriorFromDeck();
          listenToNewMatch(docId!);
        } catch (e) {
          print(e);
        }
      } else {
        //내가 userId면
        _isMyTurn = false;
        try {
          Map<String, dynamic> data =
              docSnapshot.data() as Map<String, dynamic>;

          // userId와 matchedUserId의 기존 객체 가져오기
          Map<String, dynamic> userObject = data[userId] ?? {};
          userObject['isMyTurn'] = false; // 또는 필요한 값을 설정

          // 업데이트 수행
          await firestore.collection('matches').doc(docId).update({
            '${userId}': userObject,
          });
          print('턴 업데이트 완료');
          _showYourTurn();
          gameInstance.oppoCost.addCost();

          listenToNewMatch(docId!);
        } catch (e) {
          print(e);
        }
      }
    }
  }

  void setAttackTime(){
    for(Warrior warrior in myFieldCards){
      myFieldAttackTime[warrior.id] = 1;
    }
  }

  Future<void> saveRandomCardsOnHand() async {
    // 랜덤하게 3개의 카드 뽑기
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

    try {
      print("덱 카드 저장 직전");
      await firestore.collection('matches').doc(docId).update({
        '${userId}': {
          'onHand': {
            'Card${warrior1.id}': {
              'id': warrior1.id, // 카드의 id 속성
              'name': warrior1.name, // 카드의 name 속성
              'attack': warrior1.atk, // 카드의 attack 속성
              'cost': warrior1.cost,
              'type': warrior1.type,
              'hp': warrior1.hp,
            },
            'Card${warrior2.id}': {
              'id': warrior2.id,
              'name': warrior2.name,
              'attack': warrior2.atk,
              'cost': warrior2.cost,
              'type': warrior2.type,
              'hp': warrior2.hp,
            },
            'Card${warrior3.id}': {
              'id': warrior3.id, // 카드의 id 속성
              'name': warrior3.name, // 카드의 name 속성
              'attack': warrior3.atk, // 카드의 attack 속성
              'cost': warrior3.cost,
              'type': warrior3.type,
              'hp': warrior3.hp,
            },
          },
        }
      });

      gameInstance.setCards(myHandCards, yourHandCards);
      _getMatchedUserId(); // 다 가져오면 턴 정하기
    } catch (e) {
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
    int index;
    if(deck.length > 1){
      index = random.nextInt(deck.length-1);
    }else if(deck.length == 1){
      index = 0;
    }else if(deck.isEmpty){
      index = -1;
      _showMyDeckIsEmpty();
    }else{
      index = -2;
    }

    if(index >=0){
      Warrior warrior = deck[index];
      myHandCards.add(warrior);
      deck.removeAt(index);

      DocumentSnapshot docSnapshot =
      await firestore.collection('matches').doc(docId).get();
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
        'cost': warrior.cost,
        'type': warrior.type,
        'hp': warrior.hp,
      };

      gameInstance.drawMyCard(warrior);
      await firestore.collection('matches').doc(docId).update({
        '${userId}': userObj,
      });
    }
  }

  Future<void> _moveWarriorHandToField(Warrior warrior) async {
    int index = 0; // 이 index는 나중에 함수 호출 할 때 index 넣어줘야 함.
    print('내 핸드 카드 : ${myHandCards}');

    for (int i = 0; i < myHandCards.length; i++) {
      if (myHandCards[i] == warrior) {
        index = i;
        break;
      }
    }

    Warrior warriorInHand = myHandCards[index];
    print('인 핸드에서 카드로 : ${warriorInHand}');
    myHandCards.removeAt(index);

    DocumentSnapshot docSnapshot =
        await firestore.collection('matches').doc(docId).get();
    Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

    // userId와 matchedUserId의 기존 객체 가져오기
    Map<String, dynamic> userObj = data[userId] ?? {};

    print('${userObj}');
    // onHand에서 카드 삭제
    if (userObj['onHand'] != null && userObj['onHand'] is Map) {
      // 카드 ID에 해당하는 키를 사용하여 삭제
      String cardKey = 'Card${warriorInHand!.id}';
      userObj['onHand'].remove(cardKey); // Card${id} 형식으로 키를 사용하여 삭제
    }

    if (userObj['onField'] == null) {
      userObj['onField'] = {};
    }
    userObj['onField']['Card${warriorInHand!.id}'] = {
      'id': warriorInHand.id, // 카드의 id 속성
      'name': warriorInHand.name, // 카드의 name 속성
      'attack': warriorInHand.atk, // 카드의 attack 속성
      'cost': warriorInHand.cost,
      'type': warriorInHand.type,
      'hp': warriorInHand.hp,
    };

    await firestore.collection('matches').doc(docId).update({
      '${userId}': userObj,
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void listenToNewMatch(String docId) {
    //여기서 FireStore값에 따라 상태 업데이트
    print('여기 들어오는 지 테스트');
    matchNewSubs = FirebaseFirestore.instance
        .collection('matches')
        .doc(docId)
        .snapshots()
        .listen((docSnapshot) async {
      print('docId는 다음과 같습니다' + docId);
      if (!docSnapshot.exists) {
        _isWin = true;
        if (_isWin == true) {
          _showVictoryPopup();
        }
      }
      print('내 턴 확인 ${_isMyTurn}');       

      Map<String, dynamic> data = docSnapshot['${userId}'];
      if(docSnapshot['${matchedUserId}'] != null ){ //상대 카드 낸 거 확인용임
        Map<String, dynamic> yourData = docSnapshot['${matchedUserId}'];
        print('온 핸드 확인 ${yourData['onHand']}');
        if(yourData['onField'] != null && yourData['attack'] == null && _isMyTurn == false){
          Map<String, dynamic> checkedYourField = yourData['onField'];
          print('길이 ${checkedYourField.length} && ${yourFieldCards.length}');
          if (checkedYourField.length > yourFieldCards.length) {
            for (Warrior yourLocalFieldwarrior in yourFieldCards) {
              print('카드 이름 : Card${yourLocalFieldwarrior.id}');
              checkedYourField.remove('Card${yourLocalFieldwarrior.id}');
            }
            Map<String, dynamic> notWarriorData =
                checkedYourField.values.first;
            Warrior notWarrior = Warrior(
                notWarriorData['name'],
                notWarriorData['cost'],
                notWarriorData['hp'],
                notWarriorData['attack'],
                notWarriorData['type'],
                notWarriorData['id']);
            int positionIndex;

            for(int i=5; i >= 0 ; i--){
              if(!yourFieldIndex.containsValue(i)){
                positionIndex=i;
                print('풋 유얼 카드 : ${positionIndex}, ${notWarrior}');
                gameInstance.putYourCard(positionIndex, notWarrior);
                yourFieldIndex[notWarrior.id] = positionIndex;
                for(Warrior warrior in yourHandCards){
                  if(warrior.id == notWarrior.id){
                    yourHandCards.remove(warrior);
                    break;
                  }
                }
                break;
              }
            }
            yourFieldCards.add(notWarrior);
            gameInstance.oppoCost.minusCardCost(notWarrior.cost);
          }
        }

        if(yourData['onHand'] != null && yourData['attack'] == null){
          Map<String, dynamic> checkedYourHand = yourData['onHand'];
          if(checkedYourHand.length != yourHandCards.length){
            for(Warrior yourLocalHandWarrior in yourHandCards){
              print('온 핸드 리무브 중  : ${yourLocalHandWarrior}');
              checkedYourHand.remove('Card${yourLocalHandWarrior.id}');
            }
            Map<String, dynamic> notHandWarriorData = checkedYourHand;
            if(notHandWarriorData.length == 1 && drawCardCount == 0){
              print('여기 체크');
            }else{
              for(String CardKey in notHandWarriorData.keys){
                Map<String, dynamic> actualValue = notHandWarriorData[CardKey];
                Warrior notWarrior = Warrior(
                    actualValue['name'],
                    actualValue['cost'],
                    actualValue['hp'],
                    actualValue['attack'],
                    actualValue['type'],
                    actualValue['id']);
                yourHandCards.add(notWarrior);
                gameInstance.drawYourCard(notWarrior);
                drawCardCount = 1;
              }
            }
          }
        }

        if(yourData['attack'] != null){
          Map<String, dynamic> attack = yourData['attack'];
          int yourATKCardId = attack['myFieldCardId'];
          int myATKCardId = attack['yourFieldCardId'];
          print('테스트 : ${myATKCardId}');

          if(myATKCardId == -1){
            for(Warrior yourCard in yourFieldCards){
              if(yourCard.id == yourATKCardId){
                gameInstance.yourAttack(yourFieldIndex[yourCard.id]!, -1);
                setState(() {
                  gameInstance.health.damaged(yourCard.atk);
                });
                break;
              }
            }
            if(gameInstance.oppoHp.currentHealth <= 0){
              setState(() {
                _isWin = false;
              });
              stopSubs();
              await FirebaseFirestore.instance
                  .collection('matches')
                  .doc(docId)
                  .delete();

              _showDefeatPopup();
              //패배넣기
            }

            yourData['attack'] = null;
            print('리무브 직전임 yourData :  ${yourData}');
            await firestore
                .collection('matches')
                .doc(docId)
                .update({
              '${matchedUserId}': yourData,
            });
          }else{
            for(Warrior yourCard in yourFieldCards){
              if(yourCard.id == yourATKCardId){
                for(Warrior myCard in myFieldCards){
                  if(myCard.id == myATKCardId){
                    //myCard.attack(yourCard);
                    gameInstance.yourAttack(yourFieldIndex[yourCard.id]!, myFieldIndex[myCard.id]!);

                    CardComponent myCardComponent =  gameInstance.findCardKey(gameInstance.myExistField, myFieldIndex[myCard.id]!);
                    CardComponent yourCardComponent = gameInstance.findCardKey(gameInstance.yourExistField, yourFieldIndex[yourCard.id]!);
                    setState(() {
                      myCardComponent.attack(yourCardComponent);
                      if(myCardComponent.hpPoint <0 || myCardComponent.hpPoint == 0){
                        //gameInstance.remove(myCardComponent); //내 카드 제거 메서드
                        gameInstance.destructCard(gameInstance.myExistField, myFieldIndex[myCard.id]!);
                        myFieldCards.remove(myCard);
                        myFieldIndex.remove(myCard);
                        print('삭제 체크 ${myFieldCards}, 삭제한 카드 ${myCardComponent.warrior}');
                      }
                      if(yourCardComponent.hpPoint<=0 || yourCardComponent.hpPoint == 0){
                        //gameInstance.remove(yourCardComponent); // 상대 카드 제거 메서
                        gameInstance.destructCard(gameInstance.yourExistField, yourFieldIndex[yourCard.id]!);
                        yourFieldCards.remove(yourCard);
                        yourFieldIndex.remove(yourCard.id);
                        print('상대 카드 삭제 체크 ${yourFieldCards} , 삭제된 상대 카드 ${yourCardComponent.warrior} ');
                      }
                      print('여기 테스트중입니다~');
                    });

                    break;
                  }
                }
              }
            }
            yourData['attack'] = null;
            //yourData['onField'] = yourFieldCards;

            print('리무브 직전임');

            await firestore
                .collection('matches')
                .doc(docId)
                .update({
              '${matchedUserId}': yourData,
            });
          }

        }

      }

      if (data['isMyTurn'] == true && _isMyTurn != true) {
        _showMyTurn();
        setAttackTime();
        gameInstance.cost.addCost();
        setState(() {
          _isMyTurn = true;
        });

        //gameInstance.oppoCost.addCost();
        _drawWarriorFromDeck();
      }
    });
  }

  void stopSubs() {
    if (matchNewSubs != null) {
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 75,
                height: 40,
                child: ElevatedButton(
                  style:ElevatedButton.styleFrom(
                      backgroundColor: (_isMyTurn == true) ? Colors.green :  Color.fromRGBO(184, 156, 120, 1.0)
                  ),
                  onPressed: () async {
                    if(_isMyTurn == false){
                      _showNotMyTurn();
                    }
                    else{

                      if(yourFieldCards.isEmpty){
                        CardComponent myCard =  gameInstance.findCardKey(gameInstance.myExistField, gameInstance.myFieldIndex);
                        Warrior myFieldAtkCard = myCard.warrior;
                        if(myFieldAttackTime[myFieldAtkCard.id] != 1){
                          _showMyCardAttackTimeIsZero();
                        }else{
                          gameInstance.myAttack();
                          setState(() {
                            gameInstance.oppoHp.damaged(myFieldAtkCard.atk);
                            myFieldAttackTime[myFieldAtkCard.id] = 0;
                          });

                          try {
                            DocumentSnapshot docSnapshot = await firestore
                                .collection('matches')
                                .doc(docId)
                                .get();
                            if (docSnapshot.exists) {
                              Map<String, dynamic> data =
                              docSnapshot.data() as Map<String, dynamic>;

                              // userId와 matchedUserId의 기존 객체 가져오기
                              Map<String, dynamic> userObj = data[userId] ?? {};

                              userObj['attack'] = {
                                'myFieldCardId' : myFieldAtkCard.id,
                                'yourFieldCardId' : -1
                              };

                              await firestore
                                  .collection('matches')
                                  .doc(docId)
                                  .update({
                                '${userId}': userObj,
                              });
                            }
                          } catch (e) {
                            print(e);
                          }


                        }
                      }else{
                        CardComponent myCard =  gameInstance.findCardKey(gameInstance.myExistField, gameInstance.myFieldIndex);
                        CardComponent yourCard = gameInstance.findCardKey(gameInstance.yourExistField, gameInstance.yourFieldIndex);

                        Warrior myFieldAtkCard = myCard.warrior;
                        Warrior yourFieldAtkCard = yourCard.warrior;

                        if(myFieldAttackTime[myFieldAtkCard.id] != 1){
                          _showMyCardAttackTimeIsZero();
                        }else{
                          gameInstance.myAttack();
                          setState(() {
                            myCard.attack(yourCard);
                            if(myCard.hpPoint <0 || myCard.hpPoint == 0){
                              //gameInstance.remove(myCard); // 내 카드 제거 메서드
                              gameInstance.destructCard(gameInstance.myExistField, gameInstance.myFieldIndex);
                              myFieldCards.remove(myFieldAtkCard);
                              myFieldIndex.remove(myFieldAtkCard.id);
                              print('삭제 체크 ${myFieldCards}, 삭제한 카드 ${myCard.warrior}');
                            }
                            if(yourCard.hpPoint<0 || yourCard.hpPoint == 0){
                              //gameInstance.remove(yourCard); //상대 카드 제거 메서드
                              gameInstance.destructCard(gameInstance.yourExistField, gameInstance.yourFieldIndex);
                              yourFieldCards.remove(yourFieldAtkCard);
                              yourFieldIndex.remove(yourFieldAtkCard.id);
                              print('상대 카드 삭제 체크 필드 : ${yourFieldCards}, 삭제된 상대 카드 ${yourCard.warrior}');
                            }
                            myFieldAttackTime[myFieldAtkCard.id] = 0;
                            gameInstance.atkEndCheck = -1;
                            print('여기 테스트중입니다~');
                          });

                          try {
                            DocumentSnapshot docSnapshot = await firestore
                                .collection('matches')
                                .doc(docId)
                                .get();
                            if (docSnapshot.exists) {
                              Map<String, dynamic> data =
                              docSnapshot.data() as Map<String, dynamic>;

                              // userId와 matchedUserId의 기존 객체 가져오기
                              Map<String, dynamic> userObj = data[userId] ?? {};
                              Map<String, dynamic> yourObj = data[matchedUserId] ?? {};


                              userObj['attack'] = {
                                'myFieldCardId' : myFieldAtkCard.id,
                                'yourFieldCardId' : yourFieldAtkCard.id
                              };

                              if(!myFieldCards.contains(myFieldAtkCard)){
                                Map<String, dynamic> userField = userObj['onField'];
                                userField.remove('Card${myFieldAtkCard.id}');
                              }
                              if(!yourFieldCards.contains(yourFieldAtkCard)){
                                Map<String, dynamic> yourField = yourObj['onField'];
                                yourField.remove('Card${yourFieldAtkCard.id}');
                              }

                              await firestore
                                  .collection('matches')
                                  .doc(docId)
                                  .update({
                                '${userId}': userObj,
                                '${matchedUserId}' : yourObj
                              });
                            }
                          } catch (e) {
                            print(e);
                          }

                          //gameInstance.myAttack();
                        }
                      }

                    }
                  },
                  child: Text('공격'),
                ),
              ),
              // Container(
              //   width: 75,
              //   height: 40,
              //   child: ElevatedButton(
              //     onPressed: (){
              //       setState(() {
              //         gameInstance.yourAttack();
              //       });
              //     },
              //     child: Text('상대방의 공격'),
              //   ),
              // ),
              Container(
                width: 75,
                height: 40,
                child: ElevatedButton(
                  style:ElevatedButton.styleFrom(
                    backgroundColor: (_isMyTurn == true) ? Colors.green :  Color.fromRGBO(184, 156, 120, 1.0)
                  ),
                  onPressed: () async {
                    if(_isMyTurn == false){
                      _showNotMyTurn();
                    }else{
                      setState(() {
                        _isMyTurn = false;
                      });

                      try {
                        DocumentSnapshot docSnapshot = await firestore
                            .collection('matches')
                            .doc(docId)
                            .get();
                        if (docSnapshot.exists) {
                          Map<String, dynamic> data =
                          docSnapshot.data() as Map<String, dynamic>;

                          // userId와 matchedUserId의 기존 객체 가져오기
                          Map<String, dynamic> userObj = data[userId] ?? {};
                          Map<String, dynamic> matchedUserObj =
                              data[matchedUserId] ?? {};

                          userObj['isMyTurn'] = false; // 또는 필요한 값을 설정
                          matchedUserObj['isMyTurn'] = true; // 또는 필요한 값을 설정

                          await firestore
                              .collection('matches')
                              .doc(docId)
                              .update({
                            '${userId}': userObj,
                            '${matchedUserId}': matchedUserObj,
                          });
                          _showYourTurn();
                          gameInstance.oppoCost.addCost();
                          drawCardCount = 1;
                        }
                      } catch (e) {
                        print(e);
                      }
                    }
                  },
                  child: Text('턴 종료'),
                ),
              ),
              // Container(
              //   width: 75,
              //   height: 40,
              //   child: ElevatedButton(
              //     onPressed: (){
              //       setState(() {
              //         _isMyTurn = true;
              //         //gameInstance.drawMyCard();
              //       });
              //     },
              //     child: const Text('상대 턴 종료'),
              //   ),
              // ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Container(
              //   width: 75,
              //   height: 40,
              //   child: ElevatedButton(
              //     onPressed: (){
              //       setState(() {
              //
              //         _isMyTurn = true;
              //         //gameInstance.drawCard();
              //
              //       });
              //     },
              //     child: const Text('상대방 카드 내기'),
              //   ),
              // ),
              Container(
                width: 85,
                height: 40,
                child: ElevatedButton(
                  style:ElevatedButton.styleFrom(
                      backgroundColor: (_isMyTurn == true) ? Colors.green :  Color.fromRGBO(184, 156, 120, 1.0)
                  ),
                  onPressed: () {
                    if(_isMyTurn == false){
                      _showNotMyTurn();
                    }else{
                      setState(() {
                        CardComponent cardComponent =
                        gameInstance.myCards[gameInstance.myCurrentIndex];
                        if (cardComponent.warrior.cost <=
                            gameInstance.cost.currentCost) {
                          gameInstance.cost.minusCardCost(
                              cardComponent.warrior.cost);
                          _moveWarriorHandToField(cardComponent.warrior);
                          gameInstance.putMyCard();
                          myFieldCards.add(cardComponent.warrior);
                          print('나의 필드 인덱스, 인스턴스 : ${gameInstance.myFieldIndex}');
                          myFieldIndex[cardComponent.warrior.id] =
                              gameInstance.myFieldIndex;
                          myFieldAttackTime[cardComponent.warrior.id] = 0;
                          //myHandCards.remove(cardComponent.warrior);
                        } else {
                          _showNotEnoughCost();
                        }
                      });
                    }

                  },
                  child: const Text('카드내기'),
                ),
              ),
            ],
          ),
        ),

        ///내 손안의 카드 방향키
        Align(
          alignment: Alignment(0.0, 0.75),
          child: Container(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    gameInstance.MoveLeft();
                  },
                  icon: const Icon(Icons.arrow_back,
                      size: 40, color: Colors.white),
                ),
                Container(
                  width: 150,
                  height: 70,
                ),
                IconButton(
                  onPressed: () {
                    gameInstance.MoveRight();
                  },
                  icon: const Icon(Icons.arrow_forward,
                      size: 40, color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        ///상대방 필드 위 카드
        Align(
          alignment: Alignment(0.0, -0.5), // x: 0.0 (가로 중앙), y: -0.5 (위쪽 중간)
          child: Container(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    gameInstance.yourFieldLeft();
                  },
                  icon: const Icon(Icons.arrow_back,
                      size: 40, color: Colors.white),
                ),
                Container(
                  width: 300,
                  height: 70,
                ),
                IconButton(
                  onPressed: () {
                    gameInstance.yourFieldRight();
                  },
                  icon: const Icon(Icons.arrow_forward,
                      size: 40, color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        ///내 필드 위 카드
        Align(
          alignment: Alignment(0.0, 0.3), // x: 0.0 (가로 중앙), y: -0.5 (위쪽 중간)
          child: Container(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    gameInstance.myFieldLeft();
                  },
                  icon: const Icon(Icons.arrow_back,
                      size: 40, color: Colors.white),
                ),
                Container(
                  width: 300,
                  height: 70,
                ),
                IconButton(
                  onPressed: () {
                    gameInstance.myFieldRight();
                  },
                  icon: const Icon(Icons.arrow_forward,
                      size: 40, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    ));
  }

  void _showMenuPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Expanded(
                child: Text(
                  'Menu',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showExitConfirmationPopup(context); // 나가기 전 확인 팝업
                    },
                    child: const Text('나가기'),
                  ),
                ),
                Expanded(child: const SizedBox(width: 5,)),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showExitConfirmationPopup(BuildContext context) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              '나가시겠습니까?\n지금 나가면 항복 처리가 됩니다.',
              textAlign: TextAlign.center,
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _isWin = false;
                      });
                      stopSubs();
                      await FirebaseFirestore.instance
                          .collection('matches')
                          .doc(docId)
                          .delete();

                      ///여기 수정함
                      //gameInstance = MainService();
                      Navigator.pop(context);
                      Navigator.pop(context);
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('네'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('아니오'),
                  )
                ],
              )
            ],
          );
        });
  }

  void _showVictoryPopup() {
    stopSubs();
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                const Expanded(child: Text('승리!', textAlign: TextAlign.center)),
                ElevatedButton(
                    onPressed: () {
                      stopSubs();

                      Navigator.pop(context);
                      Navigator.pop(context);
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.close))
              ],
            ),
          );
        });
  }

  void _showMyTurn() {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                const Expanded(child: Text('내 턴', textAlign: TextAlign.center)),
              ],
            ),
          );
        });
  }

  void _showYourTurn() {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                const Expanded(
                    child: Text('상대 턴', textAlign: TextAlign.center)),
              ],
            ),
          );
        });
  }

  void _showNotEnoughCost() {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                const Expanded(
                    child:
                        Text('Cost가 충분하지 않습니다.', textAlign: TextAlign.center)),
              ],
            ),
          );
        });
  }

  void _showNotMyTurn() {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                const Expanded(
                    child:
                    Text('상대방의 턴이 진행중입니다.', textAlign: TextAlign.center)),
              ],
            ),
          );
        });
  }

  void _showMyDeckIsEmpty() {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                const Expanded(
                    child:
                    Text('덱에 카드가 더 이상 없습니다.', textAlign: TextAlign.center)),
              ],
            ),
          );
        });
  }

  void _showMyCardAttackTimeIsZero() {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                const Expanded(
                    child:
                    Text('해당 카드는 이번 턴에 공격할 수 없습니다.', textAlign: TextAlign.center)),
              ],
            ),
          );
        });
  }

  void _showDefeatPopup() {
    stopSubs();
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                const Expanded(child: Text('패배!', textAlign: TextAlign.center)),
                ElevatedButton(
                    onPressed: () {
                      stopSubs();

                      Navigator.pop(context);
                      Navigator.pop(context);
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.close))
              ],
            ),
          );
        });
  }
}
