import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    // O AuthGate cuida do redirecionamento
  }

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
        const SnackBar(
          content: Text(
            'Usuário registrado! Um link de verificação foi enviado.',
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Limpa completamente todos os dados de autenticação e cache
  Future<void> clearAllAuthData() async {
    try {
      // Limpar todas as preferências locais
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Limpar cache do Firebase Auth
      await _auth.signOut();

      // Forçar limpeza de tokens e dados de sessão
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        try {
          await currentUser.delete();
        } catch (e) {
          // Se não conseguir deletar, pelo menos limpar os dados
          await _auth.signOut();
        }
      }

      // Aguardar para garantir que tudo foi limpo
      await Future.delayed(const Duration(milliseconds: 1000));
    } catch (e) {
      // Garantir que o logout aconteça mesmo com erro
      await _auth.signOut();
    }
  }

  /// Verifica se há dados de autenticação residuais
  Future<bool> hasResidualAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    return keys.isNotEmpty || _auth.currentUser != null;
  }
}
