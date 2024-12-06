import 'package:flutter/material.dart';

class Warrior{
  String _name;
  int _cost;
  int _hp;
  int _atk;
  int _type;
  int _id;


  Warrior(this._name, this._cost, this._hp, this._atk, this._type, this._id);

  String get name => _name;
  int get cost => _cost;
  int get hp => _hp;
  int get atk => _atk;
  int get type => _type;
  int get id => _id;

  void attack(Warrior opponent){
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
    return "Card(id: $_id, name: $_name, cost: $_cost, hp: $_hp, atk: $_atk, type: $_type)";
  }

  Map<String, dynamic> toMap(){
    return{
      'name' : name,
      'cost' : cost,
      'hp': hp,
      'attack': _atk,
      'type': type,
      'id': id,
    };
  }
}

class Player{
  int _money = 1;
  int _health = 20;
  String _username;

  List<Warrior> cardDeck = [];
  List<Warrior> cardOnField = [];
  List<Warrior> cardOnHand = [];

  Player(this._username);

  void addCardToDeck(Warrior c){
    if (cardDeck.length < 26) {
      cardDeck.add(c);
    }
  }

  void addCardToField(Warrior c){
    if (cardOnField.length < 7){
      cardOnField.add(c);
    }
  }

  void addCardToHand(Warrior c){
    if(cardDeck.isNotEmpty){
      cardOnHand.add(c);
    }
  }

  void deleteCardFromDeck(Warrior c){
    cardDeck.remove(c);
  }

  void deleteCardFromField(Warrior c){
    cardOnField.remove(c);
  }

  void deleteCardFromHand(Warrior c){
    cardOnHand.remove(c);
  }

  void turnEnd(Player other){
    other._money++;
    if (cardDeck.isNotEmpty && cardOnHand.length < 10) {
      Warrior drawnCard = cardDeck.removeLast();
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