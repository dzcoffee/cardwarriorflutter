import 'dart:developer';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/palette.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import '../game_logic.dart';


class HealthComponent extends PositionComponent {
  final int initialHealth;
  final int maxHealth;
  int currentHealth;
  final double radius;


  HealthComponent({
    required this.initialHealth,
    required this.maxHealth,
    this.radius = 35.0,
  }) : currentHealth = initialHealth;

  void damaged(int damage) {
    currentHealth = (currentHealth - damage).clamp(0, maxHealth);
  }

  void heal(int healAmount) {
    currentHealth = (currentHealth + healAmount).clamp(0, maxHealth);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final circlePaint = Paint()..color = Colors.red;
    canvas.drawCircle(Offset(radius, radius), radius, circlePaint);

    // 텍스트 스타일 설정
    final textPainter = TextPainter(
      text: TextSpan(
        text: "${currentHealth}/${maxHealth}",
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();


    // 텍스트를 원의 중앙에 배치
    final textOffset = Offset(
      radius - textPainter.width / 2,
      radius - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

}



class CostComponent extends PositionComponent {
  int initialCost;
  final int maxCost;
  int currentCost;
  final radius;

  CostComponent({
    required this.initialCost,
    required this.maxCost,
    this.radius = 35.0,
  }) : currentCost = initialCost;


  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final circlePaint = Paint()..color = Colors.yellowAccent;
    canvas.drawCircle(Offset(radius, radius), radius, circlePaint);

    // 텍스트 스타일 설정
    final textPainter = TextPainter(
      text: TextSpan(
        text: "${currentCost}/${maxCost}",
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();


    // 텍스트를 원의 중앙에 배치
    final textOffset = Offset(
      radius - textPainter.width / 2,
      radius - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  void addCost(){
    print('지금 코스트 ${initialCost} : ${currentCost}');
    initialCost = initialCost + 1;
    currentCost = initialCost;
  }

  void minusCardCost(int cardCost){
    currentCost = currentCost - cardCost;
  }
}

class CardComponent extends PositionComponent with TapCallbacks{
  final void Function(CardComponent) onCardClicked;

  static bool tapOnOff = false;
  bool enlargable = true;
  bool isClicked = false;

  Warrior warrior;
  late int hpPoint;
  final SpriteComponent cardSprite;
  late RectangleComponent glowEffect;
  late TextBoxComponent nameComponent;
  late TextBoxComponent hpComponent;
  late TextBoxComponent atkComponent;
  late TextBoxComponent costComponent;
  late RectangleComponent backgroundTextBoxComponent;
  bool isGlowing = false; // 카드가 강조 상태인지 여부
  int myIndex = -1;
  bool isVisible = false;


  CardComponent({required this.cardSprite, required this.onCardClicked, required this.warrior}) : super(priority: 1);

  final bgPaint = Paint()..color = Colors.white;


  @override
  Future<void> onLoad() async {
    super.onLoad();

    hpPoint = warrior.hp;
    this.size = cardSprite.size;

    // 빛나는 효과 초기화
    glowEffect = RectangleComponent(
      size: cardSprite.size, // 카드 크기보다 약간 더 큼
      position: Vector2(-10, -10), // 중심 맞추기
      paint: Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.5) // 황금빛 강조
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0,
    );

    nameComponent = TextBoxComponent(
      text: warrior.name,
      size: cardSprite.size,
      align: Anchor.bottomCenter,
      boxConfig: TextBoxConfig(
        margins: EdgeInsets.all(8.0),
      ),
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 6.0,
          color: Colors.black,
          background: bgPaint,
        )
      ),
    );

    atkComponent = TextBoxComponent(
      text: warrior.atk.toString(),
      size: cardSprite.size,
      position: Vector2(-2, 2),
      align: Anchor.bottomLeft,
      textRenderer: TextPaint(
          style: TextStyle(
            fontSize: 10.0,
            color: Colors.red,
          )
      ),
    );

    hpComponent = TextBoxComponent(
      text: hpPoint.toString(),
      size: cardSprite.size,
      position: Vector2(2, 2),
      align: Anchor.bottomRight,
      textRenderer: TextPaint(
          style: TextStyle(
            fontSize: 10.0,
            color: Colors.green,
          )
      ),
    );

    costComponent = TextBoxComponent(
      text: warrior.cost.toString(),
      size: cardSprite.size,
      position: Vector2(-2, -2),
      boxConfig: TextBoxConfig(
        margins: EdgeInsets.all(8.0),
      ),
      textRenderer: TextPaint(
          style: TextStyle(
            fontSize: 10.0,
            color: Colors.blue,
          )
      ),
    );

    // backgroundTextBoxComponent = RectangleComponent(
    //   size: Vector2(nameComponent.+ 2, nameComponent.height + 2), // 패딩을 고려한 크기
    //   position: nameComponent.position,
    //   paint: bgPaint, // 배경 색상
    // );


    add(cardSprite); // 카드 스프라이트 추가
    //add(backgroundTextBoxComponent);
    add(nameComponent);
    add(costComponent);
    add(atkComponent);
    add(hpComponent);
  }


  @override
  void onTapUp(TapUpEvent event){
    if(!isVisible) {
      print('Invisible');
      return;
    }
    onCardClicked(this);
    super.onTapUp(event);

  }


  @override
  void render(Canvas canvas) {
    if (isGlowing) {
      glowEffect.render(canvas); // 강조 효과 그리기
    }

    Rect rect = Rect.fromLTWH(0, 0, width, height);
    canvas.drawRect(rect, bgPaint);
    super.render(canvas);
  }

  void attack(CardComponent cardComponent){
    warrior.attack(cardComponent.warrior); // 현재 Card의 hp 업데이트
    hpPoint = warrior.hp;
    cardComponent.hpPoint = cardComponent.warrior.hp;
    hpComponent.text = hpPoint.toString();
    cardComponent.hpComponent.text = cardComponent.hpPoint.toString();
    print('어택 중입니다 ${hpPoint} && ${hpComponent.text} && ${cardComponent.hpComponent.text}');

    super.update(0);
  }

}