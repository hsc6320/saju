import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk_user.dart';
import 'package:saju/Login/google_login.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _emailId(String? email) {
  if (email == null || email.isEmpty) return null;
  return email.split('@').first;
}

  // void _login() async {
  //   setState(() => _isLoading = true);

  //   try {
  //     // 성공 → 홈 화면으로 이동
  //     Navigator.pushReplacementNamed(context, '/home');
  //   } catch (e) {
  //     // 실패 → 에러 메시지 표시
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('로그인 실패: ${e.toString()}')),
  //     );
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }
  void _login() async {
    setState(() => _isLoading = true);

    try {
      // 실제 이메일/비밀번호 로그인 처리 (예시)
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = cred.user;
      final loginId = user?.displayName ?? user?.email ?? user?.uid ?? '사용자';

      // 🔑 이전 화면으로 "로그인 아이디"만 돌려보냄
      Navigator.pop(context, loginId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();
    return Scaffold(
      appBar: AppBar(
       // backgroundColor: const Color(0xFFFAF3EA),
        elevation: 0,
        centerTitle: true,
       /* title: const Text(
          '사주 로그인',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),*/
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("사주 로그인", style: TextStyle(fontSize: 28)),
            SizedBox(height: 50),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: '이메일'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: '비밀번호'),
            ),
            SizedBox(height: 24),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: Text('로그인'),
                  ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: Text('회원가입'),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.login),
              label: Text('구글로 로그인'),
              // onPressed: () async {
              //   try {
              //     final user = await _authService.signInWithGoogle();
              //     if (user != null) {
              //       // 🔽 Firestore users 컬렉션 자동 생성
              //       final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
              //       await FirebaseFirestore.instance
              //               .collection('users')
              //               .doc(user.uid);
              //               //.update({'isLoggedIn': true});

              //       final snapshot = await userDoc.get();
              //       if (!snapshot.exists) {
              //         // 🔔 Firestore에 사용자 문서가 없으면 = 첫 로그인 = 회원가입
              //         await userDoc.set({
              //           'email': user.email,
              //           'displayName': user.displayName,
              //            'provider': 'google',
              //           'createdAt': FieldValue.serverTimestamp(),
              //           'isLoggedIn': true,
              //           'lastLoginAt': FieldValue.serverTimestamp(),
              //         });
              //       } else {
              //          // 기존 사용자 → 로그인 상태 갱신
              //         await userDoc.update({
              //           'isLoggedIn': true,
              //           'lastLoginAt': FieldValue.serverTimestamp(),
              //         });
              //       }
              //       if(snapshot.exists) {
              //         final data = snapshot.data(); // Map<String, dynamic>
              //         Navigator.pushReplacementNamed(context, '/'); // 홈 화면으로 이동 HomeScreen()
              //         print("Firestore 유저 정보: $data");
              //       } else {
              //         print("해당 문서는 존재하지 않습니다.");
              //       }
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         SnackBar(content: Text('${user.displayName}님 환영합니다!')),
              //       );
                    
              //     } else {
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         SnackBar(content: Text('로그인 취소됨')),
              //       );
              //     }
              //   } catch (e) {
              //     print("구글 로그인 오류 : $e\n stack");
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       SnackBar(content: Text('구글 로그인 오류: ${e.toString()}')),
              //     );
              //   }

              // },
              onPressed: () async {
                try {
                  final user = await _authService.signInWithGoogle();
                  if (user != null) {
                    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
                    final snapshot = await userDoc.get();

                    if (!snapshot.exists) {
                      await userDoc.set({
                        'email': user.email,
                        'displayName': user.displayName,
                        'provider': 'google',
                        'createdAt': FieldValue.serverTimestamp(),
                        'isLoggedIn': true,
                        'lastLoginAt': FieldValue.serverTimestamp(),
                      });
                    } else {
                      await userDoc.update({
                        'isLoggedIn': true,
                        'lastLoginAt': FieldValue.serverTimestamp(),
                      });
                    }

                    final loginId = _emailId(user.email)        // 1순위: hsc6320
                                    ?? user.displayName                     // 2순위: 홍승창
                                    ?? user.uid;                            // 3순위: uid

                    print("login Screen() 로그인정보 : $loginId, user.email : ${user.email}, user.uid : ${user.uid}");

                    // 🔑 여기서 이전 화면으로 아이디만 리턴
                    Navigator.pop(context, loginId);

                    // (SnackBar는 LoginScreen이 아니라 이전 화면에서 띄우는 게 자연스럽지만
                    //  그냥 두어도 동작은 함)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${user.displayName ?? user.email}님 환영합니다!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('로그인 취소됨')),
                    );
                  }
                } catch (e) {
                  print("구글 로그인 오류 : $e\n stack");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('구글 로그인 오류: $e')),
                  );
                }
              },

            ),

            ElevatedButton.icon(
              icon: Icon(Icons.login),
              label: Text('카카오톡으로 로그인'),
              onPressed: () async {
                try {
                  final kakaoUser = await _authService.signInWithKakao();
                  if (kakaoUser != null) {
                    // 🔐 추가 동의 (OpenID 스코프 포함)
                    final kakaoToken = await UserApi.instance.loginWithNewScopes(['openid', 'profile', 'account_email']);
                    //final kakaoToken = await kakao.UserApi.instance.loginWithKakaoAccount(scopes: ['openid', 'profile', 'account_email']);
                    final idToken = kakaoToken.idToken;
                    if (idToken != null) {
                      final payload = parseJwt(idToken);
                      final uid = payload['sub'];
                      final email = payload['email'];
                      final nickname = payload['nickname'];

                      //final uid = kakaoUser.id.toString();
                      //final email = kakaoUser.kakaoAccount?.email ?? '';
                      //final nickname = kakaoUser.kakaoAccount?.profile?.nickname ?? '';
                      
                      // 🔽 Firestore users 컬렉션 자동 생성
                      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
                      final snapshot = await userDoc.get();
                      
                      if (!snapshot.exists) {
                        // 🔔 Firestore에 사용자 문서가 없으면 = 첫 로그인 = 회원가입
                        await userDoc.set({
                          'email': email,
                          'displayName': nickname,
                          'provider': 'kakao',
                          'createdAt': FieldValue.serverTimestamp(),
                          'isLoggedIn': true,
                          'lastLoginAt': FieldValue.serverTimestamp(),
                        });
                      } else {
                        // 기존 사용자 → 로그인 상태 갱신
                        await userDoc.update({
                          'isLoggedIn': true,
                          'lastLoginAt': FieldValue.serverTimestamp(),
                        });
                      }
                      if(snapshot.exists) {
                        final data = snapshot.data(); // Map<String, dynamic>
                        Navigator.pushReplacementNamed(context, '/'); // 홈 화면으로 이동 HomeScreen()
                        print("Firestore 유저 정보: $data");
                      } else {
                        print("해당 문서는 존재하지 않습니다.");
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$nickname님 환영합니다!')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('로그인 취소됨')),
                    );
                  }
                } catch (e) {
                  print("카카오 로그인 오류 : $e\n stack");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('카카오 로그인 오류: ${e.toString()}')),
                  );
                }
              
              },
            ),
          ],
        ),
      ),
    );
  }
}
