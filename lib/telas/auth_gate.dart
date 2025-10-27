// lib/telas/auth_gate.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qrtec_final/services/auth_service.dart';
import 'package:qrtec_final/telas/tela_admin_dashboard.dart';
import 'package:qrtec_final/telas/tela_home.dart';
import 'package:qrtec_final/telas/tela_login.dart';
import 'package:qrtec_final/telas/tela_verificar_email.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Adiar para depois do primeiro frame para não bloquear a montagem inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: unawaited_futures
      _limparDadosResiduais();
    });
  }

  /// Limpa dados residuais de autenticação ao inicializar
  Future<void> _limparDadosResiduais() async {
    try {
      // Verificar se há dados residuais
      if (await _authService.hasResidualAuthData()) {
        // Limpar dados residuais silenciosamente
        await _authService.clearAllAuthData();
      }
    } catch (e) {
      // Ignorar erros na limpeza inicial
    }
  }

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

        // AQUI ESTÁ A CORREÇÃO DEFINITIVA:
        // Passamos uma chave única (o UID do usuário) para o RoleChecker.
        // Quando o UID muda (logout e login com outra conta), o Flutter
        // destrói o RoleChecker antigo e cria um novo, forçando-o a buscar
        // os dados do novo usuário.
        return RoleChecker(key: ValueKey(user.uid), user: user);
      },
    );
  }
}

// WIDGET AUXILIAR para buscar a função do usuário de forma segura
class RoleChecker extends StatelessWidget {
  final User user;
  const RoleChecker({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
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

        if (userDocSnapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Erro ao carregar seu perfil.\n\nDetalhes: ${userDocSnapshot.error}",
                ),
              ),
            ),
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

        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Erro crítico: seu perfil de usuário não foi encontrado no banco de dados.",
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: const Text('Voltar para o Login'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
