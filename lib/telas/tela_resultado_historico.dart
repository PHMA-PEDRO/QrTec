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
      builder: (context) => Dialog(child: InteractiveViewer(child: Image.network(fotoUrl))),
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
            return const Center(child: Text('Ocorreu um erro. Verifique os índices do Firestore.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Nenhum histórico encontrado para a TAG: $tagEquipamento'));
          }

          final movimentacoes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: movimentacoes.length,
            itemBuilder: (context, index) {
              final dados = movimentacoes[index].data() as Map<String, dynamic>;
              final bool isEntrada = dados['tipo'] == 'Entrada';
              final Color corMovimento = isEntrada ? Colors.green : Colors.orange.shade700;
              final IconData iconeMovimento = isEntrada ? Icons.arrow_downward : Icons.arrow_upward;
              final String? fotoUrl = dados['fotoUrl'];
              final timestamp = dados['timestamp'] as Timestamp?;
              final String dataFormatada = timestamp != null
                  ? DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(timestamp.toDate())
                  : 'Data indisponível';
              
              // CORREÇÃO: Lógica robusta para lidar com ambos os formatos de localização
              String localizacaoTexto = 'Local não informado';
              if (dados.containsKey('localizacao')) {
                if (dados['localizacao'] is String) {
                  localizacaoTexto = dados['localizacao'];
                } else if (dados['localizacao'] is GeoPoint) {
                  final geoPoint = dados['localizacao'] as GeoPoint;
                  localizacaoTexto = 'Lat: ${geoPoint.latitude.toStringAsFixed(4)}, Lon: ${geoPoint.longitude.toStringAsFixed(4)}';
                }
              }

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: corMovimento, child: Icon(iconeMovimento, color: Colors.white)),
                  title: Text('${dados['tipo']} em $dataFormatada', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Projeto: ${dados['nomeProjeto'] ?? 'N/A'}'),
                      Text('Responsável: ${dados['responsavel'] ?? 'N/A'}'),
                      Text('Local: $localizacaoTexto'),
                    ],
                  ),
                  trailing: fotoUrl != null ? const Icon(Icons.camera_alt, color: Colors.grey) : null,
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