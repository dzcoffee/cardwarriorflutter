import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:card_warrior/game_logic.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomizingPage extends StatefulWidget {
  const CustomizingPage({super.key});

  @override
  State<CustomizingPage> createState() => _CustomizingPageState();
}



class _CustomizingPageState extends State<CustomizingPage> {
  FirebaseDatabase database = FirebaseDatabase.instance;
  List<Warrior> cardList = [];
  final _authentication = FirebaseAuth.instance;
  User? loggedUser;
  Player? player;
  String? _username;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _getCurrentUser();
    _username = loggedUser?.email?.split('@').first;
    player = Player(_username!);
  }

  void _getCurrentUser() {
    try {
      final user = _authentication.currentUser;
      if (user != null) {
        loggedUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _fetchData() async {
    // TODO: implement initState
    DataSnapshot snapshot = await database.ref("CardList").get();
    Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;

    List<Warrior> fetchedCards = [];

    values.forEach((key, value){
      final warrior = Warrior(
        value['name'],
        value['cost'],
        value['hp'],
        value['attack'],
        value['type'],
        value['id'],
      );
      cardList.add(warrior);

      setState(() {
        cardList = fetchedCards; // 상태 업데이트
      });
    });
  }

  Future<void> saveWarriorsToDB(String username, List<Warrior> warriors) async {
    final database = FirebaseDatabase.instance.ref();
    final warriorListRef = database.child('userDeck/$username');
    await warriorListRef.remove();
    for (var warrior in warriors) {
      await warriorListRef.push().set(warrior.toMap());
    }
  }

  void toggleCardSelection(Warrior warrior){
    setState(() {
      if(player!.cardDeck.contains(warrior)){
        player!.deleteCardFromDeck(warrior);
      }
      else{
        player!.addCardToDeck(warrior);
      }
    });
  }

  void _showSaveDeckPopup() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context){
          return AlertDialog(
            title: Row(
              children: [
                const Expanded(
                    child: Text('덱 추가 완료', textAlign: TextAlign.center)
                ),
                ElevatedButton(
                    onPressed: (){

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Deck Customizing (${player!.cardDeck.length}/20)'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () async {
              print('Selected Cards: ${player!.cardDeck}');
              saveWarriorsToDB(_username!, player!.cardDeck);
              _showSaveDeckPopup();
            },
          )
        ],
      ),
      body: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 258/378,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: cardList.length,
          itemBuilder: (context, index){
            final card = cardList[index];
            final isSelected = player!.cardDeck.contains(card);
            int idx = card.id;
            return GestureDetector(
              onTap: () => toggleCardSelection(card), // 카드 선택/해제 토글
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/cards/$idx.JPG'),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.transparent,
                        width: 3, // 선택 상태 강조
                      ),
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: SizedBox(
                              width: 20,
                              child: Text(
                                '${card.cost}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            margin: EdgeInsets.only(bottom: 7),
                            padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${card.name}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: SizedBox(
                              width: 20,
                              child: Text(
                                '${card.atk}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 1, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: SizedBox(
                              width: 20,
                              child: Text(
                                '${card.hp}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 선택 표시 (체크 아이콘)
                  if (isSelected)
                    Align(
                      alignment: Alignment.topRight,
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                ],
              ),
            );
          }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          print('Selected Cards: ${player!.cardDeck}');
          if(player!.cardDeck.length < 20) {
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('잠깐!'),
                  content: const Text('20장을 선택해주세요!'),
                  actions: [
                    TextButton(
                      child: const Text('확인'),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                )
            );
          } else if(player!.cardDeck.length > 20){
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('잠깐!'),
                  content: const Text('20장만 가져갈 수 있습니다!'),
                  actions: [
                    TextButton(
                      child: const Text('확인'),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                )
            );
          } else{
            saveWarriorsToDB(_username!, player!.cardDeck);
            _showSaveDeckPopup();
          }
        },
        child: Icon(Icons.add, size: 30,),
      ),
    );
  }
}

