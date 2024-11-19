import 'package:card_warrior/ui/login_page.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  double _opacity = 0.0;  //초기 불투명도 값

  @override
  void initState(){
    super.initState();

    //페이지 로드시 fade-in 애니메이션 시작
    Timer(Duration(milliseconds: 500), (){
      setState(() {
        _opacity = 1.0;
      });
    });

    //3초 후 페이지 이동
    Timer(const Duration(seconds: 3), (){
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(seconds: 2),
            child: Image.asset('assets/images/logo.png', width: 400, height: 400,)  //로고 이미지
        ),
      ),
    );
  }
}
