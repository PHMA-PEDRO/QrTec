// lib/telas/tela_estoque.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 1. Transformamos em StatefulWidget
class TelaEstoque extends StatefulWidget {
  final String projectId;
  const TelaEstoque({super.key, required this.projectId});

  @override
  State<TelaEstoque> createState() => _TelaEstoqueState();
}

class _TelaEstoqueState extends State<TelaEstoque> {
  // 2. Variável para guardar o texto da busca
  String _termoBusca = '';

  void _mostrarImagem(BuildContext context, String? fotoUrl) {
    if (fotoUrl == null || fotoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma foto disponível para este item.'),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          child: Image.network(
            fotoUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque do Projeto'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 3. Adicionamos a Barra de Busca
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar por TAG',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _termoBusca = value
                      .toLowerCase(); // Guarda o termo em minúsculas
                });
              },
            ),
          ),

          // 4. A lista de resultados agora está dentro de um Expanded
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('estoque_atual')
                  .where(
                    'projetoId',
                    isEqualTo: widget.projectId,
                  ) // Usamos widget.projectId
                  .where('status', isEqualTo: 'Em Estoque')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Erro ao carregar o estoque.'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Nenhum equipamento em estoque neste projeto.'),
                  );
                }

                // 5. Lógica de Filtragem
                final todosOsItens = snapshot.data!.docs;
                final itensFiltrados = _termoBusca.isEmpty
                    ? todosOsItens // Se a busca estiver vazia, mostra tudo
                    : todosOsItens.where((doc) {
                        final dados = doc.data() as Map<String, dynamic>;
                        final tag = (dados['tag'] as String? ?? '')
                            .toLowerCase();
                        return tag.contains(_termoBusca);
                      }).toList(); // Senão, filtra a lista

                if (itensFiltrados.isEmpty) {
                  return const Center(
                    child: Text('Nenhum item encontrado com este termo.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: itensFiltrados.length,
                  itemBuilder: (context, index) {
                    final dados =
                        itensFiltrados[index].data() as Map<String, dynamic>;
                    final timestamp = dados['timestamp'] as Timestamp?;
                    final String dataFormatada = timestamp != null
                        ? DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(timestamp.toDate())
                        : 'Data indisponível';
                    final String? fotoUrl = dados['fotoUrl'];
                    final String localizacao =
                        dados['localizacao'] ?? 'Local não informado';

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(
                          Icons.computer,
                          size: 40,
                          color: Colors.green,
                        ),
                        title: Text(
                          'TAG: ${dados['tag'] ?? 'N/A'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Responsável: ${dados['responsavel'] ?? 'N/A'}',
                            ),
                            Text('Local da Entrada: $localizacao'),
                            Text('Data da Entrada: $dataFormatada'),
                          ],
                        ),
                        trailing: fotoUrl != null
                            ? const Icon(Icons.camera_alt, color: Colors.grey)
                            : null,
                        onTap: () => _mostrarImagem(context, fotoUrl),
                        isThreeLine: true,
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
