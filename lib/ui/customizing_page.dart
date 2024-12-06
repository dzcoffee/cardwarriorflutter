import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';


class CustomizingPage extends StatefulWidget {
  const CustomizingPage({super.key});

  @override
  State<CustomizingPage> createState() => _CustomizingPageState();
}

class Card{
  int attack;
  int cost;
  int hp;
  int id;
  String name;
  int type;

  Card(this.attack, this.cost, this.hp, this.id, this.name, this.type);
}

class _CustomizingPageState extends State<CustomizingPage> {
  FirebaseDatabase database = FirebaseDatabase.instance;
  List<Card> cardList = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // TODO: implement initState
    DataSnapshot snapshot = await database.ref("CardList").get();
    Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;

    List<Card> fetchedCards = [];

    values.forEach((key, value){
      final card = Card(
        value['attack'],
        value['cost'],
        value['hp'],
        value['id'],
        value['name'],
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
      body: ListView.builder(
          itemCount: cardList.length,
          itemBuilder: (context, index){
            return ListTile(
              title: Text(cardList[index].name)
            );
          },
        )
    );
  }
}
