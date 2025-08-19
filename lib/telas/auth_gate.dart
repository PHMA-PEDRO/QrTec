// lib/telas/auth_gate.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qrtec_final/telas/tela_admin_dashboard.dart';
import 'package:qrtec_final/telas/tela_home.dart';
import 'package:qrtec_final/telas/tela_login.dart';
import 'package:qrtec_final/telas/tela_verificar_email.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return const TelaLogin();
        }
        final user = snapshot.data!;
        if (!user.emailVerified) {
          return const TelaVerificarEmail();
        }
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .get(),
          builder: (context, userDocSnapshot) {
            if (userDocSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (userDocSnapshot.hasData && userDocSnapshot.data!.exists) {
              final data = userDocSnapshot.data!.data() as Map<String, dynamic>;
              final String funcao = data['funcao'] ?? 'cliente';
              if (funcao == 'admin') {
                return const TelaAdminDashboard();
              } else {
                return const TelaHome();
              }
            }
            return const TelaHome();
          },
        );
      },
    );
  }
}
