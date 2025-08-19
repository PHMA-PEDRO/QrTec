// lib/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Imports para tela_admin_dashboard e tela_home foram removidos

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signInWithEmailAndPassword({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    // O AuthGate agora cuida do redirecionamento, então não fazemos mais nada aqui.
  }

  Future<void> createUserWithEmailAndPassword({
    required BuildContext context,
    required String nome,
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = userCredential.user!;

    await user.sendEmailVerification();

    await _firestore.collection('usuarios').doc(user.uid).set({
      'uid': user.uid,
      'nome': nome,
      'email': email,
      'funcao': 'cliente',
      'dataCriacao': Timestamp.now(),
      'projetos_acesso': [],
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário registrado! Um link de verificação foi enviado para o seu e-mail.')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> sendPasswordResetEmail({
    required BuildContext context,
    required String email,
  }) async {
    await _auth.sendPasswordResetEmail(email: email);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se o e-mail estiver cadastrado, um link para redefinir a senha foi enviado.')),
      );
    }
  }
}