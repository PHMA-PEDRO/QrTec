import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TelaEstoque extends StatelessWidget {
  final String projectId;
  const TelaEstoque({super.key, required this.projectId});

  void _mostrarImagem(BuildContext context, String? fotoUrl) {
    if (fotoUrl == null || fotoUrl.isEmpty) {
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: InteractiveViewer(
          child: Image.network(
            fotoUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Fechar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('estoque_atual')
            .where('projectId', isEqualTo: projectId)
            .where('status', isEqualTo: 'Em Estoque')
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Ocorreu um erro ao carregar o estoque. Verifique os índices do Firestore.',
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nenhum equipamento em estoque neste projeto.'),
            );
          }

          final estoque = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: estoque.length,
            itemBuilder: (context, index) {
              final doc = estoque[index];
              final dados = doc.data() as Map<String, dynamic>;

              final timestamp = dados['timestamp'] as Timestamp?;
              final String dataFormatada = timestamp != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
                  : 'Data indisponível';

              final String? fotoUrl = dados['fotoUrl'];

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(
                    Icons.computer,
                    size: 40,
                    color: Colors.green,
                  ),
                  title: Text('TAG: ${dados['tag'] ?? 'N/A'}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Responsável: ${dados['responsavel'] ?? 'N/A'}'),
                      Text(
                        'Local da Entrada: ${dados['localizacao'] ?? 'N/A'}',
                      ),
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
    );
  }
}
