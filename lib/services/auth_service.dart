// lib/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qrtec_final/telas/tela_admin_dashboard.dart';
import 'package:qrtec_final/telas/tela_home.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Função para fazer Login
  Future<void> signInWithEmailAndPassword({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    if (context.mounted) {
      await _redirectUserBasedOnRole(context, userCredential.user!);
    }
  }

  // Função para Registrar um novo usuário
  Future<void> createUserWithEmailAndPassword({
    required BuildContext context,
    required String nome,
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final user = userCredential.user!;

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
        const SnackBar(content: Text('Usuário registrado com sucesso! Faça o login.')),
      );
      Navigator.pop(context);
    }
  }

  // Função interna para checar a função e redirecionar
  Future<void> _redirectUserBasedOnRole(BuildContext context, User user) async {
    final docSnapshot = await _firestore.collection('usuarios').doc(user.uid).get();
    
    if (context.mounted) {
      if (docSnapshot.exists) {
        final String funcao = docSnapshot.data()?['funcao'] ?? 'cliente';
        
        if (funcao == 'admin') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const TelaAdminDashboard()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const TelaHome()),
            (route) => false,
          );
        }
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const TelaHome()),
          (route) => false,
        );
      }
    }
  }
}