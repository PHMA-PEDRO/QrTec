import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qrtec_final/telas/tela_cadastro_equipamento.dart';
import 'package:qrtec_final/telas/tela_cadastro_projeto.dart';
import 'package:qrtec_final/telas/tela_lista_projetos_admin.dart';
import 'package:qrtec_final/telas/tela_login.dart';
import 'package:qrtec_final/telas/tela_vincular_usuario.dart';

class TelaAdminDashboard extends StatelessWidget {
  const TelaAdminDashboard({super.key});

  Future<void> _fazerLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const TelaLogin()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel do Administrador'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => _fazerLogout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Gerenciamento',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const Divider(),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.add_business_outlined,
                color: Colors.indigo,
              ),
              title: const Text('Cadastrar Novo Projeto'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TelaCadastroProjeto(),
                ),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.add_moderator_outlined,
                color: Colors.indigo,
              ),
              title: const Text('Cadastrar Equipamento'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TelaCadastroEquipamento(),
                ),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.person_add_alt_1_outlined,
                color: Colors.indigo,
              ),
              title: const Text('Vincular Usuário a Projeto'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TelaVincularUsuario(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Consultas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const Divider(),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.inventory_2_outlined,
                color: Colors.indigo,
              ),
              title: const Text('Consultar Estoques de Projetos'),
              subtitle: const Text('Veja o inventário de cada projeto'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TelaListaProjetosAdmin(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
