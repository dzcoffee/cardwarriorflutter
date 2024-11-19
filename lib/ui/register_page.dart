import 'package:card_warrior/ui/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _authentication = FirebaseAuth.instance;

  void _register() async{
    String email = _emailController.text;
    String password = _passwordController.text;

    try{
      final newUser =
      await _authentication.createUserWithEmailAndPassword(
          email: email, password: password);
      if(newUser.user != null){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('회원가입이 완료되었습니다.'),
          duration: Duration(seconds: 3),
        ));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
      }
    }catch(e){
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 16,),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 16,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: (){
                    _register();
                  },
                  child: const Text('회원가입'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

