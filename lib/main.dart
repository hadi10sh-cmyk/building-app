import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('dataBox');
  runApp(const MaterialApp(home: Scaffold(body: Center(child: Text("سلام هادی عزیز!")))));
}
