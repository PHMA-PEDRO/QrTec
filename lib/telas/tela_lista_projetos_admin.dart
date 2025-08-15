import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qrtec_final/telas/tela_estoque.dart';

class TelaListaProjetosAdmin extends StatelessWidget {
  const TelaListaProjetosAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Projeto'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projetos')
            .orderBy('nomeProjeto')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Ocorreu um erro.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum projeto cadastrado.'));
          }

          final projetos = snapshot.data!.docs;

          return ListView.builder(
            itemCount: projetos.length,
            itemBuilder: (context, index) {
              final projeto = projetos[index];
              final nomeProjeto =
                  (projeto.data() as Map<String, dynamic>)['nomeProjeto'] ??
                  'Nome indisponível';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(
                    Icons.business_center_outlined,
                    color: Colors.indigo,
                  ),
                  title: Text(nomeProjeto),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TelaEstoque(projectId: projeto.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
