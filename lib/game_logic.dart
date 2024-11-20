import 'package:flutter/material.dart';

class Card{
  String _name;
  int _cost;
  int _hp;
  int _atk;
  int _type;

  Card(this._name, this._cost, this._hp, this._atk, this._type);

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

  void attackUser(User player){
    if(player.cardOnField.isEmpty){
      player._health -= _atk;
    }
  }

  String toString() {
    return "Card(name: $_name, cost: $_cost, hp: $_hp, atk: $_atk, type: $_type)";
  }

  Widget toWidget(String imagePath) {
    const typeNames = {
      0: 'Soldier',
      1: 'Warrior',
      2: 'Magician',
      3: 'Archer',
      4: 'Assassin'
    };
    String typeString = typeNames[_type] ?? 'Unknown';

    return Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        /*
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
        */
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Cost: $_cost",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  "HP: $_hp",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ATK: $_atk",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  "Type: $typeString",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class User{
  int _money = 1;
  int _health = 20;
  String _username;

  List<Card> cardDeck = [];
  List<Card> cardOnField = [];
  List<Card> cardOnHand = [];

  User(this._username);

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

  void turnEnd(User other){
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