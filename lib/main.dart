// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:qrtec_final/firebase_options.dart';
import 'package:qrtec_final/telas/auth_gate.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurações para desabilitar App Check e reCAPTCHA
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configurar Firebase Auth para não usar reCAPTCHA
  // Isso é feito através das configurações do Android

  await initializeDateFormatting('pt_BR', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QrTec App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
