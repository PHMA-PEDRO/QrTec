// lib/telas/tela_vincular_usuario.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TelaVincularUsuario extends StatefulWidget {
  const TelaVincularUsuario({super.key});

  @override
  State<TelaVincularUsuario> createState() => _TelaVincularUsuarioState();
}

class _TelaVincularUsuarioState extends State<TelaVincularUsuario> {
  String? _selectedUserId;
  String? _selectedProjectId;
  bool _isLoading = false;

  Future<void> _vincularUsuarioAoProjeto() async {
    if (_selectedUserId == null || _selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um usuário e um projeto.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      await firestore.collection('usuarios').doc(_selectedUserId).update({
        'projetos_acesso': FieldValue.arrayUnion([_selectedProjectId]),
      });

      await firestore.collection('projetos').doc(_selectedProjectId).update({
        'usuarios_vinculados': FieldValue.arrayUnion([_selectedUserId]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário vinculado com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao vincular: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vincular Usuário a Projeto'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dropdown para selecionar o usuário
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .where('funcao', isEqualTo: 'cliente')
                  .snapshots(),
              builder: (context, snapshot) {
                // CORREÇÃO: Adicionadas chaves {}
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<DropdownMenuItem<String>> userItems = snapshot.data!.docs
                    .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(data['nome'] ?? 'Nome não encontrado'),
                      );
                    })
                    .toList();

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Selecione o Usuário',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedUserId,
                  items: userItems,
                  onChanged: (value) {
                    setState(() {
                      _selectedUserId = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Dropdown para selecionar o projeto
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projetos')
                  .snapshots(),
              builder: (context, snapshot) {
                // CORREÇÃO: Adicionadas chaves {}
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<DropdownMenuItem<String>> projectItems = snapshot
                    .data!
                    .docs
                    .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(
                          data['nomeProjeto'] ?? 'Nome não encontrado',
                        ),
                      );
                    })
                    .toList();

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Selecione o Projeto',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedProjectId,
                  items: projectItems,
                  onChanged: (value) {
                    setState(() {
                      _selectedProjectId = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _vincularUsuarioAoProjeto,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Salvar Vínculo'),
            ),
          ],
        ),
      ),
    );
  }
}
