import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:provider/provider.dart';
import 'package:saju/SajuProvider.dart';
import 'package:saju/firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/saju_input_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 비동기 초기화를 위한 준비
  
  try {
    await dotenv.load(fileName: ".env");
    //print("🔑 Open API KEY: ${dotenv.env['OPENAI_API_KEY']}");
    
    //print("🔑 KaKao API KEY: ${dotenv.env['YOUR_NATIVE_APP_KEY']}");
    //print("🔑 KaKao API KEY: ${dotenv.env['YOUR_JAVASCRIPT_APP_KEY']}");
    KakaoSdk.init(
        nativeAppKey: dotenv.get('YOUR_NATIVE_APP_KEY'),//'${YOUR_NATIVE_APP_KEY}', //c747a58a93f19c338713e831e2ed60f6
        javaScriptAppKey: dotenv.get('YOUR_JAVASCRIPT_APP_KEY'),//'${YOUR_JAVASCRIPT_APP_KEY}',857eedec26bbaad073e6e61e1c8d867f
    );
  } catch (e) { 
    print("❌ .env 파일 로딩 실패: $e");
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Firebase 초기화
  runApp(
    ChangeNotifierProvider(
      create: (_) => SajuProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); 

  // This widget is the root of your application.
  @override
    Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ko'),
      supportedLocales: const [
        Locale('ko'), // 한국어 지원
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: '초씨역림 앱',
      theme: ThemeData(primarySwatch: Colors.indigo, fontFamily: 'Roboto',),
     // home: AuthGate(), // <-- 여기에 로그인 유지 판단,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/saju_input': (context) => const SajuInputScreen(),
        //'/saju_result': (context) => SajuResultScreen(SelectedTime: 1900-01-01,),
      },
    );
  }
}
