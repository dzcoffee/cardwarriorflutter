import 'dart:ui';

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

  late final yPosition;

  late HealthComponent health;
  late CostComponent cost;
  List<CardComponent> cards = [];

  int currentIndex = 1;
  int first = 0;
  int middle = 1;
  int last = 2;

  late HealthComponent oppoHp;
  late CostComponent oppoCost;

  //게임 인스턴스 생성될 때 실행하는 함수
  @override
  Future<void> onLoad() async{
    screenWidth = size.x;
    screenHeight = size.y;
    cardPositions = cardPositions.map((num)=> num * screenWidth).toList();

    yPosition = screenHeight * 0.85;

    final BackgroundService _ = BackgroundService();
    add(_);
    await super.onLoad();
    health = HealthComponent(initialHealth: 20, maxHealth: 20)
      ..position = Vector2(-10, 400);
    add(health);
    cost = CostComponent(initialCost: 20, maxCost: 20)
    ..position = Vector2(160, 400);
    add(cost);

    //상대 정보
    oppoHp = HealthComponent(initialHealth: 20, maxHealth: 20)
      ..position = Vector2(-10, 30);
    add(oppoHp);
    oppoCost = CostComponent(initialCost: 20, maxCost: 20)
      ..position = Vector2(160, 30);
    add(oppoCost);

    //카드 초기화
    for (int i = 0; i < 5; i++){
      final sprite = await loadCardImage('card.png');
      CardComponent card = CardComponent(cardSprite: sprite);
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

    print(currentIndex);
    //카드 전부 이동해야함
    if(currentIndex == first){
      //이전카드 -> first
      cards[first-1].position = Vector2(cardPositions[0], yPosition);
      add(cards[first-1]);
      cards[first-1].add(move(Vector2(cardPositions[1], yPosition), 0.3));
      //first -> middle
      cards[first].add(move(Vector2(cardPositions[2], yPosition), 0.3));
      //middle -> last
      cards[middle].add(move(Vector2(cardPositions[3], yPosition), 0.3));
      //last -> 이후 카드
      cards[last].add(move(Vector2(cardPositions[4], yPosition), 0.5));
      remove(cards[last]);
      Future.delayed(Duration(milliseconds: 100), () {
        first--;
        middle--;
        last--;
      });
    }
    cards[--currentIndex].isGlowing = true;

  }

  void MoveRight(){
    int length = cards.length;
    print(currentIndex);
    if(currentIndex == length - 1) return;

    cards[currentIndex].isGlowing = false;
    //전부 다 움직여야 함
    if(currentIndex == last){
      //이후 카드 -> last
      cards[last + 1].position = Vector2(cardPositions[4], yPosition);
      add(cards[last+1]);
      cards[last + 1].add(move(Vector2(cardPositions[3], yPosition), 0.3));
      //last -> middle
      cards[last].add(move(Vector2(cardPositions[2], yPosition), 0.3));
      //middle -> first
      cards[middle].add(move(Vector2(cardPositions[1], yPosition), 0.3));
      //first -> 이전 카드
      cards[first].add(move(Vector2(cardPositions[0], yPosition), 0.5));
      remove(cards[first]);
      Future.delayed(Duration(milliseconds: 100), () {
        first++;
        middle++;
        last++;
      });

    }
    cards[++currentIndex].isGlowing = true;
  }

  void drawCard() async{
      final sprite = await loadCardImage('card.png');
      CardComponent card = CardComponent(cardSprite: sprite);
      card.position = Vector2(screenWidth * 0.1, size.y * 0.6);
      card.myIndex = cards.length;
      cards.add(card);
      add(card);
      card.add(move(Vector2(cardPositions[4], yPosition), 0.7));
      Future.delayed(Duration(milliseconds: 700), (){
        remove(card);
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
    cards.clear();
  }
}