import 'package:flame/components.dart';

class BackgroundService extends SpriteComponent with HasGameRef{
  @override
  Future<void> onLoad() async{
    await super.onLoad();


    sprite = await gameRef.loadSprite('game_background.png');
    size = gameRef.size;
  }
}