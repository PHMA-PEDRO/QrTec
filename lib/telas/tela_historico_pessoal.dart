// lib/telas/tela_historico_pessoal.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Importa os widgets reutilizáveis que já temos
import 'package:qrtec_final/telas/tela_historico_geral.dart';

class TelaHistoricoPessoal extends StatelessWidget {
  const TelaHistoricoPessoal({super.key});

  void _mostrarImagem(BuildContext context, String? fotoUrl) {
    if (fotoUrl == null || fotoUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(child: InteractiveViewer(child: Image.network(fotoUrl))),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pega o ID do usuário logado para usar na consulta
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Histórico de Movimentações'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // A consulta agora filtra pelo campo 'userId'
        stream: FirebaseFirestore.instance
            .collection('movimentacoes')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
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
              message: 'Não foi possível carregar seu histórico. Verifique os índices do Firestore.',
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.history_toggle_off,
              title: 'Nenhum Registro Encontrado',
              message: 'Você ainda não realizou nenhuma movimentação.',
            );
          }

          final movimentacoes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: movimentacoes.length,
            itemBuilder: (context, index) {
              final dados = movimentacoes[index].data() as Map<String, dynamic>;
              final bool isEntrada = dados['tipo'] == 'Entrada';
              final String statusTexto = isEntrada ? 'Em Estoque' : 'Em Transporte';
              final Color statusCor = isEntrada ? Colors.green : Colors.orange.shade700;
              final IconData iconeMovimento = isEntrada ? Icons.arrow_downward : Icons.arrow_upward;
              final String? fotoUrl = dados['fotoUrl'];
              final Timestamp? timestamp = dados['timestamp'] as Timestamp?;
              final String dataFormatada = timestamp != null
                  ? DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(timestamp.toDate())
                  : 'Data indisponível';
              
              String localizacaoTexto = 'Local não informado';
              if (dados.containsKey('localizacao') && dados['localizacao'] != null) {
                  if (dados['localizacao'] is String) {
                    localizacaoTexto = dados['localizacao'];
                  } else if (dados['localizacao'] is GeoPoint) {
                    final geoPoint = dados['localizacao'] as GeoPoint;
                    localizacaoTexto = 'Lat: ${geoPoint.latitude.toStringAsFixed(4)}, Lon: ${geoPoint.longitude.toStringAsFixed(4)}';
                  }
              }

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: statusCor, child: Icon(iconeMovimento, color: Colors.white)),
                  title: Text('TAG: ${dados['tagEquipamento'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: $statusTexto', style: TextStyle(fontWeight: FontWeight.bold, color: statusCor)),
                      Text('Projeto: ${dados['nomeProjeto'] ?? 'N/A'}'),
                      Text('Data: $dataFormatada'),
                      Text('Local: $localizacaoTexto'),
                    ],
                  ),
                  trailing: fotoUrl != null ? const Icon(Icons.camera_alt) : null,
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