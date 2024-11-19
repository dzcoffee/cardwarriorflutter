import 'package:flutter/material.dart';

class PlayerStatus extends StatefulWidget {
  @override
  _PlayerStatusState createState() => _PlayerStatusState();
}

class _PlayerStatusState extends State<PlayerStatus> {
  int hp = 100; // 체력 초기 값

  void decreaseHp(int damage) {
    setState(() {
      hp = (hp - damage).clamp(0, 100); // hp는 0에서 100 사이로 유지
    });
  }

  void increaseHp(int heal) {
    setState(() {
      hp = (hp + heal).clamp(0, 100); // hp는 0에서 100 사이로 유지
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        HealthBottle(hp: hp),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => decreaseHp(15), // 예시로 15 데미지 감소
          child: Text("Take 15 Damage"),
        ),
        ElevatedButton(
          onPressed: () => increaseHp(15), // 예시로 15 체력 회복
          child: Text("Heal 15 Health"),
        ),
      ],
    );
  }
}



class HealthBottle extends StatelessWidget {
  final int hp;

  const HealthBottle({Key? key, required this.hp}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(100, 300),
      painter: HealthBottlePainter(hp),
    );
  }
}

class HealthBottlePainter extends CustomPainter {
  final int hp;

  HealthBottlePainter(this.hp);

  @override
  void paint(Canvas canvas, Size size) {
    final double hpRatio = hp / 100;

    // 병 외곽선
    final bottlePaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    // 체력바의 색상
    final healthPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Colors.green,
          Colors.orange,
          Colors.red,
        ],
        stops: [0.0, 0.7, 1.0], // 그라데이션 색상 비율
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // 병의 모양
    Path bottlePath = Path();
    bottlePath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
        const Radius.circular(20),
      ),
    );

    var healthRRect;
    if (hp>0){
      healthRRect = RRect.fromRectAndRadius(
        // 체력바 위치랑 크기
        Rect.fromLTWH(
          20,
          size.height - (size.height * hpRatio) + 20, // HP 값에 따라 위치 조정
          size.width - 40,
          size.height * hpRatio - 40, // 체력에 비례한 높이
        ),
        const Radius.circular(20),
      );
    } else{
      healthRRect = RRect.fromRectAndRadius(
        // 체력바 위치랑 크기
        Rect.fromLTWH(
          20,
          size.height - (size.height * hpRatio) + 20, // HP 값에 따라 위치 조정
          size.width - 40,
          0, // 체력에 비례한 높이
        ),
        const Radius.circular(20),
      );
    }


    // 체력 색상 그리기
    canvas.drawRRect(healthRRect, healthPaint);

    // 병 외곽선 그리기
    canvas.drawPath(bottlePath, bottlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
