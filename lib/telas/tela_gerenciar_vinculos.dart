// lib/telas/tela_gerenciar_vinculos.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TelaGerenciarVinculos extends StatefulWidget {
  const TelaGerenciarVinculos({super.key});

  @override
  State<TelaGerenciarVinculos> createState() => _TelaGerenciarVinculosState();
}

class _TelaGerenciarVinculosState extends State<TelaGerenciarVinculos> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Função para desvincular o usuário, usada por múltiplas abas
  Future<void> _desvincularUsuario(String userId, String projectId) async {
    bool confirmar =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Ação'),
            content: const Text(
              'Você tem certeza que deseja desvincular este usuário do projeto?',
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text(
                  'Desvincular',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmar || !mounted) return;

    try {
      await _firestore.collection('usuarios').doc(userId).update({
        'projetos_acesso': FieldValue.arrayRemove([projectId]),
      });
      await _firestore.collection('projetos').doc(projectId).update({
        'usuarios_vinculados': FieldValue.arrayRemove([userId]),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário desvinculado com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao desvincular: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos um TabController para gerenciar as abas
    return DefaultTabController(
      length: 3, // Temos 3 abas
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gerenciar Vínculos'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.add_link), text: 'Vincular Novo'),
              Tab(icon: Icon(Icons.business), text: 'Por Projeto'),
              Tab(icon: Icon(Icons.person), text: 'Por Usuário'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        // O corpo da tela agora é uma TabBarView
        body: const TabBarView(
          children: [
            // Conteúdo da Aba 1
            AbaVincularNovo(),
            // Conteúdo da Aba 2
            AbaGerenciarPorProjeto(),
            // Conteúdo da Aba 3
            AbaGerenciarPorUsuario(),
          ],
        ),
      ),
    );
  }
}

// WIDGET PARA A ABA 1: VINCULAR NOVO
class AbaVincularNovo extends StatefulWidget {
  const AbaVincularNovo({super.key});
  @override
  State<AbaVincularNovo> createState() => _AbaVincularNovoState();
}

class _AbaVincularNovoState extends State<AbaVincularNovo> {
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
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_selectedUserId)
          .update({
            'projetos_acesso': FieldValue.arrayUnion([_selectedProjectId]),
          });
      await FirebaseFirestore.instance
          .collection('projetos')
          .doc(_selectedProjectId)
          .update({
            'usuarios_vinculados': FieldValue.arrayUnion([_selectedUserId]),
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário vinculado com sucesso!')),
        );
        setState(() {
          _selectedUserId = null;
          _selectedProjectId = null;
        });
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao vincular: $e')));
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .where('funcao', isEqualTo: 'cliente')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final userItems = snapshot.data!.docs
                  .map(
                    (doc) => DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(
                        (doc.data() as Map<String, dynamic>)['nome'] ?? '',
                      ),
                    ),
                  )
                  .toList();
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Selecione o Usuário',
                  border: OutlineInputBorder(),
                ),
                value: _selectedUserId,
                items: userItems,
                onChanged: (value) => setState(() {
                  _selectedUserId = value;
                }),
              );
            },
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('projetos')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final projectItems = snapshot.data!.docs
                  .map(
                    (doc) => DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(
                        (doc.data() as Map<String, dynamic>)['nomeProjeto'] ??
                            '',
                      ),
                    ),
                  )
                  .toList();
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Selecione o Projeto',
                  border: OutlineInputBorder(),
                ),
                value: _selectedProjectId,
                items: projectItems,
                onChanged: (value) => setState(() {
                  _selectedProjectId = value;
                }),
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
                : const Text('Vincular Usuário'),
          ),
        ],
      ),
    );
  }
}

// WIDGET PARA A ABA 2: GERENCIAR POR PROJETO
class AbaGerenciarPorProjeto extends StatefulWidget {
  const AbaGerenciarPorProjeto({super.key});
  @override
  State<AbaGerenciarPorProjeto> createState() => _AbaGerenciarPorProjetoState();
}

class _AbaGerenciarPorProjetoState extends State<AbaGerenciarPorProjeto> {
  String? _projetoSelecionadoId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _desvincularUsuario(String userId, String projectId) async {
    // ... (A lógica de desvincular está na classe principal do State)
    final parentState = context
        .findAncestorStateOfType<_TelaGerenciarVinculosState>();
    await parentState?._desvincularUsuario(userId, projectId);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('projetos')
                .orderBy('nomeProjeto')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final projectItems = snapshot.data!.docs
                  .map(
                    (doc) => DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(
                        (doc.data() as Map<String, dynamic>)['nomeProjeto'] ??
                            '',
                      ),
                    ),
                  )
                  .toList();
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Selecione um Projeto para Ver Vínculos',
                  border: OutlineInputBorder(),
                ),
                value: _projetoSelecionadoId,
                items: projectItems,
                onChanged: (value) => setState(() {
                  _projetoSelecionadoId = value;
                }),
              );
            },
          ),
          const SizedBox(height: 8),
          const Divider(),
          Expanded(
            child: _projetoSelecionadoId == null
                ? const Center(child: Text('Selecione um projeto acima.'))
                : StreamBuilder<DocumentSnapshot>(
                    stream: _firestore
                        .collection('projetos')
                        .doc(_projetoSelecionadoId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());
                      final List<dynamic> userIds =
                          (snapshot.data!.data()
                              as Map<
                                String,
                                dynamic
                              >?)?['usuarios_vinculados'] ??
                          [];
                      if (userIds.isEmpty)
                        return const Center(
                          child: Text(
                            'Nenhum usuário vinculado a este projeto.',
                          ),
                        );
                      return ListView.builder(
                        itemCount: userIds.length,
                        itemBuilder: (context, index) {
                          final userId = userIds[index] as String;
                          return FutureBuilder<DocumentSnapshot>(
                            future: _firestore
                                .collection('usuarios')
                                .doc(userId)
                                .get(),
                            builder: (context, userSnapshot) {
                              if (!userSnapshot.hasData)
                                return const ListTile(
                                  title: Text('Carregando...'),
                                );
                              final userName =
                                  (userSnapshot.data?.data()
                                      as Map<String, dynamic>?)?['nome'] ??
                                  'Usuário desconhecido';
                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.person),
                                  title: Text(userName),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.link_off,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _desvincularUsuario(
                                      userId,
                                      _projetoSelecionadoId!,
                                    ),
                                  ),
                                ),
                              );
                            },
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

// WIDGET PARA A ABA 3: GERENCIAR POR USUÁRIO
class AbaGerenciarPorUsuario extends StatefulWidget {
  const AbaGerenciarPorUsuario({super.key});
  @override
  State<AbaGerenciarPorUsuario> createState() => _AbaGerenciarPorUsuarioState();
}

class _AbaGerenciarPorUsuarioState extends State<AbaGerenciarPorUsuario> {
  String? _usuarioSelecionadoId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _desvincularUsuario(String userId, String projectId) async {
    final parentState = context
        .findAncestorStateOfType<_TelaGerenciarVinculosState>();
    await parentState?._desvincularUsuario(userId, projectId);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('usuarios')
                .where('funcao', isEqualTo: 'cliente')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final userItems = snapshot.data!.docs
                  .map(
                    (doc) => DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(
                        (doc.data() as Map<String, dynamic>)['nome'] ?? '',
                      ),
                    ),
                  )
                  .toList();
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Selecione um Usuário para Ver Vínculos',
                  border: OutlineInputBorder(),
                ),
                value: _usuarioSelecionadoId,
                items: userItems,
                onChanged: (value) => setState(() {
                  _usuarioSelecionadoId = value;
                }),
              );
            },
          ),
          const SizedBox(height: 8),
          const Divider(),
          Expanded(
            child: _usuarioSelecionadoId == null
                ? const Center(child: Text('Selecione um usuário acima.'))
                : StreamBuilder<DocumentSnapshot>(
                    stream: _firestore
                        .collection('usuarios')
                        .doc(_usuarioSelecionadoId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());
                      final List<dynamic> projectIds =
                          (snapshot.data!.data()
                              as Map<String, dynamic>?)?['projetos_acesso'] ??
                          [];
                      if (projectIds.isEmpty)
                        return const Center(
                          child: Text(
                            'Este usuário não está vinculado a nenhum projeto.',
                          ),
                        );
                      return ListView.builder(
                        itemCount: projectIds.length,
                        itemBuilder: (context, index) {
                          final projectId = projectIds[index] as String;
                          return FutureBuilder<DocumentSnapshot>(
                            future: _firestore
                                .collection('projetos')
                                .doc(projectId)
                                .get(),
                            builder: (context, projectSnapshot) {
                              if (!projectSnapshot.hasData)
                                return const ListTile(
                                  title: Text('Carregando...'),
                                );
                              final projectName =
                                  (projectSnapshot.data?.data()
                                      as Map<
                                        String,
                                        dynamic
                                      >?)?['nomeProjeto'] ??
                                  'Projeto desconhecido';
                              return Card(
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.business_center_outlined,
                                  ),
                                  title: Text(projectName),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.link_off,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _desvincularUsuario(
                                      _usuarioSelecionadoId!,
                                      projectId,
                                    ),
                                  ),
                                ),
                              );
                            },
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
