// lib/telas/tela_lista_projetos_admin.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qrtec_final/telas/tela_estoque.dart';

// O modelo de projeto precisa estar acessível aqui.
// Para evitar erros, o definimos diretamente no arquivo por enquanto.
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
  // Variável de estado para guardar o texto da busca
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
          // CAMPO DE BUSCA
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

          // LISTA DE RESULTADOS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projetos')
                  .orderBy('nomeProjeto')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Nenhum projeto cadastrado.'),
                  );
                }

                // LÓGICA DE FILTRO
                final todosProjetos = snapshot.data!.docs;
                final projetosFiltrados = todosProjetos.where((doc) {
                  final projeto = Projeto.fromFirestore(doc);
                  // Filtra se o nome do projeto (em minúsculas) contém o texto da busca (em minúsculas)
                  return projeto.nome.toLowerCase().contains(
                    _textoBusca.toLowerCase(),
                  );
                }).toList();

                if (projetosFiltrados.isEmpty) {
                  return const Center(
                    child: Text('Nenhum projeto encontrado.'),
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
