import 'dart:math';
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

  //내가 카드 놓는 좌표
  List<double> myFieldCardX = [0.15, 0.4, 0.65, 0.15, 0.4, 0.65];
  List<double> myFieldCardY = [0.47, 0.47, 0.47, 0.6, 0.6, 0.6];

  //상대방이 카드 놓는 좌표
  List<double> yourFieldCardX = [0.15, 0.4, 0.65, 0.15, 0.4, 0.65];
  List<double> yourFieldCardY = [0.15, 0.15, 0.15, 0.3, 0.3, 0.3];

  //내 손의 y좌표
  late final myPositionY;

  late HealthComponent health;
  late CostComponent cost;
  List<CardComponent> myCards = [];
  List<CardComponent> myOnField = [];

  List<CardComponent> yourCards = [];
  List<CardComponent> yourOnField = [];

  Map<CardComponent, int> myExistField = {};
  Map<CardComponent, int> yourExistField = {};

  late var enlargedImage;
  late CardComponent enlargedCard;

  CardComponent? selectedCard = null;

  int myCurrentIndex = 1;
  int first = 0;

  int myFieldIndex = -1;
  int yourFieldIndex = -1;

  late Vector2 yourDrawPosition;
  late Vector2 myDrawPosition;

  late HealthComponent oppoHp;
  late CostComponent oppoCost;


  //게임 인스턴스 생성될 때 실행하는 함수
  @override
  Future<void> onLoad() async{
    screenWidth = size.x;
    screenHeight = size.y;
    cardPositions = cardPositions.map((num)=> num * screenWidth).toList();
    myPositionY = screenHeight * 0.85;

    //플레이어 직접 공격 위치 설정
    yourDrawPosition = Vector2(screenWidth * 0.4, size.y * 0.03);
    myDrawPosition = Vector2(screenWidth * 0.4, size.y * 0.8);

    myFieldCardX = myFieldCardX.map((num)=> num * screenWidth).toList();
    myFieldCardY = myFieldCardY.map((num)=> num * screenHeight).toList();
    yourFieldCardX = yourFieldCardX.map((num)=> num * screenWidth).toList();
    yourFieldCardY = yourFieldCardY.map((num)=> num * screenHeight).toList();


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
            myPositionY);
        add(card);
      } else{
        card.position = Vector2(cardPositions[4], myPositionY);
      }

      myCards.add(card);
    }
    myCards[1].isGlowing = true;

    //상대방 카드 초기화
    for (int i = 0; i < 3; i++){
      final sprite = await loadCardImage('card.png');
      CardComponent card = CardComponent(cardSprite: sprite);
      yourCards.add(card);
    }


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

  ///카드 회전하는 함수인데 딱히 필요하지는 않음
  RotateEffect rotate(double angle, double duration) {
    return RotateEffect.by(
      angle,
      EffectController(duration: duration, curve: Curves.easeInOut)
    );
  }





  ///왼쪽 카드 선택
  void MoveLeft(){
    if(myCurrentIndex == 0) return;

    myCards[myCurrentIndex].isGlowing = false;
    //카드 전부 이동해야함
    if(myCurrentIndex == first && myCards.length > 3){
      //이전카드 -> first
      myCards[first-1].position = Vector2(cardPositions[0], myPositionY);
      add(myCards[first-1]);
      myCards[first-1].add(move(Vector2(cardPositions[1], myPositionY), 0.1));
      //first -> middle
      myCards[first].add(move(Vector2(cardPositions[2], myPositionY), 0.1));
      //middle -> last
      myCards[first+1].add(move(Vector2(cardPositions[3], myPositionY), 0.1));
      //last -> 이후 카드
      myCards[first+2].add(move(Vector2(cardPositions[4], myPositionY), 0.1));
      remove(myCards[first+2]);
      Future.delayed(Duration(milliseconds: 100), () {
        first--;
      });
    }
    myCards[--myCurrentIndex].isGlowing = true;
  }





  ///오른쪽 카드 선택

  void MoveRight(){
    int length = myCards.length;
    if(myCurrentIndex == length - 1) return;

    myCards[myCurrentIndex].isGlowing = false;
    //전부 다 움직여야 함
    if(myCurrentIndex == first+2 && myCards.length > 3){
      //이후 카드 -> last
      myCards[first + 3].position = Vector2(cardPositions[4], myPositionY);
      add(myCards[first + 3]);
      myCards[first + 3].add(move(Vector2(cardPositions[3], myPositionY), 0.1));
      //last -> middle
      myCards[first + 2].add(move(Vector2(cardPositions[2], myPositionY), 0.1));
      //middle -> first
      myCards[first + 1].add(move(Vector2(cardPositions[1], myPositionY), 0.1));
      //first -> 이전 카드
      myCards[first].add(move(Vector2(cardPositions[0], myPositionY), 0.1));

      Future.delayed(Duration(milliseconds: 100), () {
        remove(myCards[first]);
        first++;
      });

    }
    myCards[++myCurrentIndex].isGlowing = true;
  }


  ///카드 크게 보여줄 때 필요한 함수(이미 만들어진 카드를 새로운 객체로 복사)
  SpriteComponent cloneCardSprite(SpriteComponent cardSprite){
    return SpriteComponent(
      sprite: cardSprite.sprite,
      size: cardSprite.size * 3.0,
      position: Vector2(screenWidth * 0.2, screenHeight * 0.3)
    );
  }


    void exhibitCard() async{
    print(currentIndex);
    enlargedCard = await CardComponent(cardSprite: cloneCardSprite(cards[currentIndex].cardSprite), warrior: cards[currentIndex].warrior);
    return;
  }


  ///상대방 카드 드로우
  void drawYourCard() async{
    final sprite = await loadCardImage('card.png');
    CardComponent card = CardComponent(cardSprite: sprite);
    card.position = Vector2(screenWidth * 0.05, size.y * 0.3);
    yourCards.add(card);
    add(card);
    card.add(move(Vector2(screenWidth * 0.4, size.y * 0.05), 0.5));
    Future.delayed(Duration(milliseconds: 500), (){
      remove(card);
    });
  }

  ///카드 드로잉해서 손에 넣는 함수
  void drawMyCard(Warrior warrior) async {
    final sprite = await loadCardImage('cards/${warrior.id}.JPG');
    CardComponent card = CardComponent(cardSprite: sprite, warrior: warrior);
    card.position = Vector2(screenWidth * 0.1, size.y * 0.6);
    myCards.add(card);
    add(card);
    switch(myCards.length){
      case 1:
        card.add(move(Vector2(cardPositions[1], myPositionY), 0.7));
        Future.delayed(Duration(milliseconds: 700), () {
          card.isGlowing = true;
          myCurrentIndex = 0;
          putBack();
        });
        break;
      case 2:
        card.add(move(Vector2(cardPositions[2], myPositionY), 0.7));
        Future.delayed(Duration(milliseconds: 700), () {
          card.isGlowing = true;
          myCards[myCurrentIndex].isGlowing = false;
          myCurrentIndex++;
          myCards[myCurrentIndex].isGlowing = true;
          putBack();
        });
        break;
      case 3:
        card.add(move(Vector2(cardPositions[3], myPositionY), 0.7));
        Future.delayed(Duration(milliseconds: 700), () {
          card.isGlowing = true;
          myCards[myCurrentIndex].isGlowing = false;
          myCurrentIndex++;
          myCards[myCurrentIndex].isGlowing = true;
          putBack();
        });
        break;
      default:
        card.add(move(Vector2(cardPositions[4], myPositionY), 0.7));
        Future.delayed(Duration(milliseconds: 700), () {
          card.isGlowing = true;
          remove(card);
        });
        break;
    }
  }

  
  /// 맵에서 인덱스로 카드컴포넌트의 키 찾는 함수, 파라미터 val은 필드 위 해당 카드 인덱스
  CardComponent findCardKey(Map<CardComponent, int> map, int val){
    CardComponent key = map.entries
        .firstWhere((entry) => entry.value == val).key;
    return key;
  }

  ///카드 맵에 있는 다음 인덱스 반환
  int findNextValue(Map<CardComponent, int> map, int fieldIndex){
    List<int> values = map.values.toList();
    values.sort();
    // currentIndex 바로 다음 인덱스 찾음
    for (int value in values) {
      if (value > fieldIndex) {
        return value;
      }
    }
    //인덱스가 가장 클 경우
    return values.first;
  }
  ///카드 맵에 있는 이전 인덱스 반환
  int findPreviousValue(Map<CardComponent, int> map, int fieldIndex){
    List<int> values = map.values.toList();
    values.sort((a, b) => b.compareTo(a));
    // currentIndex 바로 이전 인덱스 찾음
    for (int value in values) {
      if (value < fieldIndex) {
        return value;
      }
    }
    //인덱스가 가장 작을 경우 (내림차순 정렬)
    return values.first;
  }


  ///카드를 필드에 내놓는 함수
  void putMyCard(){
    if(myExistField.length > 5 || myCards.isEmpty) return;
    //필드 꽉참
    if(giveMeEmptyNumber() == -1){
      return;
    }
    if(myExistField.isEmpty){
      myFieldIndex = 0;
    } else{
      findCardKey(myExistField, myFieldIndex).isGlowing = false;
      myFieldIndex = giveMeEmptyNumber();
    }
    CardComponent card = myCards[myCurrentIndex];
    myCards[myCurrentIndex].add(move(Vector2(
        myFieldCardX[myFieldIndex],
        myFieldCardY[myFieldIndex]),
        0.1));
    myExistField[card] = myFieldIndex;
    myCards.removeAt(myCurrentIndex);
    Future.delayed(Duration(milliseconds: 300), (){
      //이 주석 위로 카드를 판에서 내는 로직

      //남은 카드가 3장 초과
      if(myCards.length > 2){
        if(first > 0){
          myCurrentIndex = --first;
        }
        else{
          myCurrentIndex = first + 2;
        }
      }
      //남은 카드가 2장 이하
      else{
        switch(myCards.length){
          case 1:
            myCurrentIndex = 0;
            break;
          default:
            if(myCurrentIndex >0){
              myCurrentIndex = 1;
              break;
            }
        }
      }
      add(myCards[myCurrentIndex]);
      myCards[myCurrentIndex].isGlowing = true;

      putBack();
    });
  }

  ///상대방 카드를 필드에 놓는 함수
  /*positionIndex => 6개로 나뉜 상대방 필드 위 인덱스
  들어오는 값은 0부터 5까지밖에 없다.
   */
  void putYourCard(int positionIndex, String cardName) async{
    //yourFieldIndex는 필드 위 선택된 카드 중 이전에 선택된 인덱스
    if(yourFieldIndex != -1) {
      findCardKey(yourExistField, yourFieldIndex).isGlowing = false;
    }
    yourFieldIndex = positionIndex;

    final sprite = await loadCardImage(cardName);
    CardComponent card = CardComponent(cardSprite: sprite);
    card.position = Vector2(screenWidth * 0.4, size.y * 0.05);
    card.isGlowing = true;
    yourCards.add(card);
    add(card);
    card.add(move(Vector2(
        yourFieldCardX[yourFieldIndex],
        yourFieldCardY[yourFieldIndex]),
        0.3));
    //youExistField = Map ==> {카드객체 : 필드 인덱스}
    yourExistField[card] = yourFieldIndex;
  }

  ///카드 드로잉 후에 카드 정리하는 함수
  void putBack(){
    switch(myCards.length){
      case 1:
        myCards[first].add(move(Vector2(cardPositions[1], myPositionY), 0.1));
        break;
      case 2:
        myCards[first].add(move(Vector2(cardPositions[1], myPositionY), 0.1));
        myCards[first + 1].add(move(Vector2(cardPositions[2], myPositionY), 0.1));
        break;
      default:
        myCards[first].add(move(Vector2(cardPositions[1], myPositionY), 0.1));
        myCards[first + 1].add(move(Vector2(cardPositions[2], myPositionY), 0.1));
        myCards[first + 2].add(move(Vector2(cardPositions[3], myPositionY), 0.1));
        break;
    }
  }


  /// 상대방 필드 위 카드 선택 인터페이스
  void yourFieldLeft(){
    if(yourFieldIndex == -1){
      return;
    }
    CardComponent key = findCardKey(yourExistField, yourFieldIndex);
    key.isGlowing = false;

    yourFieldIndex = findPreviousValue(yourExistField, yourFieldIndex);
    key = findCardKey(yourExistField, yourFieldIndex);
    key.isGlowing = true;
  }

  void yourFieldRight(){
    if(yourFieldIndex == -1){
      return;
    }
    CardComponent key = findCardKey(yourExistField, yourFieldIndex);
    key.isGlowing = false;

    yourFieldIndex = findNextValue(yourExistField, yourFieldIndex);
    key = findCardKey(yourExistField, yourFieldIndex);
    key.isGlowing = true;
  }


  ///내 필드 위 카드 선택 인터페이스
  void myFieldLeft(){
    if(myFieldIndex == -1){
      return;
    }
    CardComponent key = findCardKey(myExistField, myFieldIndex);
    key.isGlowing = false;

    myFieldIndex = findPreviousValue(myExistField, myFieldIndex);
    key = findCardKey(myExistField, myFieldIndex);
    key.isGlowing = true;
  }

  void myFieldRight(){
    if(myFieldIndex == -1){
      return;
    }
    CardComponent key = findCardKey(myExistField, myFieldIndex);
    key.isGlowing = false;

    myFieldIndex = findNextValue(myExistField, myFieldIndex);
    key = findCardKey(myExistField, myFieldIndex);
    key.isGlowing = true;
  }



  int giveMeEmptyNumber() {
    // 현재 사용 중인 value 값 추출
    List<int> usedValues = myExistField.values.toList();

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
      print(myExistField);
      return minEmptyValue;
    } else {
      return -1;
    }
  }

  void myAttack(){
    CardComponent card = findCardKey(myExistField, myFieldIndex);
    int priority = card.priority;
    card.priority = 100;
    card.add(move(Vector2(myFieldCardX[myFieldIndex], myFieldCardY[myFieldIndex]+20), 0.2));
    Future.delayed(Duration(milliseconds: 200), (){
      if(yourExistField.length != 0) {
        card.add(move(
            Vector2(yourFieldCardX[yourFieldIndex],
                yourFieldCardY[yourFieldIndex] + 20),
            0.2));
      } else{
        card.add(move(
            yourDrawPosition,
            0.2));
      }
      Future.delayed(Duration(milliseconds: 400), (){
        card.add(move(Vector2(myFieldCardX[myFieldIndex], myFieldCardY[myFieldIndex]), 0.2));
        card.priority = priority;
      });
    });
  }

  void yourAttack(){
    CardComponent card = findCardKey(yourExistField, yourFieldIndex);
    int priority = card.priority;
    card.priority = 100;
    card.add(move(Vector2(yourFieldCardX[yourFieldIndex], yourFieldCardY[yourFieldIndex]-20), 0.2));
    Future.delayed(Duration(milliseconds: 200), (){
      if(myExistField.length != 0) {
        card.add(move(
            Vector2(
                myFieldCardX[myFieldIndex], myFieldCardY[myFieldIndex] - 20),
            0.2));
      } else{
        card.add(move(
            myDrawPosition,
            0.2));
      }
      Future.delayed(Duration(milliseconds: 400), (){
        card.add(move(Vector2(myFieldCardX[yourFieldIndex], yourFieldCardY[yourFieldIndex]), 0.2));
        card.priority = priority;
      });
    });
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
    myCards.clear();
  }
}


