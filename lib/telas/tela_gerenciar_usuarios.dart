// lib/telas/tela_gerenciar_usuarios.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qrtec_final/telas/tela_historico_geral.dart';

class TelaGerenciarUsuarios extends StatefulWidget {
  const TelaGerenciarUsuarios({super.key});

  @override
  State<TelaGerenciarUsuarios> createState() => _TelaGerenciarUsuariosState();
}

class _TelaGerenciarUsuariosState extends State<TelaGerenciarUsuarios> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _salvarAlteracoesUsuario(
    String uid,
    String novoNome,
    String novaFuncao,
  ) async {
    if (novoNome.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome não pode ficar em branco.')),
      );
      return;
    }

    try {
      await _firestore.collection('usuarios').doc(uid).update({
        'nome': novoNome.trim(),
        'funcao': novaFuncao,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário atualizado com sucesso!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao atualizar: $e')));
      }
    }
  }

  void _mostrarDialogEditarUsuario(Map<String, dynamic> userData) {
    final nomeController = TextEditingController(text: userData['nome']);
    String funcaoSelecionada = userData['funcao'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar Usuário'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: funcaoSelecionada,
                    decoration: const InputDecoration(
                      labelText: 'Função',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'cliente',
                        child: Text('Cliente'),
                      ),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          funcaoSelecionada = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => _salvarAlteracoesUsuario(
                    userData['uid'],
                    nomeController.text,
                    funcaoSelecionada,
                  ),
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Usuários'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('usuarios').orderBy('nome').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => const ListItemSkeleton(),
            );
          }
          if (snapshot.hasError) {
            return const EmptyStateWidget(
              icon: Icons.error,
              title: 'Erro',
              message: 'Não foi possível carregar os usuários.',
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.people,
              title: 'Nenhum Usuário',
              message: 'Nenhum usuário foi encontrado.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final dados = doc.data() as Map<String, dynamic>;
              final bool isAdmin = dados['funcao'] == 'admin';

              return Card(
                child: ListTile(
                  // CORREÇÃO: O nome do ícone foi ajustado para um que existe
                  leading: Icon(
                    isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: isAdmin ? Colors.amber.shade800 : Colors.blue,
                  ),
                  title: Text(dados['nome'] ?? 'Sem nome'),
                  subtitle: Text(dados['email'] ?? 'Sem e-mail'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(dados['funcao'] ?? 'cliente'),
                        backgroundColor: isAdmin
                            ? Colors.amber.shade100
                            : Colors.blue.shade100,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar',
                        onPressed: () => _mostrarDialogEditarUsuario(dados),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
