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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test'),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: cardList.length,
        itemBuilder: (context, index){
          return Container(
            width: 300,
            height: 400,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/icons/card.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text('${cardList[index].cost}')
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                      child: Text('${cardList[index].name}')
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Text('${cardList[index].atk}'),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Text('${cardList[index].hp}'),
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