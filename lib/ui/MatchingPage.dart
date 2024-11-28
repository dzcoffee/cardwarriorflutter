import 'dart:async';
import 'package:card_warrior/ui/game_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchingPage extends StatefulWidget {
  const MatchingPage({super.key});

  @override
  State<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage> {
  bool isMatched = false;
  String matchMessage = '';
  final _authentication = FirebaseAuth.instance;
  User? loggedUser;
  String? userId = '';
  String matchedUserId = '';
  int check = 0;
  StreamSubscription<DocumentSnapshot>? matchNewSubs;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    userId = loggedUser?.email?.split('@').first;
    checkExistingMatch();
  }

  void getCurrentUser() {
    try {
      final user = _authentication.currentUser;
      if (user != null) {
        loggedUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> checkExistingMatch() async { // 존재하는 매치 중에 매칭되지 않은 거 loop문으로 찾아봄
    bool foundMatch = false; // 매칭된 유저 발견 여부
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('matches').get();
      for(var doc in snapshot.docs){
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if(data['isMatched'] == false && data['userId'] != userId){ // 대기중인 유저 발견
          updateMatchStatus(doc.id); // 매칭 정보 업데이트
          print('checking Existing Match 중에');
          setState(() {
            matchedUserId = data['userId'];
            matchMessage = '매칭유저가 발견되었습니다.';

            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        MatchedPage(matchedUserId: matchedUserId, docId: doc.id)));
          });
          break;
        }
      }
      if(!foundMatch) {
        await createInitialMatchDocument(); // 다 돌아봤는데 없으면 Match 새로 만듬
      }
  }

  void updateMatchStatus(String docId){
    FirebaseFirestore.instance.collection('matches').doc(docId).update({
      'matchedUserId' : userId,
      'isMatched' : true
    }).then((_){
      setState(() {
        isMatched = true;
      });
    });
  }

  Future<void> createInitialMatchDocument() async {
    // Firestore에 새로운 문서 생성
    FirebaseFirestore.instance.collection('matches').add({
      'userId': userId,
      'matchedUserId': null, // 초기값 설정
      'isMatched': false // 초기 상태 설정
    }).then((docRef) {
      // 문서 생성 후 리스닝을 시작
      listenToNewMatch(docRef.id);
    }).catchError((error) {
      print("Error creating match document: $error");
    });
  }

  void listenToNewMatch(String docRefId) {
     matchNewSubs = FirebaseFirestore.instance.collection('matches').doc(docRefId).snapshots().listen((docSnapshot) {
       if (docSnapshot.exists) {
        if (docSnapshot.data()?['isMatched'] == true) {
          print('sub 중단 직후 push');
          setState(() {
            matchedUserId = docSnapshot.data()?['matchedUserId'];
            isMatched = true;
            matchMessage = '매칭유저가 발견되었습니다.';
            stopSubs();


            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        MatchedPage(matchedUserId: matchedUserId, docId: docRefId)));
          });
        }
      }
    });
  }

  void stopSubs(){
    if(matchNewSubs != null){
      print('매치성공 구독 종료');
      matchNewSubs!.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('매칭 중'),
      ),
      body: Center(
        child: isMatched ? Text(matchMessage) : CircularProgressIndicator(),
      ),
    );
  }
}

class MatchedPage extends StatefulWidget {
  final String matchedUserId;
  final String docId;
  MatchedPage({required this.matchedUserId, required this.docId});

  @override
  State<MatchedPage> createState() => _MatchedPageState();
}

class _MatchedPageState extends State<MatchedPage> {
  Timer? _timer; // 타이머 변수
  final _authentication = FirebaseAuth.instance;
  User? loggedUser;
  String? userId = '';
  Map<String, dynamic>? documentData; // 문서 데이터를 저장할 변수
  String? docId;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    print('받아온 위젯 docID : ${widget.docId}');
    userId = loggedUser?.email?.split('@').first;
    deleteNotMatchedDoc();
    docId = widget.docId;

    // 5초 후에 다른 페이지로 이동
    _timer = Timer(Duration(seconds: 5), () {
      Navigator.pushNamed(context, '/gamepage', arguments: docId);
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 위젯이 dispose될 때 타이머 중지
    super.dispose();
  }

  void deleteNotMatchedDoc() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('matches').doc(widget.docId).get();
    if (snapshot.exists) {
      // 문서가 존재하면 데이터 저장
      documentData = snapshot.data() as Map<String, dynamic>?;
      print('matchedUserdId : ' + documentData?['matchedUserId']);
      print('유저 ID : ${userId}');
      if(documentData?['matchedUserId'] == userId){
        deleteDocByUserId(userId!);
        docId = widget.docId;
      }
    }
  }

  void deleteDocByUserId(String userId) async {
    // 'matches' 컬렉션에서 모든 문서 가져오기
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('matches').get();
    print('userID 로 삭제도미 : ${userId}');
    for (var doc in snapshot.docs) {
      // 각 문서의 'userId' 필드 값 확인
      if (doc.data() is Map<String, dynamic>) {
        var documentData = doc.data() as Map<String, dynamic>;
        if (documentData['userId'] == userId && documentData['matchedUserId'] == null ) {
          // userId가 일치하는 경우, 해당 문서 삭제
          await FirebaseFirestore.instance.collection('matches').doc(doc.id).delete();

          print('문서 삭제됨: ${doc.id}');
        }
      }
    }
  }

  void getCurrentUser() {
    try {
      final user = _authentication.currentUser;
      if (user != null) {
        loggedUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('매칭 완료'),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('매칭된 유저'),
          SizedBox(
            height: 20,
          ),
          Text(widget.matchedUserId)
        ],
      )),
    );
  }
}
