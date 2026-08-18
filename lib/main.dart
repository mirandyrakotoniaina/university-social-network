import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'database/database_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gbgbypwngabqqdmkxsoh.supabase.co',
    anonKey: 'sb_publishable_yUeIP33J-wdmCXnApyIg5w_16zJsNMT',
  );


  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}