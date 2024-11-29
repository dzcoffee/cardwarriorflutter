import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:card_warrior/game_logic.dart';

class CustomizingPage extends StatefulWidget {
  const CustomizingPage({super.key});

  @override
  State<CustomizingPage> createState() => _CustomizingPageState();
}



class _CustomizingPageState extends State<CustomizingPage> {
  FirebaseDatabase database = FirebaseDatabase.instance;
  User user = User('username');
  List<Warrior> cardList = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // TODO: implement initState
    DataSnapshot snapshot = await database.ref("CardList").get();
    Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;

    List<Warrior> fetchedCards = [];

    values.forEach((key, value){
      final card = Warrior(
        value['id'],
        value['name'],
        value['cost'],
        value['hp'],
        value['attack'],
        value['type']
      );
      cardList.add(card);

      setState(() {
        cardList = fetchedCards; // 상태 업데이트
      });
    });
  }

  void toggleCardSelection(Warrior card){
    setState(() {
      if(user.cardDeck.contains(card)){
        user.deleteCardFromDeck(card);
      }
      else{
        user.addCardToDeck(card);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Deck Customizing'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: (){
              print('Selected Cards: ${user.cardDeck}');
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
          final isSelected = user.cardDeck.contains(card);
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
                        alignment: Alignment.topLeft, // 카드 상단 왼쪽
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${card.cost}',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter, // 카드 하단 중앙
                        child: Container(
                          margin: EdgeInsets.only(bottom: 7),
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        alignment: Alignment.bottomLeft, // 카드 하단 왼쪽
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${card.atk}',
                            style: TextStyle(
                              fontSize: 25,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight, // 카드 하단 오른쪽
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${card.hp}',
                            style: TextStyle(
                              fontSize: 25,
                              color: Colors.green,
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
                    alignment: Alignment.topRight, // 카드 상단 오른쪽
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