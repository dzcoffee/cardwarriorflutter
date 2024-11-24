import 'dart:async';
import 'dart:math';

import 'package:card_warrior/game_service/main_service.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class Card{
  String _name;
  int _cost;
  int _hp;
  int _atk;
  int _type;
  int _id;

  Card(this._name, this._cost, this._hp, this._atk, this._type, this._id);

  String get name => _name;
  int get cost => _cost;
  int get hp => _hp;
  int get atk => _atk;
  int get type => _type;

  void attack(Card opponent){
    if(_type == 1 && opponent._type == 4){
      opponent._hp -= _atk*2;
      _hp -= opponent._atk;
    }
    else if(_type == 2 && opponent._type == 3){
      opponent._hp -= _atk*2;
      _hp -= opponent._atk;
    }
    else if(_type == 3 && opponent._type == 1){
      opponent._hp -= _atk*2;
      _hp -= opponent._atk;
    }
    else if(_type == 4 && opponent._type == 2){
      opponent._hp -= _atk*2;
      _hp -= opponent._atk;
    }
    else{
      opponent._hp -= _atk;
      _hp -= opponent._atk;
    }
  }

  void attackUser(Player player){
    if(player.cardOnField.isEmpty){
      player._health -= _atk;
    }
  }

  String toString() {
    return "Card(name: $_name, cost: $_cost, hp: $_hp, atk: $_atk, type: $_type)";
  }

}

class Player{
  int _money = 1;
  int _health = 20;
  String _username;

  List<Card> cardDeck = [];
  List<Card> cardOnField = [];
  List<Card> cardOnHand = [];

  Player(this._username);

  void addCardToDeck(Card c){
    if (cardDeck.length < 26) {
      cardDeck.add(c);
    }
  }

  void addCardToField(Card c){
    if (cardOnField.length < 7){
      cardOnField.add(c);
    }
  }

  void addCardToHand(Card c){
    if(cardDeck.isNotEmpty){
      cardOnHand.add(c);
    }
  }

  void deleteCardFromDeck(Card c){
    cardDeck.remove(c);
  }

  void deleteCardFromField(Card c){
    cardOnField.remove(c);
  }

  void deleteCardFromHand(Card c){
    cardOnHand.remove(c);
  }

  void turnEnd(Player other){
    other._money++;
    if (cardDeck.isNotEmpty && cardOnHand.length < 10) {
      Card drawnCard = cardDeck.removeLast();
      addCardToHand(drawnCard);
    }
  }

  int get health => _health;

  set health(int value) {
    _health = value.clamp(0, 20);
  }

  int get money => _money;

  set money(int value) {
    _money = value.clamp(0, 10);
  }

  void surrender(){
    print("end game");
  }

  String toString() {
    return "User(username: $_username, health: $_health, money: $_money, "
        "deck: ${cardDeck.length} cards, field: ${cardOnField.length} cards, hand: ${cardOnHand.length} cards)";
  }
}

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
  FirebaseDatabase database = FirebaseDatabase.instance;
  List<Card> deck = [];
  List<Card> myHandCards = [];
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    userId = loggedUser?.email?.split('@').first;
    _fetchData();
  }

  Future<void> _fetchData() async {
    // TODO: implement initState
    DataSnapshot snapshot = await database.ref("userDeck/${userId}").ref.get();
    Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;

    List<Card> fetchedCards = [];

    values.forEach((key, value){
      final card = Card(
          value['name'],
          value['cost'],
          value['hp'],
          value['attack'],
          value['type'],
          value['id']
      );
      deck.add(card);

      setState(() {
        deck = fetchedCards; // 상태 업데이트

      });
      print('덱은 다음과 같음 : ${deck}');
      if(deck.length == 2){
        saveRandomCardsOnHand();
      }
    });
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
    int index2;

    // 중복되지 않는 인덱스 생성
    do {
      index2 = random.nextInt(deck.length);
    } while (index1 == index2);

    // 선택된 카드
    Card card1 = deck[index1];
    Card card2 = deck[index2];

    myHandCards.add(card1);
    myHandCards.add(card2);

    try{
      print("덱 카드 저장 직전");
      await firestore.collection('matches').doc(docId).update({
        '${userId}': {
          'onHand' :
            {
              'Card1': {
                'id': card1._id, // 카드의 id 속성
                'name': card1.name, // 카드의 name 속성
                'attack': card1.atk, // 카드의 attack 속성
              },
              'Card2': {
                'id': card2._id,
                'name': card2.name,
                'attack': card2.atk,
              },
            },
        }
      });
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

  void listenToNewMatch(String docId) { //여기서 FireStore값에 따라 상태 업데이트
    matchNewSubs = FirebaseFirestore.instance.collection('matches').doc(docId).snapshots().listen((docSnapshot) {
      print('docId는 다음과 같습니다' + docId);
      if(!docSnapshot.exists){
        _showVictoryPopup();
      }
      setState(() {

      });
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
                    //Navigator.pop(context); Matching Page 넣으면 주석 빼기
                    //Navigator.pop(context);
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
                    //Navigator.pop(context); Matching Page 넣으면 주석 빼기
                    //Navigator.pop(context);
                    //Navigator.pop(context);
                  },
                  child: const Icon(Icons.close)
                )
              ],
            ),
          );
        }
    );
  }
}
