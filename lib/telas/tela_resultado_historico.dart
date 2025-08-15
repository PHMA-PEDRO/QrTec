// lib/telas/tela_resultado_historico.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TelaResultadoHistorico extends StatelessWidget {
  final String tagEquipamento;
  const TelaResultadoHistorico({super.key, required this.tagEquipamento});

  void _mostrarImagem(BuildContext context, String? fotoUrl) {
    if (fotoUrl == null || fotoUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: InteractiveViewer(child: Image.network(fotoUrl)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico: $tagEquipamento'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('movimentacoes')
            .where('tagEquipamento', isEqualTo: tagEquipamento)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Ocorreu um erro. Verifique os índices do Firestore.',
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Nenhum histórico encontrado para a TAG: $tagEquipamento',
              ),
            );
          }

          final movimentacoes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: movimentacoes.length,
            itemBuilder: (context, index) {
              final doc = movimentacoes[index];
              final dados = doc.data() as Map<String, dynamic>;

              final bool isEntrada = dados['tipo'] == 'Entrada';
              final Color corMovimento = isEntrada
                  ? Colors.green
                  : Colors.orange.shade700;
              final IconData iconeMovimento = isEntrada
                  ? Icons.arrow_downward
                  : Icons.arrow_upward;
              final String? fotoUrl = dados['fotoUrl'];

              final timestamp = dados['timestamp'] as Timestamp?;
              final String dataFormatada = timestamp != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
                  : 'Data indisponível';

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: corMovimento,
                    child: Icon(iconeMovimento, color: Colors.white),
                  ),
                  title: Text('${dados['tipo']} em $dataFormatada'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // MUDANÇA AQUI: Adicionamos o nome do projeto
                      Text('Projeto: ${dados['nomeProjeto'] ?? 'N/A'}'),
                      Text('Responsável: ${dados['responsavel'] ?? 'N/A'}'),
                      Text('Local: ${dados['localizacao'] ?? 'N/A'}'),
                    ],
                  ),
                  trailing: fotoUrl != null
                      ? const Icon(Icons.camera_alt)
                      : null,
                  onTap: () => _mostrarImagem(context, fotoUrl),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
