import 'package:flutter/material.dart';


class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.lightBlue, // 프레임 색상
            width: 10,            // 프레임 두께
          ),
        ),
        child: Column(
          children: [
            /* 상단 절반 */
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey, Colors.black54],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        )
                    ),
                  ),
                  const Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Text('your section', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black),
                      iconSize: 50,
                      onPressed: () {
                        setState(() {
                          _showMenuPopup(context);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            /* 하단 절반 */
            Expanded(
              child: Stack(
                children: [
                  Container(
                    color: const Color(0xFFF2ECB3), // 하단 배경 색상
                  ),
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text('my section', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(
                        height: 300,
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenuPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Expanded(child: SizedBox()),
              const Expanded(child: SizedBox()),
              const Expanded(
                child: Text(
                  'Menu',
                  textAlign: TextAlign.center, // 중앙 정렬
                ),
              ), // 세 번째 구간 (Menu 텍스트)
              const Expanded(child: SizedBox()),
              ElevatedButton(
                onPressed: (){
                  Navigator.pop(context);
                },
                child: const Icon(Icons.close),
              )
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showExitConfirmationPopup(context); // 나가기 전 확인 팝업
                  },
                  child: const Text('나가기'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    // 여기에 버튼 동작 추가
                  },
                  child: const Text('어떤 기능 버튼'),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ],
        );
      },
    );
  }




  void _showExitConfirmationPopup(BuildContext context){
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context){
          return AlertDialog(
            title: const Text('나가시겠습니까?\n지금 나가면 항복 처리가 됩니다.', textAlign: TextAlign.center,),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {

                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('네'),
                  ),
                  ElevatedButton(
                    onPressed: (){
                      Navigator.pop(context);
                    },
                    child: const Text('아니오'),
                  )
                ],
              )

            ],
          );
        }
    );
  }
}
