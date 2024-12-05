import 'dart:ui';

import 'package:card_warrior/game_logic.dart';
import 'package:card_warrior/game_service/background_service.dart';
import 'package:card_warrior/game_service/resource_service.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';

class MainService extends FlameGame{

  late final screenWidth;
  late final screenHeight;

  List<double> cardPositions = [0.17, 0.27, 0.42, 0.57, 0.67];

  List<double> putPositionsX = [0.15, 0.4, 0.65, 0.15, 0.4, 0.65];
  List<double> putPositionsY = [0.47, 0.47, 0.47, 0.6, 0.6, 0.6];

  late final yPosition;

  late HealthComponent health;
  late CostComponent cost;
  List<CardComponent> cards = [];
  List<CardComponent> onField = [];
  Map<CardComponent, int> existField = {};
  late var enlargedImage;
  late CardComponent enlargedCard;

  CardComponent? selectedCard = null;

  int currentIndex = 1;
  int first = 0;

  late HealthComponent oppoHp;
  late CostComponent oppoCost;

  //게임 인스턴스 생성될 때 실행하는 함수
  @override
  Future<void> onLoad() async{
    screenWidth = size.x;
    screenHeight = size.y;
    cardPositions = cardPositions.map((num)=> num * screenWidth).toList();
    yPosition = screenHeight * 0.85;

    putPositionsX = putPositionsX.map((num)=> num * screenWidth).toList();
    putPositionsY = putPositionsY.map((num)=> num * screenHeight).toList();


    final BackgroundService _ = BackgroundService();
    add(_);
    await super.onLoad();
    health = HealthComponent(initialHealth: 20, maxHealth: 20)
      ..position = Vector2(-10, 400);
    add(health);
    cost = CostComponent(initialCost: 0, maxCost: 10)
    ..position = Vector2(140, 300);
    add(cost);

    //상대 정보
    oppoHp = HealthComponent(initialHealth: 20, maxHealth: 20)
      ..position = Vector2(-10, 30);
    add(oppoHp);
    oppoCost = CostComponent(initialCost: 20, maxCost: 20)
      ..position = Vector2(160, 30);
    add(oppoCost);


  }

  void setCards(List<Warrior> warriorList) async {
    //카드 초기화
    for (int i = 0; i < warriorList.length; i++){
      final sprite = await loadCardImage('cards/${warriorList[i].id}.JPG');
      CardComponent card = CardComponent(cardSprite: sprite, warrior: warriorList[i]);
      if(i < 3) {
        card.position = Vector2(
            cardPositions[i+1],
            yPosition);
        add(card);
      } else{
        card.position = Vector2(cardPositions[4], yPosition);
      }
      card.myIndex = i;
      cards.add(card);
    }
    cards[1].isGlowing = true;

    enlargedImage = cards[currentIndex].cardSprite;
    enlargedCard = CardComponent(cardSprite: cloneCardSprite(cards[currentIndex].cardSprite), warrior: cards[currentIndex].warrior);
    add(enlargedCard);

  }

  Future<SpriteComponent> loadCardImage(String imagePath) async {
    final image = await Flame.images.load(imagePath);  // 이미지 로드
    final sprite = SpriteComponent.fromImage(image)
    ..size = Vector2(80, 120);
    return sprite;
  }

  /// 카드 이동 애니메이션
  MoveToEffect move(offset, double duration) {
    return MoveToEffect(
      offset,
      EffectController(duration: duration, curve: Curves.easeInOut),
    );
  }

  RotateEffect rotate(double angle, double duration) {
    return RotateEffect.by(
      angle,
      EffectController(duration: duration, curve: Curves.easeInOut)
    );
  }

  void MoveLeft(){
    if(currentIndex == 0) return;

    cards[currentIndex].isGlowing = false;
    //카드 전부 이동해야함
    if(currentIndex == first && cards.length > 3){
      //이전카드 -> first
      cards[first-1].position = Vector2(cardPositions[0], yPosition);
      add(cards[first-1]);
      cards[first-1].add(move(Vector2(cardPositions[1], yPosition), 0.1));
      //first -> middle
      cards[first].add(move(Vector2(cardPositions[2], yPosition), 0.1));
      //middle -> last
      cards[first+1].add(move(Vector2(cardPositions[3], yPosition), 0.1));
      //last -> 이후 카드
      cards[first+2].add(move(Vector2(cardPositions[4], yPosition), 0.1));
      remove(cards[first+2]);
      Future.delayed(Duration(milliseconds: 100), () {
        first--;
      });
    }
    cards[--currentIndex].isGlowing = true;

    exhibitCard();
  }



  void MoveRight(){
    int length = cards.length;
    if(currentIndex == length - 1) return;

    cards[currentIndex].isGlowing = false;
    //전부 다 움직여야 함
    if(currentIndex == first+2 && cards.length > 3){
      //이후 카드 -> last
      cards[first + 3].position = Vector2(cardPositions[4], yPosition);
      add(cards[first + 3]);
      cards[first + 3].add(move(Vector2(cardPositions[3], yPosition), 0.1));
      //last -> middle
      cards[first + 2].add(move(Vector2(cardPositions[2], yPosition), 0.1));
      //middle -> first
      cards[first + 1].add(move(Vector2(cardPositions[1], yPosition), 0.1));
      //first -> 이전 카드
      cards[first].add(move(Vector2(cardPositions[0], yPosition), 0.1));

      Future.delayed(Duration(milliseconds: 100), () {
        remove(cards[first]);
        first++;
      });

    }
    cards[++currentIndex].isGlowing = true;

    exhibitCard();
  }

  SpriteComponent cloneCardSprite(SpriteComponent cardSprite){
    return SpriteComponent(
      sprite: cardSprite.sprite,
      size: cardSprite.size * 1.2,
      position: Vector2(screenWidth * 0.4, screenHeight * 0.7)
    );
  }

    void exhibitCard() async{
    print(currentIndex);
    enlargedCard = await CardComponent(cardSprite: cloneCardSprite(cards[currentIndex].cardSprite), warrior: cards[currentIndex].warrior);
    return;
  }

  void drawCard(Warrior warrior) async {
    final sprite = await loadCardImage('cards/${warrior.id}.JPG');
    CardComponent card = CardComponent(cardSprite: sprite, warrior: warrior);
    card.position = Vector2(screenWidth * 0.1, size.y * 0.6);
    card.myIndex = cards.length;
    cards.add(card);
    add(card);
    switch(cards.length){
      case 1:
        card.add(move(Vector2(cardPositions[1], yPosition), 0.7));
        Future.delayed(Duration(milliseconds: 700), () {
          card.isGlowing = true;
          currentIndex = 0;
          putBack();
        });
        break;
      case 2:
        card.add(move(Vector2(cardPositions[2], yPosition), 0.7));
        Future.delayed(Duration(milliseconds: 700), () {
          card.isGlowing = true;
          cards[currentIndex].isGlowing = false;
          currentIndex++;
          cards[currentIndex].isGlowing = true;
          putBack();
        });
        break;
      case 3:
        card.add(move(Vector2(cardPositions[3], yPosition), 0.7));
        Future.delayed(Duration(milliseconds: 700), () {
          card.isGlowing = true;
          cards[currentIndex].isGlowing = false;
          currentIndex++;
          cards[currentIndex].isGlowing = true;
          putBack();
        });
        break;
      default:
        card.add(move(Vector2(cardPositions[4], yPosition), 0.7));
        Future.delayed(Duration(milliseconds: 700), () {
          card.isGlowing = true;
          remove(card);
        });
        break;
    }
  }

  void putCard(){
    if(existField.length > 5) return;
    //필드 꽉참
    if(giveMeEmptyNumber() == -1){
      return;
    }
    int? number;
    if(existField.isEmpty){
      number = 0;
    } else{
      number = giveMeEmptyNumber();
    }

    CardComponent card = cards[currentIndex];
    card.isGlowing = false;
    cards[currentIndex].add(move(Vector2(
        putPositionsX[number],
        putPositionsY[number]),
        0.3));
    existField[card] = number;
    cards.removeAt(currentIndex);
    Future.delayed(Duration(milliseconds: 300), (){
      //이 주석 위로 카드를 판에서 내는 로직

      //남은 카드가 3장 초과
      if(cards.length > 2){
        if(first > 0){
          currentIndex = --first;
        }
        else{
          currentIndex = first + 2;
        }
      }
      //남은 카드가 2장 이하
      else{
        switch(cards.length){
          case 1:
            currentIndex = 0;
            break;
          default:
            if(currentIndex >0){
              currentIndex = 1;
              break;
            }
        }
      }
      add(cards[currentIndex]);
      cards[currentIndex].isGlowing = true;

      putBack();
      exhibitCard();
    });
  }


  void putBack(){
    switch(cards.length){
      case 1:
        cards[first].add(move(Vector2(cardPositions[1], yPosition), 0.1));
        break;
      case 2:
        cards[first].add(move(Vector2(cardPositions[1], yPosition), 0.1));
        cards[first + 1].add(move(Vector2(cardPositions[2], yPosition), 0.1));
        break;
      default:
        cards[first].add(move(Vector2(cardPositions[1], yPosition), 0.1));
        cards[first + 1].add(move(Vector2(cardPositions[2], yPosition), 0.1));
        cards[first + 2].add(move(Vector2(cardPositions[3], yPosition), 0.1));
        break;
    }
  }

  int giveMeEmptyNumber() {
    // 현재 사용 중인 value 값 추출
    List<int> usedValues = existField.values.toList();

    // 0~5 사이에서 비어 있는 최소값 찾기
    int? minEmptyValue;
    for (int i = 0; i <= 5; i++) {
      if (!usedValues.contains(i)) {
        minEmptyValue = i;
        break;
      }
    }

    // 비어 있는 최소값이 있다면 새로운 카드 추가
    if (minEmptyValue != null) {
      print(minEmptyValue);
      print(existField);
      return minEmptyValue;
    } else {
      return -1;
    }
  }


  //update마다 실행되는 함수
  @override
  void update(double dt) {
    super.update(dt);
  }

  // 인스턴스 해제될 때 실행되는 로직
  @override
  void onRemove(){
    super.onRemove();
    cards.clear();
  }
}