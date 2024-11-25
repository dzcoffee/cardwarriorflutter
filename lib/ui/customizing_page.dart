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
        title: Text('Deck Customizing'),
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
          childAspectRatio: 3/4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: cardList.length,
        itemBuilder: (context, index){
          final warriorList = cardList[index];
          final isSelected = player!.cardDeck.contains(warriorList);
          return GestureDetector(
            onTap: () => toggleCardSelection(warriorList), // 카드 선택/해제 토글
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/card.png'),
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
                      Positioned(
                        top: 8,
                        left: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${warriorList.cost}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${warriorList.name}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${warriorList.atk}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${warriorList.hp}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 선택 표시 (체크 아이콘)
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
              ],
            ),
          );
        }
      )
    );
  }
}
/*
ListView.builder(

itemBuilder: (context, index){
return ListTile(
title: Text(cardList[index].name)
);
},
)
*/