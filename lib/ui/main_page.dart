import 'package:card_warrior/effect/splash_page.dart';
import 'package:card_warrior/ui/MatchingPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './customizing_page.dart';
import './game_page.dart';
import './option_page.dart';
import './login_page.dart';

import 'package:card_warrior/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';


void main(){
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    return MaterialApp(
      title: 'Main Page',
      theme: ThemeData(
        primaryColor: const Color.fromRGBO(184, 156, 120, 1.0),
        useMaterial3: false,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(184, 156, 120, 1.0),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromRGBO(184, 156, 120, 1.0),
            foregroundColor: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
      ),
      initialRoute: '/splashpage',
      routes: {
        '/splashpage': (context) => const SplashPage(),
        '/mainpage': (context) => const MainPage(),
        //'/gamepage': (context) => const GamePage(),
        '/custompage': (context) => const CustomizingPage(),
        '/optionpage': (context) => const OptionPage(),
        '/matchingpage' : (context) => const MatchingPage(),
        '/loginpage' : (context) => const LoginPage()
      },
    );
  }
}


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _authentication = FirebaseAuth.instance;
  User? loggedUser;

  @override
  void initState(){
    super.initState();
    getCurrentUser();
    String? username = loggedUser?.email?.split('@').first;
    print(username);
  }

  void getCurrentUser(){
    try{
      final user = _authentication.currentUser;
      if(user != null){
        loggedUser = user;
      }
    }catch(e){
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/mainbackground.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 100,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50)
                  ),
                  child: const Text('게임시작'),
                  onPressed: (){
                    setState(() {
                      Navigator.pushNamed(context, '/matchingpage');
                      //Navigator.push(context, MaterialPageRoute(builder: (context) => GamePage(docId: 'test')));
                    });
                  },
                ),
                const SizedBox(
                  height: 100,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50)
                  ),
                  child: const Text('덱 커스터마이징'),
                  onPressed: (){
                    setState(() {
                      Navigator.pushNamed(context, '/custompage');
                    });
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50)
                  ),
                  child: const Text('로그아웃'),
                  onPressed: (){
                    setState(() {
                      Navigator.pushNamed(context, '/loginpage');
                    });
                  },
                ),
              ],
            ),
          ),
        ]
      ),
    );
  }
}