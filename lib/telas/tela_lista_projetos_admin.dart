// lib/telas/tela_lista_projetos_admin.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qrtec_final/telas/tela_estoque.dart';
import 'package:shimmer/shimmer.dart'; // Import do shimmer

class Projeto {
  final String id;
  final String nome;
  final Map<String, dynamic> data;

  Projeto({required this.id, required this.nome, required this.data});

  factory Projeto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Projeto(
      id: doc.id,
      nome: data['nomeProjeto'] ?? 'Nome indisponível',
      data: data,
    );
  }
}

class TelaListaProjetosAdmin extends StatefulWidget {
  const TelaListaProjetosAdmin({super.key});

  @override
  State<TelaListaProjetosAdmin> createState() => _TelaListaProjetosAdminState();
}

class _TelaListaProjetosAdminState extends State<TelaListaProjetosAdmin> {
  String _textoBusca = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultar Estoque de Projeto'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar por nome do projeto...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _textoBusca = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projetos')
                  .orderBy('nomeProjeto')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    itemCount: 5,
                    itemBuilder: (context, index) => const ListItemSkeleton(),
                  );
                }
                if (snapshot.hasError) {
                  return const EmptyStateWidget(
                    icon: Icons.error_outline,
                    title: 'Ocorreu um Erro',
                    message: 'Não foi possível carregar os projetos.',
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.business_center_outlined,
                    title: 'Nenhum Projeto Cadastrado',
                    message:
                        'Use o painel de gerenciamento para adicionar o primeiro projeto.',
                  );
                }

                final todosProjetos = snapshot.data!.docs;
                final projetosFiltrados = todosProjetos.where((doc) {
                  final projeto = Projeto.fromFirestore(doc);
                  return projeto.nome.toLowerCase().contains(
                    _textoBusca.toLowerCase(),
                  );
                }).toList();

                if (projetosFiltrados.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.search_off,
                    title: 'Nenhum Projeto Encontrado',
                    message: 'Tente um termo de busca diferente.',
                  );
                }

                return ListView.builder(
                  itemCount: projetosFiltrados.length,
                  itemBuilder: (context, index) {
                    final projetoDoc = projetosFiltrados[index];
                    final projeto = Projeto.fromFirestore(projetoDoc);
                    final bool isAtivo =
                        (projetoDoc.data() as Map<String, dynamic>)['status'] ==
                        'ativo';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      color: isAtivo ? Colors.white : Colors.grey.shade300,
                      child: ListTile(
                        leading: Icon(
                          Icons.business_center_outlined,
                          color: isAtivo ? Colors.indigo : Colors.grey,
                        ),
                        title: Text(
                          projeto.nome,
                          style: TextStyle(
                            decoration: isAtivo
                                ? TextDecoration.none
                                : TextDecoration.lineThrough,
                          ),
                        ),
                        subtitle: Text(isAtivo ? 'Ativo' : 'Inativo'),
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
          ),
        ],
      ),
    );
  }
}

// Widgets reutilizáveis (podemos movê-los para um arquivo separado depois)
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.white),
          title: Container(height: 16, width: 150, color: Colors.white),
          subtitle: Container(height: 12, width: 100, color: Colors.white),
        ),
      ),
    );
  }
}
