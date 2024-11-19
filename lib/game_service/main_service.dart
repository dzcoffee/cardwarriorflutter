import 'package:card_warrior/game_service/background_service.dart';
import 'package:card_warrior/game_service/resource_service.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';

class MainService extends FlameGame{
  late HealthComponent health;
  late CostComponent cost;
  List<CardComponent> cards = [];
  List<CardComponent> visibleCards = [];

  late HealthComponent oppoHp;
  late CostComponent oppoCost;

  //게임 인스턴스 생성될 때 실행하는 함수
  @override
  Future<void> onLoad() async{
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
    for (int i = 0; i < 4; i++){
      final sprite = await loadCardImage('card.png');
      CardComponent card = CardComponent(cardSprite: sprite);
      card.isVisible = true;
      card.myIndex = i;
      cards.add(card);
    }
    cards[1].isGlowing = true;

    _updateVisibleCards();
  }

  Future<SpriteComponent> loadCardImage(String imagePath) async {
    final image = await Flame.images.load(imagePath);  // 이미지 로드
    final sprite = SpriteComponent.fromImage(image)
    ..size = Vector2(80, 120);
    return sprite;
  }

  void allMoveLeft(){
    for(var card in cards){
      card.moveLeft();
    }
    CardComponent.currentIndex = (CardComponent.currentIndex - 1 + cards.length) % cards.length;
    _animateCardTransition(Vector2(-100, 0));
  }

  void allMoveRight(){
    for(var card in cards){
      card.moveRight();
    }
    CardComponent.currentIndex = (CardComponent.currentIndex + 1) % cards.length;
    _animateCardTransition(Vector2(100, 0));
  }


  void _animateCardTransition(Vector2 offset) {
    for (var card in visibleCards) {
      card.move(offset, 0.5); // 부드러운 이동
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      _updateVisibleCards();
    });
  }


  void _updateVisibleCards() {
    removeAll(visibleCards);
    visibleCards.clear();

    final baseX = 200.0; // 중앙 기준 X 위치
    final baseY = 650.0; // 겹치는 Y 위치
    final overlapOffset = 5.0; // 카드 간의 겹침 정도
    final rotationAngles = [-0.1, 0.0, 0.1]; // 각 카드의 회전 각도 (라디안 값)

    cards[CardComponent.first].position = Vector2(baseX - 10 * overlapOffset, baseY);
    cards[CardComponent.first].angle = rotationAngles[0];
    visibleCards.add(cards[CardComponent.first]);
    add(cards[CardComponent.first]);

    cards[CardComponent.middle].position = Vector2(baseX, baseY);
    cards[CardComponent.middle].angle = rotationAngles[1];
    visibleCards.add(cards[CardComponent.middle]);
    add(cards[CardComponent.middle]);

    cards[CardComponent.last].position = Vector2(baseX + 10 * overlapOffset, baseY);
    cards[CardComponent.last].angle = rotationAngles[2];
    visibleCards.add(cards[CardComponent.last]);
    add(cards[CardComponent.last]);

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
    visibleCards.clear();
    CardComponent.currentIndex = 0;
    CardComponent.first = 0;
    CardComponent.middle = 1;
    CardComponent.last = 2;
  }
}