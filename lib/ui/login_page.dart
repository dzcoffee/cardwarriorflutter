import 'package:card_warrior/ui/main_page.dart';
import 'package:card_warrior/ui/register_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _authentication = FirebaseAuth.instance;
  
  void _login() async{
    String email = _emailController.text;
    String password = _passwordController.text;

    if(email.isEmpty || password.isEmpty){
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('에러!'),
          content: const Text('아이디와 비밀번호를 입력 해주세요!'),
          actions: [
            TextButton(
              child: const Text('확인'),
              onPressed: () => Navigator.pop(context),
            )
          ],
        )
      );
    }else{
      try{
        final currentUser =
        await _authentication.signInWithEmailAndPassword(
            email: email, password: password);
        if(currentUser.user != null){
          String? username = currentUser.user?.email?.split('@').first;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${username}님 환영합니다.'),
            duration: Duration(seconds: 3),
          ));
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainPage()));
        }
      }catch(e){
        print(e);
      }

    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/loginbackground.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 20,
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 16,),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: '비밀번호',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white
                  ),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 16,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                      width: 60,
                    ),
                    ElevatedButton(
                      onPressed: _login,
                      child: const Text('로그인'),
                    ),
                    TextButton(
                      child: Text('회원가입하기'),
                      onPressed: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterPage()));
                      },
                    )
                  ],
                )
              ],
            ),
          ),
        ]
      ),
    );
  }
}
