import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

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
    final rect = Rect.fromCircle(center: Offset(position.x + 75, position.y + 75), radius: 50);
    canvas.drawCircle(Offset(position.x + 75, position.y + 75), 50, paint);

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
      ..paint(canvas, Offset(position.x + 45, position.y + 60));
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
    final rect = Rect.fromCircle(center: Offset(position.x + 75, position.y + 75), radius: 50);
    canvas.drawCircle(Offset(position.x + 75, position.y + 75), 50, paint);

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
      ..paint(canvas, Offset(position.x + 45, position.y + 60));
  }
}


class CardComponent extends PositionComponent {
  final SpriteComponent cardSprite;
  static int currentIndex = 0;
  static int first = 0;
  static int middle = 1;
  static int last = 2;
  late RectangleComponent glowEffect;
  bool isGlowing = false; // 카드가 강조 상태인지 여부
  bool isVisible = false;
  late int myIndex;

  CardComponent({required this.cardSprite});

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
    add(cardSprite); // 카드 스프라이트 추가
  }

  @override
  void render(Canvas canvas) {
    if (isGlowing) {
      glowEffect.render(canvas); // 강조 효과 그리기
    }
    super.render(canvas);
  }

  /// 카드 이동 애니메이션
  void move(Vector2 offset, double duration) {
    add(
      MoveByEffect(
        offset,
        EffectController(duration: duration, curve: Curves.easeInOut),
      ),
    );
  }

  void moveLeft() {
    int length = children.length;
    if(isVisible){
      if(myIndex == currentIndex){
        isVisible = false;
      } else if(myIndex == (currentIndex + 1) % length){
        isGlowing = false;
        first = myIndex;
      } else if(myIndex == (currentIndex + 2) % length){
        isGlowing = true;
        middle = myIndex;
        }
      } else{
      if(myIndex == (currentIndex + 3) % length){
        last = myIndex;
        isVisible = true;
      }
    }
  }

  void moveRight() {
    int length = children.length;
    if(isVisible){
      if(myIndex == currentIndex){
        isGlowing = true;
        middle = myIndex;
      } else if(myIndex == (currentIndex + 1) % length){
        last = myIndex;
        isGlowing = false;
      } else if(myIndex == (currentIndex + 2) % length){
        isVisible = false;
      }
    } else{
      if(myIndex == (currentIndex - 1 + length) % length){
        first = myIndex;
        isVisible = true;
      }
    }
  }


}