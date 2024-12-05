import 'dart:developer';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import '../game_logic.dart';

class HealthComponent extends PositionComponent {
  final double initialHealth;
  final double maxHealth;
  double currentHealth;

  HealthComponent({
    required this.initialHealth,
    required this.maxHealth,
  }) : currentHealth = initialHealth;

  void damaged(double damage) {
    currentHealth = (currentHealth - damage).clamp(0, maxHealth);
  }

  void heal(double healAmount) {
    currentHealth = (currentHealth + healAmount).clamp(0, maxHealth);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final progress = currentHealth / maxHealth;

    // 체력 원형 바 그리기
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final progressPaint = Paint()
      ..color = Colors.red[300]!
      ..style = PaintingStyle.fill;

    // 원형 바 그리기
    final rect = Rect.fromCircle(center: Offset(position.x + 75, position.y + 35), radius: 50);
    canvas.drawCircle(Offset(position.x + 75, position.y + 35), 50, paint);

    // 체력 비율에 따른 원형 바 채우기
    final sweepAngle = 2 * 3.141592653589793 * progress;
    final path = Path()
      ..arcTo(rect, -3.141592653589793 / 2, sweepAngle, false);
    canvas.drawPath(path, progressPaint);

    // 체력 값 표시
    TextPainter(
      text: TextSpan(
        text: '${currentHealth.toStringAsFixed(0)} / ${maxHealth.toInt()}',
        style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(canvas, Offset(position.x + 45, position.y + 25));
  }
}

class CostComponent extends PositionComponent {
  final double initialCost;
  final double maxCost;
  double currentCost;

  CostComponent({
    required this.initialCost,
    required this.maxCost,
  }) : currentCost = initialCost;

  void spendCost(double damage) {
    currentCost = (currentCost - damage).clamp(0, maxCost);
  }

  void getCost(double healAmount) {
    currentCost = (currentCost + healAmount).clamp(0, maxCost);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final progress = currentCost / maxCost;

    // 코스트 원형 바 그리기
    final paint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;

    final progressPaint = Paint()
      ..color = Colors.amber[300]!
      ..style = PaintingStyle.fill;

    // 원형 바 그리기
    final rect = Rect.fromCircle(center: Offset(position.x + 75, position.y + 35), radius: 50);
    canvas.drawCircle(Offset(position.x + 75, position.y + 35), 50, paint);

    // 코스트 비율에 따른 원형 바 채우기
    final sweepAngle = 2 * 3.141592653589793 * progress;
    final path = Path()
      ..arcTo(rect, -3.141592653589793 / 2, sweepAngle, false);
    canvas.drawPath(path, progressPaint);

    // 코스트 값 표시
    TextPainter(
      text: TextSpan(
        text: '${currentCost.toStringAsFixed(0)} / ${maxCost.toInt()}',
        style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(canvas, Offset(position.x + 45, position.y + 25));
  }

  void addCost(){
    currentCost = currentCost +1;
  }

  void minusCardCost(double cardCost){
    currentCost = currentCost - cardCost;
  }
}


class CardComponent extends PositionComponent with TapCallbacks{
  late World world;
  Warrior warrior;
  final SpriteComponent cardSprite;
  late RectangleComponent glowEffect;
  late TextComponent nameComponent;
  late TextComponent hpComponent;
  late TextComponent atkComponent;
  late TextComponent costComponent;
  late RectangleComponent backgroundTextBoxComponent;
  bool isGlowing = false; // 카드가 강조 상태인지 여부
  late int myIndex;


  CardComponent({required this.cardSprite, required this.warrior}) : super(priority: 1);

  final bgPaint = Paint()..color = Colors.white;


  @override
  Future<void> onLoad() async {
    super.onLoad();


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
      text: warrior.hp.toString(),
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
    super.onTapUp(event);
    print('hi');
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

}
