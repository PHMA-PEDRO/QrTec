// lib/main.dart (Versão Final para o Novo Projeto)

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:qrtec_final/firebase_options.dart'; // Mantém a referência do projeto novo
import 'package:firebase_app_check/firebase_app_check.dart';

// Importa a sua tela de login que você acabou de copiar
import 'package:qrtec_final/telas/tela_login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QrTec App', // Nome atualizado
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // MUDANÇA PRINCIPAL: Inicia na TelaLogin em vez da tela de exemplo
      home: const TelaLogin(),
    );
  }
}
